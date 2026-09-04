import '../../domain/models/youtube_auth_result.dart';
import '../../domain/models/youtube_connection.dart';
import '../../domain/repositories/youtube_auth_repository.dart';
import '../auth/google_oauth_client.dart';
import '../storage/youtube_auth_secure_storage.dart';

class OAuthYouTubeAuthRepository implements YouTubeAuthRepository {
  const OAuthYouTubeAuthRepository({
    required this.oauthClient,
    required this.secureStorage,
  });

  final GoogleOAuthClient oauthClient;
  final YouTubeAuthSecureStorage secureStorage;

  @override
  Future<YouTubeAuthResult> authenticate() => oauthClient.authenticate();

  @override
  Future<YouTubeAuthResult> restoreAuthentication() {
    return oauthClient.restoreAuthentication();
  }

  @override
  Future<YouTubeConnection?> readValidatedConnection() {
    return secureStorage.readValidatedConnection();
  }

  @override
  Future<void> saveValidatedConnection(YouTubeConnection connection) {
    return secureStorage.saveValidatedConnection(connection);
  }

  @override
  Future<void> clearStoredConnection() => secureStorage.clear();

  @override
  Future<void> disconnect() async {
    await oauthClient.disconnect();
    await secureStorage.clear();
  }
}
