import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ImportContinueButton extends StatelessWidget {
  const ImportContinueButton({
    required this.enabled,
    this.trackCount = 0,
    this.onPressed,
    super.key,
  });

  final bool enabled;
  final int trackCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.spotifyGreen,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.disabledBackground,
          disabledForegroundColor: AppColors.disabledForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 21),
          ],
        ),
      ),
    );
  }

  String get _label {
    if (trackCount == 0) {
      return 'Continue';
    }

    final trackLabel = trackCount == 1 ? 'track' : 'tracks';
    return 'Continue with ${_formatCount(trackCount)} $trackLabel';
  }

  String _formatCount(int count) {
    final digits = count.toString();
    final formatted = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(digits[index]);
    }

    return formatted.toString();
  }
}
