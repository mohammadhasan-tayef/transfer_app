import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/playlist.dart';

class PlaylistList extends StatelessWidget {
  const PlaylistList({required this.playlists, super.key});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _PlaylistTile(playlist: playlists[index]);
      },
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final trackLabel = playlist.trackCount == 1 ? 'track' : 'tracks';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          _PlaylistCover(imageUrls: playlist.coverImageUrls),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${playlist.trackCount} $trackLabel',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.spotifyGreen.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.spotifyGreen,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCover extends StatelessWidget {
  const _PlaylistCover({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrls.firstOrNull;
    final imageUri = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final remoteImageUrl =
        imageUri != null &&
            imageUri.scheme == 'https' &&
            imageUri.host.isNotEmpty
        ? imageUrl
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 56,
        height: 56,
        child: remoteImageUrl == null
            ? const _PlaylistCoverPlaceholder()
            : Image.network(
                remoteImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  return loadingProgress == null
                      ? child
                      : const _PlaylistCoverPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _PlaylistCoverPlaceholder();
                },
              ),
      ),
    );
  }
}

class _PlaylistCoverPlaceholder extends StatelessWidget {
  const _PlaylistCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceSecondary,
      child: Icon(
        Icons.queue_music_rounded,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }
}
