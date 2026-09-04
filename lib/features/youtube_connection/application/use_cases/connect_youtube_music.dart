import '../../domain/models/youtube_auth_result.dart';
import '../../domain/models/youtube_connection.dart';
import '../../domain/models/youtube_connection_failure.dart';
import '../../domain/repositories/youtube_auth_repository.dart';
import 'validate_youtube_connection.dart';

class ConnectYouTubeMusic {
  const ConnectYouTubeMusic(
    this._authRepository,
    this._validateConnection, {
    this.now = DateTime.now,
  });

  final YouTubeAuthRepository _authRepository;
  final ValidateYouTubeConnection _validateConnection;
  final DateTime Function() now;

  Stream<YouTubeConnection> call() async* {
    yield const YouTubeConnection.authenticating();

    final authResult = await _authRepository.authenticate();
    if (authResult.outcome == YouTubeAuthOutcome.cancelled) {
      yield const YouTubeConnection.disconnected();
      return;
    }
    if (!authResult.isSuccess) {
      yield YouTubeConnection.error(
        authResult.failure ??
            const YouTubeConnectionFailure(
              YouTubeConnectionFailureType.authenticationFailed,
            ),
      );
      return;
    }

    final accountIdentifier = authResult.accountIdentifier!;
    yield YouTubeConnection.validating(
      accountIdentifier: accountIdentifier,
      displayName: authResult.displayName,
    );

    final validation = await _validateConnection();
    if (!validation.succeeded) {
      await _authRepository.clearStoredConnection();
      yield YouTubeConnection.error(
        validation.failure ??
            const YouTubeConnectionFailure(
              YouTubeConnectionFailureType.validationFailed,
            ),
        accountIdentifier: accountIdentifier,
        displayName: authResult.displayName,
      );
      return;
    }

    final validatedAt = now().toUtc();
    final connection = YouTubeConnection.connected(
      accountIdentifier: accountIdentifier,
      displayName: authResult.displayName,
      connectedAt: validatedAt,
      innerTubeValidatedAt: validatedAt,
    );
    await _authRepository.saveValidatedConnection(connection);
    yield connection;
  }
}
