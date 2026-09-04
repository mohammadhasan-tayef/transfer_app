import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/youtube_connection_failure.dart';
import '../../domain/models/youtube_connection_validation_result.dart';
import '../../domain/models/youtube_write_capability_result.dart';
import '../../domain/repositories/youtube_music_client.dart';
import '../../domain/repositories/youtube_write_capability_client.dart';
import '../auth/youtube_auth_diagnostics.dart';
import '../auth/youtube_authorization_provider.dart';

class InnerTubeYouTubeMusicClient
    implements YouTubeMusicClient, YouTubeWriteCapabilityClient {
  InnerTubeYouTubeMusicClient({
    required this.authorizationProvider,
    http.Client? httpClient,
    this.requestTimeout = const Duration(seconds: 15),
    this.diagnostics = const SafeYouTubeAuthDiagnostics(),
  }) : _httpClient = httpClient ?? http.Client();

  static final _musicOrigin = Uri.parse('https://music.youtube.com');
  static const _libraryBrowseId = 'FEmusic_liked_playlists';

  final YouTubeAuthorizationProvider authorizationProvider;
  final http.Client _httpClient;
  final Duration requestTimeout;
  final YouTubeAuthDiagnostics diagnostics;

  InnerTubeClientConfiguration? _clientConfiguration;

  @override
  Future<YouTubeConnectionValidationResult> validateAuthentication() async {
    final accountResult = await _post('account/account_menu', const {});
    if (!accountResult.succeeded) {
      return YouTubeConnectionValidationResult.failure(accountResult.failure!);
    }
    if (!_containsKeyDeep(accountResult.body, 'activeAccountHeaderRenderer')) {
      return YouTubeConnectionValidationResult.failure(
        YouTubeConnectionFailure(
          YouTubeConnectionFailureType.validationFailed,
          httpStatus: 200,
        ),
      );
    }

    final libraryResult = await getLibraryPlaylists();
    if (!libraryResult.succeeded) {
      return YouTubeConnectionValidationResult.failure(libraryResult.failure!);
    }
    if (!libraryResult.body.containsKey('contents')) {
      return YouTubeConnectionValidationResult.failure(
        YouTubeConnectionFailure(
          YouTubeConnectionFailureType.malformedResponse,
          httpStatus: 200,
        ),
      );
    }

    diagnostics.record(
      'Authenticated InnerTube library request succeeded',
      httpStatus: libraryResult.httpStatus,
    );
    return YouTubeConnectionValidationResult.success(
      httpStatus: libraryResult.httpStatus ?? 200,
    );
  }

  Future<InnerTubeOperationResult> getLibraryPlaylists() {
    return _post('browse', const {'browseId': _libraryBrowseId});
  }

  Future<InnerTubeOperationResult> createPlaylist({
    required String title,
    required String description,
  }) {
    return _post('playlist/create', {
      'title': title,
      'description': description,
      'privacyStatus': 'PRIVATE',
    });
  }

  Future<InnerTubeOperationResult> addPlaylistItems({
    required String playlistId,
    required List<String> videoIds,
  }) {
    return _post('browse/edit_playlist', {
      'playlistId': playlistId,
      'actions': [
        for (final videoId in videoIds)
          {'action': 'ACTION_ADD_VIDEO', 'addedVideoId': videoId},
      ],
    });
  }

  @override
  Future<YouTubeWriteCapabilityResult> runDevelopmentWriteCapabilityCheck({
    String? videoId,
  }) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final createResult = await createPlaylist(
      title: 'Music Transfer POC - TEMPORARY - $timestamp',
      description:
          'Development-only capability check. Safe to remove manually.',
    );
    if (!createResult.succeeded) {
      return YouTubeWriteCapabilityResult.failure(createResult.failure!);
    }

    final playlistId = createResult.body['playlistId'];
    if (playlistId is! String || playlistId.isEmpty) {
      return YouTubeWriteCapabilityResult.failure(
        YouTubeConnectionFailure(
          YouTubeConnectionFailureType.malformedResponse,
          httpStatus: 200,
        ),
      );
    }

    var itemAdded = false;
    if (videoId != null && videoId.trim().isNotEmpty) {
      final addResult = await addPlaylistItems(
        playlistId: playlistId,
        videoIds: [videoId.trim()],
      );
      if (!addResult.succeeded) {
        return YouTubeWriteCapabilityResult.failure(addResult.failure!);
      }
      final status = addResult.body['status'];
      if (status is! String || !status.contains('SUCCEEDED')) {
        return YouTubeWriteCapabilityResult.failure(
          YouTubeConnectionFailure(
            YouTubeConnectionFailureType.validationFailed,
            httpStatus: 200,
          ),
        );
      }
      itemAdded = true;
    }

    diagnostics.record(
      'Create-playlist capability succeeded',
      httpStatus: createResult.httpStatus,
    );
    return YouTubeWriteCapabilityResult.success(
      playlistId: playlistId,
      itemAdded: itemAdded,
      httpStatus: createResult.httpStatus ?? 200,
    );
  }

  Future<InnerTubeOperationResult> _post(
    String endpoint,
    Map<String, Object?> requestBody,
  ) async {
    try {
      final authorizationHeaders = await authorizationProvider
          .authorizationHeaders();
      if (authorizationHeaders == null) {
        return InnerTubeOperationResult.failure(
          YouTubeConnectionFailure(
            YouTubeConnectionFailureType.authenticationFailed,
          ),
        );
      }

      final clientConfiguration = _clientConfiguration ??=
          await _loadClientConfiguration();
      if (clientConfiguration == null) {
        return InnerTubeOperationResult.failure(
          YouTubeConnectionFailure(
            YouTubeConnectionFailureType.malformedResponse,
          ),
        );
      }
      final headers = <String, String>{
        ...authorizationHeaders,
        'Accept': '*/*',
        'Content-Type': 'application/json',
        'Origin': _musicOrigin.toString(),
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            'Chrome/120.0 Mobile Safari/537.36',
        'X-Goog-Request-Time':
            '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
        'X-Goog-Visitor-Id': ?clientConfiguration.visitorId,
      };
      final body = <String, Object?>{
        ...requestBody,
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': clientConfiguration.clientVersion,
            'hl': 'en',
          },
          'user': <String, Object?>{},
        },
      };
      final uri = Uri.parse(
        'https://music.youtube.com/youtubei/v1/$endpoint?alt=json',
      );
      final response = await _httpClient
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(requestTimeout);
      diagnostics.record(
        'InnerTube validation request completed',
        httpStatus: response.statusCode,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return InnerTubeOperationResult.failure(
          _failureForHttpStatus(response.statusCode),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return InnerTubeOperationResult.failure(
          YouTubeConnectionFailure(
            YouTubeConnectionFailureType.malformedResponse,
            httpStatus: response.statusCode,
          ),
        );
      }
      return InnerTubeOperationResult.success(decoded, response.statusCode);
    } on TimeoutException {
      return InnerTubeOperationResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.timeout),
      );
    } on http.ClientException {
      return InnerTubeOperationResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.noInternet),
      );
    } on FormatException {
      return InnerTubeOperationResult.failure(
        YouTubeConnectionFailure(
          YouTubeConnectionFailureType.malformedResponse,
        ),
      );
    } catch (_) {
      return InnerTubeOperationResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.unknown),
      );
    }
  }

  Future<InnerTubeClientConfiguration?> _loadClientConfiguration() async {
    try {
      final response = await _httpClient
          .get(
            _musicOrigin,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                  'Chrome/120.0 Mobile Safari/537.36',
            },
          )
          .timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final configPattern = RegExp(
        r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;',
        dotAll: true,
      );
      String? visitorId;
      String? clientVersion;
      for (final match in configPattern.allMatches(response.body)) {
        final serializedConfig = match.group(1);
        if (serializedConfig == null) {
          continue;
        }
        final config = jsonDecode(serializedConfig);
        if (config is! Map<String, dynamic>) {
          continue;
        }

        final visitorCandidate = config['VISITOR_DATA'];
        if (visitorCandidate is String && visitorCandidate.isNotEmpty) {
          visitorId = visitorCandidate;
        }
        final versionCandidate = config['INNERTUBE_CLIENT_VERSION'];
        if (versionCandidate is String && versionCandidate.isNotEmpty) {
          clientVersion = versionCandidate;
        }
      }
      if (clientVersion == null) {
        return null;
      }
      return InnerTubeClientConfiguration(
        clientVersion: clientVersion,
        visitorId: visitorId,
      );
    } on FormatException {
      return null;
    }
  }

  YouTubeConnectionFailure _failureForHttpStatus(int statusCode) {
    final type = switch (statusCode) {
      401 || 403 => YouTubeConnectionFailureType.authenticationFailed,
      429 => YouTubeConnectionFailureType.rateLimited,
      >= 500 => YouTubeConnectionFailureType.serverError,
      _ => YouTubeConnectionFailureType.validationFailed,
    };
    return YouTubeConnectionFailure(type, httpStatus: statusCode);
  }

  bool _containsKeyDeep(Object? value, String expectedKey) {
    if (value is Map) {
      if (value.containsKey(expectedKey)) {
        return true;
      }
      return value.values.any((child) => _containsKeyDeep(child, expectedKey));
    }
    if (value is Iterable) {
      return value.any((child) => _containsKeyDeep(child, expectedKey));
    }
    return false;
  }
}

class InnerTubeClientConfiguration {
  const InnerTubeClientConfiguration({
    required this.clientVersion,
    this.visitorId,
  });

  final String clientVersion;
  final String? visitorId;
}

class InnerTubeOperationResult {
  const InnerTubeOperationResult._({
    required this.succeeded,
    required this.body,
    this.httpStatus,
    this.failure,
  });

  const InnerTubeOperationResult.success(
    Map<String, dynamic> body,
    int httpStatus,
  ) : this._(succeeded: true, body: body, httpStatus: httpStatus);

  const InnerTubeOperationResult.failure(YouTubeConnectionFailure failure)
    : this._(succeeded: false, body: const {}, failure: failure);

  final bool succeeded;
  final Map<String, dynamic> body;
  final int? httpStatus;
  final YouTubeConnectionFailure? failure;
}
