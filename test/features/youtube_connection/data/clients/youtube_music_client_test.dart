import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transfer_aplicationn/features/youtube_connection/data/auth/youtube_authorization_provider.dart';
import 'package:transfer_aplicationn/features/youtube_connection/data/clients/youtube_music_client.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_failure.dart';

void main() {
  const clientConfigHtml =
      'ytcfg.set({"VISITOR_DATA":"visitor-id",'
      '"INNERTUBE_CLIENT_VERSION":"1.test-version"});';
  test(
    'validates authenticated account and library InnerTube responses',
    () async {
      final requestedEndpoints = <String>[];
      final client = InnerTubeYouTubeMusicClient(
        authorizationProvider: const _FakeAuthorizationProvider(),
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(clientConfigHtml, 200);
          }
          requestedEndpoints.add(request.url.path);
          if (request.url.path.endsWith('/account/account_menu')) {
            return http.Response(
              jsonEncode({
                'actions': [
                  {
                    'openPopupAction': {
                      'popup': {
                        'activeAccountHeaderRenderer': {
                          'accountName': 'Listener',
                        },
                      },
                    },
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'contents': {}}), 200);
        }),
      );

      final result = await client.validateAuthentication();

      expect(result.succeeded, isTrue);
      expect(result.httpStatus, 200);
      expect(requestedEndpoints, [
        '/youtubei/v1/account/account_menu',
        '/youtubei/v1/browse',
      ]);
    },
  );

  test('maps InnerTube 401 to a typed authentication failure', () async {
    final client = InnerTubeYouTubeMusicClient(
      authorizationProvider: const _FakeAuthorizationProvider(),
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(clientConfigHtml, 200);
        }
        return http.Response('{}', 401);
      }),
    );

    final result = await client.validateAuthentication();

    expect(result.succeeded, isFalse);
    expect(
      result.failure?.type,
      YouTubeConnectionFailureType.authenticationFailed,
    );
    expect(result.failure?.httpStatus, 401);
  });

  test(
    'maps client configuration timeout to a typed timeout failure',
    () async {
      final client = InnerTubeYouTubeMusicClient(
        authorizationProvider: const _FakeAuthorizationProvider(),
        requestTimeout: const Duration(milliseconds: 1),
        httpClient: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(clientConfigHtml, 200);
        }),
      );

      final result = await client.validateAuthentication();

      expect(result.succeeded, isFalse);
      expect(result.failure?.type, YouTubeConnectionFailureType.timeout);
    },
  );

  test('fails safely when YouTube Music omits its client version', () async {
    final client = InnerTubeYouTubeMusicClient(
      authorizationProvider: const _FakeAuthorizationProvider(),
      httpClient: MockClient(
        (request) async => http.Response('<html>no ytcfg</html>', 200),
      ),
    );

    final result = await client.validateAuthentication();

    expect(result.succeeded, isFalse);
    expect(
      result.failure?.type,
      YouTubeConnectionFailureType.malformedResponse,
    );
  });

  test('maps InnerTube 429 to a typed rate-limit failure', () async {
    final client = InnerTubeYouTubeMusicClient(
      authorizationProvider: const _FakeAuthorizationProvider(),
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(clientConfigHtml, 200);
        }
        return http.Response('{}', 429);
      }),
    );

    final result = await client.validateAuthentication();

    expect(result.succeeded, isFalse);
    expect(result.failure?.type, YouTubeConnectionFailureType.rateLimited);
    expect(result.failure?.httpStatus, 429);
  });

  test(
    'development write check creates a temporary playlist and adds an item',
    () async {
      final requestBodies = <Map<String, dynamic>>[];
      final client = InnerTubeYouTubeMusicClient(
        authorizationProvider: const _FakeAuthorizationProvider(),
        httpClient: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(clientConfigHtml, 200);
          }
          requestBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          if (request.url.path.endsWith('/playlist/create')) {
            return http.Response(
              jsonEncode({'playlistId': 'poc-playlist'}),
              200,
            );
          }
          return http.Response(jsonEncode({'status': 'STATUS_SUCCEEDED'}), 200);
        }),
      );

      final result = await client.runDevelopmentWriteCapabilityCheck(
        videoId: 'known-video',
      );

      final clientContext = requestBodies.first['context'] as Map;
      final clientMetadata = clientContext['client'] as Map;
      expect(clientMetadata['clientVersion'], '1.test-version');
      expect(clientMetadata['clientName'], 'WEB_REMIX');
      expect(requestBodies, hasLength(2));
      expect(result.succeeded, isTrue);
      expect(result.playlistId, 'poc-playlist');
      expect(result.itemAdded, isTrue);
      expect(requestBodies.first['title'], contains('TEMPORARY'));
      expect(requestBodies.last['playlistId'], 'poc-playlist');
    },
  );
}

class _FakeAuthorizationProvider implements YouTubeAuthorizationProvider {
  const _FakeAuthorizationProvider();

  @override
  Future<Map<String, String>?> authorizationHeaders() async {
    return const {'Authorization': 'Bearer redacted-test-token'};
  }
}
