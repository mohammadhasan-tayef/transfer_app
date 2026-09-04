import '../models/youtube_auth_result.dart';
import '../models/youtube_connection.dart';

abstract interface class YouTubeAuthRepository {
  Future<YouTubeAuthResult> authenticate();

  Future<YouTubeAuthResult> restoreAuthentication();

  Future<YouTubeConnection?> readValidatedConnection();

  Future<void> saveValidatedConnection(YouTubeConnection connection);

  Future<void> clearStoredConnection();

  Future<void> disconnect();
}
