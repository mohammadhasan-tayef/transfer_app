import '../models/youtube_write_capability_result.dart';

abstract interface class YouTubeWriteCapabilityClient {
  Future<YouTubeWriteCapabilityResult> runDevelopmentWriteCapabilityCheck({
    String? videoId,
  });
}
