import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/core/theme/app_theme.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/connect_youtube_music.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/disconnect_youtube_music.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/restore_youtube_connection.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/run_youtube_write_capability_check.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/validate_youtube_connection.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_auth_result.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_failure.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_validation_result.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_write_capability_result.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/repositories/youtube_auth_repository.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/repositories/youtube_music_client.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/repositories/youtube_write_capability_client.dart';
import 'package:transfer_aplicationn/features/youtube_connection/presentation/screens/youtube_connection_screen.dart';

void main() {
  testWidgets('Continue stays disabled while disconnected', (tester) async {
    final dependencies = _Dependencies.disconnected();
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();

    expect(find.text('Not connected'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
  });

  testWidgets('successful validation enables Continue and navigates to Home', (
    tester,
  ) async {
    final dependencies = _Dependencies(
      repository: _FakeRepository(
        authResult: const YouTubeAuthResult.success(
          accountIdentifier: 'listener@example.com',
        ),
      ),
      client: _FakeClient(const YouTubeConnectionValidationResult.success()),
    );
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Connect YouTube Music'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('listener@example.com'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Future Home'), findsOneWidget);
  });

  testWidgets('validation failure shows retry and keeps Continue disabled', (
    tester,
  ) async {
    final dependencies = _Dependencies(
      repository: _FakeRepository(
        authResult: const YouTubeAuthResult.success(
          accountIdentifier: 'listener@example.com',
        ),
      ),
      client: _FakeClient(
        YouTubeConnectionValidationResult.failure(
          const YouTubeConnectionFailure(
            YouTubeConnectionFailureType.validationFailed,
            httpStatus: 400,
          ),
        ),
      ),
    );
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Connect YouTube Music'),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't connect to YouTube Music"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Try again'), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
  });

  testWidgets('double tap starts only one authentication attempt', (
    tester,
  ) async {
    final authCompleter = Completer<YouTubeAuthResult>();
    final repository = _FakeRepository(authFuture: authCompleter.future);
    final dependencies = _Dependencies(
      repository: repository,
      client: _FakeClient(const YouTubeConnectionValidationResult.success()),
    );
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();
    final connectButton = find.widgetWithText(
      ElevatedButton,
      'Connect YouTube Music',
    );

    await tester.tap(connectButton);
    await tester.tap(connectButton);
    await tester.pump();

    expect(repository.authenticateCalls, 1);
    authCompleter.complete(const YouTubeAuthResult.cancelled());
    await tester.pumpAndSettle();
  });
  testWidgets('disconnect failure becomes a recoverable error state', (
    tester,
  ) async {
    final repository = _FakeRepository(
      authResult: const YouTubeAuthResult.success(
        accountIdentifier: 'listener@example.com',
      ),
      disconnectError: StateError('disconnect failed'),
    );
    final dependencies = _Dependencies(
      repository: repository,
      client: _FakeClient(const YouTubeConnectionValidationResult.success()),
    );
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Connect YouTube Music'),
    );
    await tester.pumpAndSettle();
    final disconnectButton = find.widgetWithText(TextButton, 'Disconnect');
    await tester.ensureVisible(disconnectButton);
    await tester.tap(disconnectButton);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't connect to YouTube Music"), findsOneWidget);
    expect(_continueButton(tester).onPressed, isNull);
  });

  testWidgets('Continue stays disabled while disconnect is in flight', (
    tester,
  ) async {
    final disconnectCompleter = Completer<void>();
    final repository = _FakeRepository(
      authResult: const YouTubeAuthResult.success(
        accountIdentifier: 'listener@example.com',
      ),
      disconnectFuture: disconnectCompleter.future,
    );
    final dependencies = _Dependencies(
      repository: repository,
      client: _FakeClient(const YouTubeConnectionValidationResult.success()),
    );
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Connect YouTube Music'),
    );
    await tester.pumpAndSettle();
    final disconnectButton = find.widgetWithText(TextButton, 'Disconnect');
    await tester.ensureVisible(disconnectButton);
    await tester.tap(disconnectButton);
    await tester.pump();

    expect(_continueButton(tester).onPressed, isNull);

    disconnectCompleter.complete();
    await tester.pumpAndSettle();
    expect(find.text('Not connected'), findsOneWidget);
  });

  testWidgets('completion after disposal does not call setState', (
    tester,
  ) async {
    final authCompleter = Completer<YouTubeAuthResult>();
    final dependencies = _Dependencies(
      repository: _FakeRepository(authFuture: authCompleter.future),
      client: _FakeClient(const YouTubeConnectionValidationResult.success()),
    );
    await tester.pumpWidget(dependencies.app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Connect YouTube Music'),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    authCompleter.complete(const YouTubeAuthResult.cancelled());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

ElevatedButton _continueButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Continue'),
  );
}

class _Dependencies {
  const _Dependencies({required this.repository, required this.client});

  factory _Dependencies.disconnected() {
    return _Dependencies(
      repository: _FakeRepository(
        authResult: const YouTubeAuthResult.cancelled(),
      ),
      client: _FakeClient(const YouTubeConnectionValidationResult.success()),
    );
  }

  final _FakeRepository repository;
  final _FakeClient client;

  Widget app() {
    final validate = ValidateYouTubeConnection(client);
    return MaterialApp(
      theme: AppTheme.dark,
      home: YouTubeConnectionScreen(
        connectYouTubeMusic: ConnectYouTubeMusic(repository, validate),
        restoreYouTubeConnection: RestoreYouTubeConnection(
          repository,
          validate,
        ),
        disconnectYouTubeMusic: DisconnectYouTubeMusic(repository),
        runWriteCapabilityCheck: RunYouTubeWriteCapabilityCheck(client),
        homeBuilder: (_) => const Scaffold(body: Text('Future Home')),
      ),
    );
  }
}

class _FakeRepository implements YouTubeAuthRepository {
  _FakeRepository({
    this.authResult,
    this.authFuture,
    this.disconnectFuture,
    this.disconnectError,
  });

  final YouTubeAuthResult? authResult;
  final Future<void>? disconnectFuture;
  final Object? disconnectError;
  final Future<YouTubeAuthResult>? authFuture;
  int authenticateCalls = 0;
  YouTubeConnection? storedConnection;

  @override
  Future<YouTubeAuthResult> authenticate() {
    authenticateCalls += 1;
    return authFuture ?? Future.value(authResult);
  }

  @override
  Future<YouTubeAuthResult> restoreAuthentication() async {
    return const YouTubeAuthResult.cancelled();
  }

  @override
  Future<YouTubeConnection?> readValidatedConnection() async =>
      storedConnection;

  @override
  Future<void> saveValidatedConnection(YouTubeConnection connection) async {
    storedConnection = connection;
  }

  @override
  Future<void> clearStoredConnection() async {
    storedConnection = null;
  }

  @override
  Future<void> disconnect() async {
    final error = disconnectError;
    if (error != null) {
      throw error;
    }
    final pendingDisconnect = disconnectFuture;
    if (pendingDisconnect != null) {
      await pendingDisconnect;
    }
    storedConnection = null;
  }
}

class _FakeClient implements YouTubeMusicClient, YouTubeWriteCapabilityClient {
  const _FakeClient(this.validationResult);

  final YouTubeConnectionValidationResult validationResult;

  @override
  Future<YouTubeConnectionValidationResult> validateAuthentication() async {
    return validationResult;
  }

  @override
  Future<YouTubeWriteCapabilityResult> runDevelopmentWriteCapabilityCheck({
    String? videoId,
  }) async {
    return const YouTubeWriteCapabilityResult.success(
      playlistId: 'temporary-playlist',
      itemAdded: false,
    );
  }
}
