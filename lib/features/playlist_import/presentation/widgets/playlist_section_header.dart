import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PlaylistSectionHeader extends StatelessWidget {
  const PlaylistSectionHeader({required this.playlistCount, super.key});

  final int playlistCount;

  @override
  Widget build(BuildContext context) {
    final playlistLabel = playlistCount == 1 ? 'playlist' : 'playlists';

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your playlists',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            '$playlistCount $playlistLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
