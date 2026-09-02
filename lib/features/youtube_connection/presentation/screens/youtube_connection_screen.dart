import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class YouTubeConnectionScreen extends StatelessWidget {
  const YouTubeConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Connect YouTube Music',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
