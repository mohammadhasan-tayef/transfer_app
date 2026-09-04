import 'youtube_connection_failure.dart';

class YouTubeConnectionValidationResult {
  const YouTubeConnectionValidationResult._({
    required this.succeeded,
    this.httpStatus,
    this.failure,
  });

  const YouTubeConnectionValidationResult.success({int httpStatus = 200})
    : this._(succeeded: true, httpStatus: httpStatus);

  YouTubeConnectionValidationResult.failure(YouTubeConnectionFailure failure)
    : this._(
        succeeded: false,
        httpStatus: failure.httpStatus,
        failure: failure,
      );

  final bool succeeded;
  final int? httpStatus;
  final YouTubeConnectionFailure? failure;
}
