import 'dart:developer' as developer;

abstract interface class YouTubeAuthDiagnostics {
  void record(String event, {int? httpStatus});
}

class SafeYouTubeAuthDiagnostics implements YouTubeAuthDiagnostics {
  const SafeYouTubeAuthDiagnostics();

  @override
  void record(String event, {int? httpStatus}) {
    final statusSuffix = httpStatus == null ? '' : ' (HTTP $httpStatus)';
    developer.log('$event$statusSuffix', name: 'youtube_connection');
  }
}
