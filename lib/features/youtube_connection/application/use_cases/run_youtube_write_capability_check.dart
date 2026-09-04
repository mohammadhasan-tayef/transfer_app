import '../../domain/models/youtube_write_capability_result.dart';
import '../../domain/repositories/youtube_write_capability_client.dart';

class RunYouTubeWriteCapabilityCheck {
  const RunYouTubeWriteCapabilityCheck(this._client);

  final YouTubeWriteCapabilityClient _client;

  Future<YouTubeWriteCapabilityResult> call({String? videoId}) {
    return _client.runDevelopmentWriteCapabilityCheck(videoId: videoId);
  }
}
