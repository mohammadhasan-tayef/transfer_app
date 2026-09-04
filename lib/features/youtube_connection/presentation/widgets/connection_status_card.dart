import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/youtube_connection.dart';
import '../../domain/models/youtube_connection_status.dart';
import '../mappers/youtube_connection_failure_message.dart';

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({required this.connection, super.key});

  final YouTubeConnection connection;

  @override
  Widget build(BuildContext context) {
    final details = _detailsFor(connection);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(details.icon, color: details.color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    details.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (connection.status == YouTubeConnectionStatus.connected &&
                      connection.accountIdentifier != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      connection.accountIdentifier!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ConnectionStatusDetails _detailsFor(YouTubeConnection connection) {
    return switch (connection.status) {
      YouTubeConnectionStatus.disconnected => const _ConnectionStatusDetails(
        title: 'Not connected',
        message: 'Connect your Google account to continue.',
        icon: Icons.link_off_rounded,
        color: AppColors.textMuted,
      ),
      YouTubeConnectionStatus.authenticating => const _ConnectionStatusDetails(
        title: 'Connecting...',
        message: 'Waiting for Google sign-in.',
        icon: Icons.open_in_browser_rounded,
        color: AppColors.youtubeRed,
      ),
      YouTubeConnectionStatus.validating => const _ConnectionStatusDetails(
        title: 'Verifying...',
        message: 'Verifying your YouTube Music connection with InnerTube.',
        icon: Icons.verified_user_outlined,
        color: AppColors.youtubeRed,
      ),
      YouTubeConnectionStatus.connected => const _ConnectionStatusDetails(
        title: 'Connected',
        message: 'Your authenticated YouTube Music connection is ready.',
        icon: Icons.check_circle_rounded,
        color: AppColors.spotifyGreen,
      ),
      YouTubeConnectionStatus.error => _ConnectionStatusDetails(
        title: "Couldn't connect to YouTube Music",
        message: youtubeConnectionFailureMessage(connection.failure),
        icon: Icons.error_outline_rounded,
        color: AppColors.youtubeRed,
      ),
    };
  }
}

class _ConnectionStatusDetails {
  const _ConnectionStatusDetails({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}
