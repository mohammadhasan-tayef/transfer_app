import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../playlist_import/domain/models/playlist.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({required List<Playlist> playlists, super.key})
    : playlists = List<Playlist>.unmodifiable(playlists);

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Home',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
