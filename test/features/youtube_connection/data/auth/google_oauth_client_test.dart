import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:transfer_aplicationn/features/youtube_connection/data/auth/google_oauth_client.dart';
import 'package:transfer_aplicationn/features/youtube_connection/data/auth/youtube_auth_diagnostics.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_auth_result.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_failure.dart';
import 'package:transfer_aplicationn/features/youtube_connection/presentation/mappers/youtube_connection_failure_message.dart';

void main() {
  const testClientId = 'test-web-client.apps.googleusercontent.com';
  late _FakeGoogleSignIn signIn;
  late _RecordingDiagnostics diagnostics;

  setUp(() {
    signIn = _FakeGoogleSignIn();
    diagnostics = _RecordingDiagnostics();
  });

  GoogleOAuthClient clientWith(String serverClientId) => GoogleOAuthClient(
    configuration: GoogleOAuthConfiguration(serverClientId: serverClientId),
    googleSignIn: signIn,
    diagnostics: diagnostics,
  );

  for (final serverClientId in ['', ' \t\n ']) {
    test(
      'missing or blank ID blocks sign-in and restore (${serverClientId.length})',
      () async {
        final client = clientWith(serverClientId);
        for (final result in [
          await client.authenticate(),
          await client.restoreAuthentication(),
        ]) {
          expect(result.outcome, YouTubeAuthOutcome.failure);
          expect(
            result.failure?.type,
            YouTubeConnectionFailureType.configuration,
          );
          expect(
            youtubeConnectionFailureMessage(result.failure),
            'Google sign-in is not configured for this build.',
          );
        }
        expect(signIn.calls, isEmpty);
        expect(diagnostics.events, isEmpty);
      },
    );
  }

  for (final serverClientId in [testClientId, ' $testClientId ']) {
    test(
      'configured ID is forwarded and initialization is awaited (${serverClientId.length})',
      () async {
        final initialization = Completer<void>();
        signIn.initialization = initialization.future;
        final client = clientWith(serverClientId);
        final authentication = client.authenticate();
        await Future<void>.delayed(Duration.zero);
        expect(signIn.receivedServerClientId, testClientId);
        expect(signIn.calls, ['initialize']);

        initialization.complete();
        // The fake cancels at the authentication boundary, after initialization.
        expect((await authentication).outcome, YouTubeAuthOutcome.cancelled);
        expect(signIn.calls, [
          'initialize',
          'supportsAuthenticate',
          'authenticate',
        ]);
        await client.authenticate();
        expect(
          signIn.calls.where((call) => call == 'initialize'),
          hasLength(1),
        );
      },
    );
  }

  test(
    'default configuration forwards the compile-time environment value',
    () async {
      const environmentId = String.fromEnvironment(
        'GOOGLE_OAUTH_SERVER_CLIENT_ID',
      );
      final client = GoogleOAuthClient(
        googleSignIn: signIn,
        diagnostics: diagnostics,
      );
      final result = await client.authenticate();
      if (environmentId.trim().isEmpty) {
        expect(
          result.failure?.type,
          YouTubeConnectionFailureType.configuration,
        );
        expect(signIn.calls, isEmpty);
      } else {
        expect(signIn.receivedServerClientId, environmentId.trim());
        expect(result.outcome, YouTubeAuthOutcome.cancelled);
        expect(signIn.calls, [
          'initialize',
          'supportsAuthenticate',
          'authenticate',
        ]);
      }
    },
  );

  for (final code in [
    GoogleSignInExceptionCode.clientConfigurationError,
    GoogleSignInExceptionCode.providerConfigurationError,
  ]) {
    for (final duringInitialization in [true, false]) {
      test(
        'maps $code safely during ${duringInitialization ? 'initialization' : 'authentication'}',
        () async {
          final error = GoogleSignInException(
            code: code,
            description: 'sensitive-description-sentinel',
            details: 'sensitive-details-sentinel',
          );
          if (duringInitialization) {
            signIn.initializationError = error;
          } else {
            signIn.authenticationError = error;
          }
          final client = clientWith(testClientId);
          final result = await client.authenticate();
          expect(result.outcome, YouTubeAuthOutcome.failure);
          expect(
            result.failure?.type,
            YouTubeConnectionFailureType.configuration,
          );
          expect(
            youtubeConnectionFailureMessage(result.failure),
            'Google sign-in is not configured for this build.',
          );
          expect(
            diagnostics.events,
            duringInitialization ? isEmpty : ['OAuth step started'],
          );
          if (duringInitialization) {
            expect(signIn.calls, ['initialize']);
            final restored = await client.restoreAuthentication();
            expect(
              restored.failure?.type,
              YouTubeConnectionFailureType.configuration,
            );
            expect(signIn.calls, ['initialize']);
          }
        },
      );
    }
  }
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  final calls = <String>[];
  String? receivedServerClientId;
  Future<void>? initialization;
  GoogleSignInException? initializationError;
  GoogleSignInException? authenticationError;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    calls.add('initialize');
    receivedServerClientId = serverClientId;
    if (initializationError != null) {
      throw initializationError!;
    }
    await initialization;
  }

  @override
  bool supportsAuthenticate() {
    calls.add('supportsAuthenticate');
    return true;
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const [],
  }) async {
    calls.add('authenticate');
    throw authenticationError ??
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled);
  }

  @override
  Future<GoogleSignInAccount?>? attemptLightweightAuthentication({
    bool reportAllExceptions = false,
  }) {
    calls.add('attemptLightweightAuthentication');
    return null;
  }
}

class _RecordingDiagnostics implements YouTubeAuthDiagnostics {
  final events = <String>[];

  @override
  void record(String event, {int? httpStatus}) => events.add(event);
}
