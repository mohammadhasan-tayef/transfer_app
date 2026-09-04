import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/youtube_auth_result.dart';
import '../../domain/models/youtube_connection_failure.dart';
import 'youtube_auth_diagnostics.dart';
import 'youtube_authorization_provider.dart';

class GoogleOAuthConfiguration {
  const GoogleOAuthConfiguration({
    this.serverClientId = const String.fromEnvironment(
      'GOOGLE_OAUTH_SERVER_CLIENT_ID',
    ),
  });

  final String serverClientId;

  bool get isConfigured => serverClientId.trim().isNotEmpty;
}

class GoogleOAuthClient implements YouTubeAuthorizationProvider {
  GoogleOAuthClient({
    this.configuration = const GoogleOAuthConfiguration(),
    GoogleSignIn? googleSignIn,
    this.diagnostics = const SafeYouTubeAuthDiagnostics(),
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const youtubeScope = 'https://www.googleapis.com/auth/youtube';
  static const _scopes = <String>[youtubeScope];

  final GoogleOAuthConfiguration configuration;
  final GoogleSignIn _googleSignIn;
  final YouTubeAuthDiagnostics diagnostics;

  Future<void>? _initialization;
  GoogleSignInAccount? _currentAccount;

  Future<YouTubeAuthResult> authenticate() async {
    if (!configuration.isConfigured) {
      return const YouTubeAuthResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.configuration),
      );
    }

    try {
      await _ensureInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        return const YouTubeAuthResult.failure(
          YouTubeConnectionFailure(YouTubeConnectionFailureType.configuration),
        );
      }

      diagnostics.record('OAuth step started');
      final account = await _googleSignIn.authenticate(scopeHint: _scopes);
      final existingAuthorization = await account.authorizationClient
          .authorizationForScopes(_scopes);
      if (existingAuthorization == null) {
        await account.authorizationClient.authorizeScopes(_scopes);
      }

      _currentAccount = account;
      diagnostics.record('OAuth completed');
      return YouTubeAuthResult.success(
        accountIdentifier: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (error) {
      return _mapGoogleSignInFailure(error);
    } catch (_) {
      return const YouTubeAuthResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.unknown),
      );
    }
  }

  Future<YouTubeAuthResult> restoreAuthentication() async {
    if (!configuration.isConfigured) {
      return const YouTubeAuthResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.configuration),
      );
    }

    try {
      await _ensureInitialized();
      final lightweightAttempt = _googleSignIn
          .attemptLightweightAuthentication();
      if (lightweightAttempt == null) {
        return const YouTubeAuthResult.cancelled();
      }

      final account = await lightweightAttempt;
      if (account == null) {
        return const YouTubeAuthResult.cancelled();
      }

      final authorization = await account.authorizationClient
          .authorizationForScopes(_scopes);
      if (authorization == null) {
        return const YouTubeAuthResult.failure(
          YouTubeConnectionFailure(
            YouTubeConnectionFailureType.authenticationFailed,
          ),
        );
      }

      _currentAccount = account;
      return YouTubeAuthResult.success(
        accountIdentifier: account.email,
        displayName: account.displayName,
      );
    } on GoogleSignInException catch (error) {
      return _mapGoogleSignInFailure(error);
    } catch (_) {
      return const YouTubeAuthResult.failure(
        YouTubeConnectionFailure(YouTubeConnectionFailureType.unknown),
      );
    }
  }

  @override
  Future<Map<String, String>?> authorizationHeaders() async {
    final account = _currentAccount;
    if (account == null) {
      return null;
    }
    return account.authorizationClient.authorizationHeaders(_scopes);
  }

  Future<void> disconnect() async {
    _currentAccount = null;
    if (_initialization != null) {
      await _googleSignIn.disconnect();
    }
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _googleSignIn.initialize(
      serverClientId: configuration.serverClientId,
    );
  }

  YouTubeAuthResult _mapGoogleSignInFailure(GoogleSignInException error) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return const YouTubeAuthResult.cancelled();
    }

    final failureType = switch (error.code) {
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        YouTubeConnectionFailureType.configuration,
      GoogleSignInExceptionCode.interrupted ||
      GoogleSignInExceptionCode.uiUnavailable ||
      GoogleSignInExceptionCode.userMismatch =>
        YouTubeConnectionFailureType.authenticationFailed,
      _ => YouTubeConnectionFailureType.unknown,
    };
    return YouTubeAuthResult.failure(YouTubeConnectionFailure(failureType));
  }
}
