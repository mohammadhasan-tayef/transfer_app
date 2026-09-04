import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/youtube_connection_status.dart';

class YouTubeConnectCard extends StatelessWidget {
  const YouTubeConnectCard({
    required this.status,
    required this.isBusy,
    required this.onConnect,
    super.key,
  });

  final YouTubeConnectionStatus status;
  final bool isBusy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final isError = status == YouTubeConnectionStatus.error;
    final buttonLabel = isError ? 'Try again' : 'Connect YouTube Music';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.youtubeRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy || status == YouTubeConnectionStatus.connected
                    ? null
                    : onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.youtubeRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabledBackground,
                  disabledForegroundColor: AppColors.disabledForeground,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
