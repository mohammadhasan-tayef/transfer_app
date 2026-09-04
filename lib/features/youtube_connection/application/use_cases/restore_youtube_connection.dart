import '../../domain/models/youtube_connection.dart';
import '../../domain/models/youtube_connection_failure.dart';
import '../../domain/repositories/youtube_auth_repository.dart';
import 'validate_youtube_connection.dart';

class RestoreYouTubeConnection {
  const RestoreYouTubeConnection(
    this._authRepository,
    this._validateConnection, {
    this.now = DateTime.now,
  });

  final YouTubeAuthRepository _authRepository;
  final ValidateYouTubeConnection _validateConnection;
  final DateTime Function() now;

  Stream<YouTubeConnection> call() async* {
    final cachedConnection = await _authRepository.readValidatedConnection();
    if (cachedConnection == null) {
      yield const YouTubeConnection.disconnected();
      return;
    }

    final authResult = await _authRepository.restoreAuthentication();
    if (!authResult.isSuccess) {
      await _authRepository.clearStoredConnection();
      yield const YouTubeConnection.disconnected();
      return;
    }

    final accountIdentifier = authResult.accountIdentifier!;
    final isSameAccount =
        cachedConnection.accountIdentifier == accountIdentifier;
    if (!isSameAccount) {
      await _authRepository.clearStoredConnection();
    }
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
      connectedAt: isSameAccount
          ? cachedConnection.connectedAt ?? validatedAt
          : validatedAt,
      innerTubeValidatedAt: validatedAt,
    );
    await _authRepository.saveValidatedConnection(connection);
    yield connection;
  }
}
