import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ImportPlaylistCard extends StatelessWidget {
  const ImportPlaylistCard({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.spotifyGreen.withValues(alpha: 0.15),
                AppColors.surface.withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(
              color: AppColors.spotifyGreen.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: [
              _ImportIcon(isLoading: isLoading),
              const SizedBox(height: 22),
              Text(
                isLoading ? 'Importing playlists...' : 'Import your playlists',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose playlist CSV files exported from Exportify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const _CsvBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportIcon extends StatelessWidget {
  const _ImportIcon({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.spotifyGreen.withValues(alpha: 0.16),
        border: Border.all(
          color: AppColors.spotifyGreen.withValues(alpha: 0.6),
        ),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(19),
              child: CircularProgressIndicator(
                color: AppColors.spotifyGreen,
                strokeWidth: 2.5,
              ),
            )
          : const Icon(
              Icons.add_rounded,
              color: AppColors.spotifyGreen,
              size: 36,
            ),
    );
  }
}

class _CsvBadge extends StatelessWidget {
  const _CsvBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            color: AppColors.textSecondary,
            size: 16,
          ),
          SizedBox(width: 7),
          Text(
            'CSV files',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
