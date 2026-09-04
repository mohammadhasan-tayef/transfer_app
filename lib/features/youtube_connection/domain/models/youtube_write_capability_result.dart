import 'youtube_connection_failure.dart';

class YouTubeWriteCapabilityResult {
  const YouTubeWriteCapabilityResult._({
    required this.succeeded,
    this.playlistId,
    this.itemAdded = false,
    this.httpStatus,
    this.failure,
  });

  const YouTubeWriteCapabilityResult.success({
    required String playlistId,
    required bool itemAdded,
    int httpStatus = 200,
  }) : this._(
         succeeded: true,
         playlistId: playlistId,
         itemAdded: itemAdded,
         httpStatus: httpStatus,
       );

  YouTubeWriteCapabilityResult.failure(YouTubeConnectionFailure failure)
    : this._(
        succeeded: false,
        httpStatus: failure.httpStatus,
        failure: failure,
      );

  final bool succeeded;
  final String? playlistId;
  final bool itemAdded;
  final int? httpStatus;
  final YouTubeConnectionFailure? failure;
}
