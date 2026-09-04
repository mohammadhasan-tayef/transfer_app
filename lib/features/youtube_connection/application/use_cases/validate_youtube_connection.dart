import '../../domain/models/youtube_connection_validation_result.dart';
import '../../domain/repositories/youtube_music_client.dart';

class ValidateYouTubeConnection {
  const ValidateYouTubeConnection(this._client);

  final YouTubeMusicClient _client;

  Future<YouTubeConnectionValidationResult> call() {
    return _client.validateAuthentication();
  }
}
