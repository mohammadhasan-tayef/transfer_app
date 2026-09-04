import 'youtube_connection_failure.dart';
import 'youtube_connection_status.dart';

class YouTubeConnection {
  const YouTubeConnection._({
    required this.status,
    this.accountIdentifier,
    this.displayName,
    this.connectedAt,
    this.innerTubeValidatedAt,
    this.failure,
  });

  const YouTubeConnection.disconnected()
    : this._(status: YouTubeConnectionStatus.disconnected);

  const YouTubeConnection.authenticating()
    : this._(status: YouTubeConnectionStatus.authenticating);

  const YouTubeConnection.validating({
    required String accountIdentifier,
    String? displayName,
  }) : this._(
         status: YouTubeConnectionStatus.validating,
         accountIdentifier: accountIdentifier,
         displayName: displayName,
       );

  YouTubeConnection.connected({
    required String accountIdentifier,
    String? displayName,
    required DateTime connectedAt,
    required DateTime innerTubeValidatedAt,
  }) : this._(
         status: YouTubeConnectionStatus.connected,
         accountIdentifier: accountIdentifier,
         displayName: displayName,
         connectedAt: connectedAt,
         innerTubeValidatedAt: innerTubeValidatedAt,
       );

  const YouTubeConnection.error(
    YouTubeConnectionFailure failure, {
    String? accountIdentifier,
    String? displayName,
  }) : this._(
         status: YouTubeConnectionStatus.error,
         accountIdentifier: accountIdentifier,
         displayName: displayName,
         failure: failure,
       );

  final YouTubeConnectionStatus status;
  final String? accountIdentifier;
  final String? displayName;
  final DateTime? connectedAt;
  final DateTime? innerTubeValidatedAt;
  final YouTubeConnectionFailure? failure;

  bool get canContinue {
    return status == YouTubeConnectionStatus.connected &&
        innerTubeValidatedAt != null;
  }
}
