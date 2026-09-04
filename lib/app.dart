import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/playlist_import/application/use_cases/import_playlists.dart';
import 'features/playlist_import/data/repositories/file_picker_playlist_import_repository.dart';
import 'features/playlist_import/domain/models/playlist.dart';
import 'features/playlist_import/presentation/screens/playlist_import_screen.dart';
import 'features/youtube_connection/application/use_cases/connect_youtube_music.dart';
import 'features/youtube_connection/application/use_cases/disconnect_youtube_music.dart';
import 'features/youtube_connection/application/use_cases/restore_youtube_connection.dart';
import 'features/youtube_connection/application/use_cases/run_youtube_write_capability_check.dart';
import 'features/youtube_connection/application/use_cases/validate_youtube_connection.dart';
import 'features/youtube_connection/data/auth/google_oauth_client.dart';
import 'features/youtube_connection/data/clients/youtube_music_client.dart';
import 'features/youtube_connection/data/repositories/oauth_youtube_auth_repository.dart';
import 'features/youtube_connection/data/storage/youtube_auth_secure_storage.dart';
import 'features/youtube_connection/presentation/screens/youtube_connection_screen.dart';

class MusicTransferApp extends StatelessWidget {
  const MusicTransferApp({super.key});

  static const _playlistImportRepository = FilePickerPlaylistImportRepository();
  static const _importPlaylists = ImportPlaylists(_playlistImportRepository);
  static final _googleOAuthClient = GoogleOAuthClient();
  static final _youtubeAuthRepository = OAuthYouTubeAuthRepository(
    oauthClient: _googleOAuthClient,
    secureStorage: YouTubeAuthSecureStorage(),
  );
  static final _youtubeMusicClient = InnerTubeYouTubeMusicClient(
    authorizationProvider: _googleOAuthClient,
  );
  static final _validateYouTubeConnection = ValidateYouTubeConnection(
    _youtubeMusicClient,
  );
  static final _connectYouTubeMusic = ConnectYouTubeMusic(
    _youtubeAuthRepository,
    _validateYouTubeConnection,
  );
  static final _restoreYouTubeConnection = RestoreYouTubeConnection(
    _youtubeAuthRepository,
    _validateYouTubeConnection,
  );
  static final _disconnectYouTubeMusic = DisconnectYouTubeMusic(
    _youtubeAuthRepository,
  );
  static final _runWriteCapabilityCheck = RunYouTubeWriteCapabilityCheck(
    _youtubeMusicClient,
  );

  static Future<bool> _launchExportify(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Widget _buildYouTubeConnectionScreen(
    BuildContext context,
    List<Playlist> playlists,
  ) {
    return YouTubeConnectionScreen(
      connectYouTubeMusic: _connectYouTubeMusic,
      restoreYouTubeConnection: _restoreYouTubeConnection,
      disconnectYouTubeMusic: _disconnectYouTubeMusic,
      runWriteCapabilityCheck: _runWriteCapabilityCheck,
      homeBuilder: (context) => _buildHomeScreen(context, playlists),
    );
  }

  static Widget _buildHomeScreen(
    BuildContext context,
    List<Playlist> playlists,
  ) {
    return HomeScreen(playlists: playlists);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Transfer',
      theme: AppTheme.dark,
      home: const PlaylistImportScreen(
        importPlaylists: _importPlaylists,
        youtubeConnectionScreenBuilder: _buildYouTubeConnectionScreen,
        launchExportify: _launchExportify,
      ),
    );
  }
}
