import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'animated_transfer_line.dart';

class TransferHeader extends StatelessWidget {
  const TransferHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TransferRouteIcon(
              color: AppColors.spotifyGreen,
              opacity: 0.12,
              icon: Icons.music_note_rounded,
              iconSize: 27,
            ),
            SizedBox(width: 12),
            AnimatedTransferLine(),
            SizedBox(width: 12),
            _TransferRouteIcon(
              color: AppColors.youtubeRed,
              opacity: 0.10,
              icon: Icons.play_arrow_rounded,
              iconSize: 31,
            ),
          ],
        ),
        SizedBox(height: 30),
        Text(
          'Move your music',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 10),
        _TransferRouteLabel(),
      ],
    );
  }
}

class _TransferRouteIcon extends StatelessWidget {
  const _TransferRouteIcon({
    required this.color,
    required this.opacity,
    required this.icon,
    required this.iconSize,
  });

  final Color color;
  final double opacity;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _TransferRouteLabel extends StatelessWidget {
  const _TransferRouteLabel();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Spotify playlists',
            style: TextStyle(
              color: AppColors.spotifyGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 9),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
          Text(
            'YouTube Music',
            style: TextStyle(
              color: AppColors.youtubeRed,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
