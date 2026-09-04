import 'youtube_connection_failure.dart';

enum YouTubeAuthOutcome { success, cancelled, failure }

class YouTubeAuthResult {
  const YouTubeAuthResult._({
    required this.outcome,
    this.accountIdentifier,
    this.displayName,
    this.failure,
  });

  const YouTubeAuthResult.success({
    required String accountIdentifier,
    String? displayName,
  }) : this._(
         outcome: YouTubeAuthOutcome.success,
         accountIdentifier: accountIdentifier,
         displayName: displayName,
       );

  const YouTubeAuthResult.cancelled()
    : this._(
        outcome: YouTubeAuthOutcome.cancelled,
        failure: const YouTubeConnectionFailure(
          YouTubeConnectionFailureType.cancelled,
        ),
      );

  const YouTubeAuthResult.failure(YouTubeConnectionFailure failure)
    : this._(outcome: YouTubeAuthOutcome.failure, failure: failure);

  final YouTubeAuthOutcome outcome;
  final String? accountIdentifier;
  final String? displayName;
  final YouTubeConnectionFailure? failure;

  bool get isSuccess => outcome == YouTubeAuthOutcome.success;
}
