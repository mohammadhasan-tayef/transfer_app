import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/connect_youtube_music.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/restore_youtube_connection.dart';
import 'package:transfer_aplicationn/features/youtube_connection/application/use_cases/validate_youtube_connection.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_auth_result.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_failure.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_status.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection_validation_result.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/repositories/youtube_auth_repository.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/repositories/youtube_music_client.dart';

void main() {
  const successfulAuth = YouTubeAuthResult.success(
    accountIdentifier: 'listener@example.com',
    displayName: 'Listener',
  );
  final now = DateTime.utc(2026, 9, 2, 12);

  test(
    'connection cannot become connected before validation succeeds',
    () async {
      final repository = _FakeYouTubeAuthRepository(
        authenticationResults: [successfulAuth],
      );
      final client = _FakeYouTubeMusicClient([
        const YouTubeConnectionValidationResult.success(),
      ]);
      final connect = ConnectYouTubeMusic(
        repository,
        ValidateYouTubeConnection(client),
        now: () => now,
      );

      final states = await connect().toList();

      expect(states.map((state) => state.status), [
        YouTubeConnectionStatus.authenticating,
        YouTubeConnectionStatus.validating,
        YouTubeConnectionStatus.connected,
      ]);
      expect(states[0].canContinue, isFalse);
      expect(states[1].canContinue, isFalse);
      expect(states[2].canContinue, isTrue);
    },
  );

  test('authentication cancellation stays disconnected', () async {
    final repository = _FakeYouTubeAuthRepository(
      authenticationResults: [const YouTubeAuthResult.cancelled()],
    );
    final client = _FakeYouTubeMusicClient([]);
    final connect = ConnectYouTubeMusic(
      repository,
      ValidateYouTubeConnection(client),
    );

    final states = await connect().toList();

    expect(states.map((state) => state.status), [
      YouTubeConnectionStatus.authenticating,
      YouTubeConnectionStatus.disconnected,
    ]);
    expect(client.validationCalls, 0);
    expect(states.last.canContinue, isFalse);
  });

  test('validation failure produces an error and never connects', () async {
    final repository = _FakeYouTubeAuthRepository(
      authenticationResults: [successfulAuth],
    );
    final client = _FakeYouTubeMusicClient([
      YouTubeConnectionValidationResult.failure(
        const YouTubeConnectionFailure(
          YouTubeConnectionFailureType.authenticationFailed,
          httpStatus: 401,
        ),
      ),
    ]);
    final connect = ConnectYouTubeMusic(
      repository,
      ValidateYouTubeConnection(client),
    );

    final states = await connect().toList();

    expect(states.last.status, YouTubeConnectionStatus.error);
    expect(states.last.canContinue, isFalse);
    expect(states.last.failure?.httpStatus, 401);
    expect(repository.clearCalls, 1);
    expect(
      states.where(
        (state) => state.status == YouTubeConnectionStatus.connected,
      ),
      isEmpty,
    );
  });

  test('validation success persists a verified connected state', () async {
    final repository = _FakeYouTubeAuthRepository(
      authenticationResults: [successfulAuth],
    );
    final client = _FakeYouTubeMusicClient([
      const YouTubeConnectionValidationResult.success(httpStatus: 200),
    ]);
    final connect = ConnectYouTubeMusic(
      repository,
      ValidateYouTubeConnection(client),
      now: () => now,
    );

    final states = await connect().toList();

    expect(states.last.status, YouTubeConnectionStatus.connected);
    expect(states.last.innerTubeValidatedAt, now);
    expect(repository.savedConnection, same(states.last));
  });

  test('retry starts cleanly and clears the previous error state', () async {
    final repository = _FakeYouTubeAuthRepository(
      authenticationResults: [
        const YouTubeAuthResult.failure(
          YouTubeConnectionFailure(
            YouTubeConnectionFailureType.authenticationFailed,
          ),
        ),
        successfulAuth,
      ],
    );
    final client = _FakeYouTubeMusicClient([
      const YouTubeConnectionValidationResult.success(),
    ]);
    final connect = ConnectYouTubeMusic(
      repository,
      ValidateYouTubeConnection(client),
      now: () => now,
    );

    final firstAttempt = await connect().toList();
    final retry = await connect().toList();

    expect(firstAttempt.last.status, YouTubeConnectionStatus.error);
    expect(retry.first.status, YouTubeConnectionStatus.authenticating);
    expect(retry.first.failure, isNull);
    expect(retry.last.status, YouTubeConnectionStatus.connected);
    expect(retry.last.failure, isNull);
  });

  test('cached invalid authentication never becomes connected', () async {
    final repository = _FakeYouTubeAuthRepository(
      restoreResult: const YouTubeAuthResult.failure(
        YouTubeConnectionFailure(
          YouTubeConnectionFailureType.authenticationFailed,
        ),
      ),
      cachedConnection: YouTubeConnection.connected(
        accountIdentifier: 'old@example.com',
        connectedAt: now.subtract(const Duration(days: 1)),
        innerTubeValidatedAt: now.subtract(const Duration(days: 1)),
      ),
    );
    final client = _FakeYouTubeMusicClient([]);
    final restore = RestoreYouTubeConnection(
      repository,
      ValidateYouTubeConnection(client),
      now: () => now,
    );

    final states = await restore().toList();

    expect(states, hasLength(1));
    expect(states.single.status, YouTubeConnectionStatus.disconnected);
    expect(states.single.canContinue, isFalse);
    expect(repository.clearCalls, 1);
    expect(client.validationCalls, 0);
  });

  test(
    'restoring a different account resets cached connection metadata',
    () async {
      final previousConnectedAt = now.subtract(const Duration(days: 1));
      final repository = _FakeYouTubeAuthRepository(
        restoreResult: const YouTubeAuthResult.success(
          accountIdentifier: 'new@example.com',
        ),
        cachedConnection: YouTubeConnection.connected(
          accountIdentifier: 'old@example.com',
          connectedAt: previousConnectedAt,
          innerTubeValidatedAt: previousConnectedAt,
        ),
      );
      final client = _FakeYouTubeMusicClient([
        const YouTubeConnectionValidationResult.success(),
      ]);
      final restore = RestoreYouTubeConnection(
        repository,
        ValidateYouTubeConnection(client),
        now: () => now,
      );

      final states = await restore().toList();

      expect(states.last.status, YouTubeConnectionStatus.connected);
      expect(states.last.accountIdentifier, 'new@example.com');
      expect(states.last.connectedAt, now);
      expect(states.last.connectedAt, isNot(previousConnectedAt));
      expect(repository.clearCalls, 1);
    },
  );
}

