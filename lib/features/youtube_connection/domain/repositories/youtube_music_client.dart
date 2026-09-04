import '../models/youtube_connection_validation_result.dart';

abstract interface class YouTubeMusicClient {
  Future<YouTubeConnectionValidationResult> validateAuthentication();
}
