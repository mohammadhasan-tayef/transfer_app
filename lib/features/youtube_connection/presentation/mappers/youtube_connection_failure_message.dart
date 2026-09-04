import '../../domain/models/youtube_connection_failure.dart';

String youtubeConnectionFailureMessage(
  YouTubeConnectionFailure? failure, {
  String fallbackMessage = 'The connection could not be verified.',
}) {
  if (failure == null) {
    return fallbackMessage;
  }
  return switch (failure.type) {
    YouTubeConnectionFailureType.cancelled =>
      'Google sign-in was cancelled. You can try again.',
    YouTubeConnectionFailureType.noInternet =>
      'No internet connection. Check your connection and try again.',
    YouTubeConnectionFailureType.timeout =>
      'The connection check timed out. Please try again.',
    YouTubeConnectionFailureType.configuration =>
      'Google sign-in is not configured for this build.',
    YouTubeConnectionFailureType.authenticationFailed =>
      'Google authentication did not grant the required YouTube access.',
    YouTubeConnectionFailureType.validationFailed =>
      'Google sign-in succeeded, but YouTube Music access could not be verified.',
    YouTubeConnectionFailureType.rateLimited =>
      'YouTube is receiving too many requests. Please try again later.',
    YouTubeConnectionFailureType.serverError =>
      'YouTube Music is temporarily unavailable. Please try again.',
    YouTubeConnectionFailureType.malformedResponse =>
      'YouTube Music returned an unexpected response. Please try again.',
    YouTubeConnectionFailureType.unknown =>
      'Could not connect to YouTube Music. Please try again.',
  };
}
