import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/playlist_import/application/use_cases/import_playlists.dart';
import 'features/playlist_import/data/repositories/file_picker_playlist_import_repository.dart';
import 'features/playlist_import/presentation/screens/playlist_import_screen.dart';

class MusicTransferApp extends StatelessWidget {
  const MusicTransferApp({super.key});

  static const _playlistImportRepository = FilePickerPlaylistImportRepository();
  static const _importPlaylists = ImportPlaylists(_playlistImportRepository);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Transfer',
      theme: AppTheme.dark,
      home: const PlaylistImportScreen(importPlaylists: _importPlaylists),
    );
  }
}