class _FakeYouTubeAuthRepository implements YouTubeAuthRepository {
  _FakeYouTubeAuthRepository({
    List<YouTubeAuthResult> authenticationResults = const [],
    this.restoreResult = const YouTubeAuthResult.cancelled(),
    this.cachedConnection,
  }) : _authenticationResults = [...authenticationResults];

  final List<YouTubeAuthResult> _authenticationResults;
  final YouTubeAuthResult restoreResult;
  YouTubeConnection? cachedConnection;
  YouTubeConnection? savedConnection;
  int clearCalls = 0;

  @override
  Future<YouTubeAuthResult> authenticate() async {
    return _authenticationResults.removeAt(0);
  }

  @override
  Future<YouTubeAuthResult> restoreAuthentication() async => restoreResult;

  @override
  Future<YouTubeConnection?> readValidatedConnection() async {
    return cachedConnection;
  }

  @override
  Future<void> saveValidatedConnection(YouTubeConnection connection) async {
    savedConnection = connection;
    cachedConnection = connection;
  }

  @override
  Future<void> clearStoredConnection() async {
    clearCalls += 1;
    cachedConnection = null;
  }

  @override
  Future<void> disconnect() async {
    cachedConnection = null;
  }
}

class _FakeYouTubeMusicClient implements YouTubeMusicClient {
  _FakeYouTubeMusicClient(List<YouTubeConnectionValidationResult> results)
    : _results = [...results];

  final List<YouTubeConnectionValidationResult> _results;
  int validationCalls = 0;

  @override
  Future<YouTubeConnectionValidationResult> validateAuthentication() async {
    validationCalls += 1;
    return _results.removeAt(0);
  }
}
