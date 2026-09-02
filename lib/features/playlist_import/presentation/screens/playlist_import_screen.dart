import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../youtube_connection/presentation/screens/youtube_connection_screen.dart';
import '../../application/use_cases/import_playlists.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/playlist_import_result.dart';
import '../widgets/empty_playlist_state.dart';
import '../widgets/import_continue_button.dart';
import '../widgets/import_playlist_card.dart';
import '../widgets/playlist_list.dart';
import '../widgets/playlist_section_header.dart';
import '../widgets/privacy_notice_card.dart';
import '../widgets/transfer_header.dart';

class PlaylistImportScreen extends StatefulWidget {
  const PlaylistImportScreen({required this.importPlaylists, super.key});

  final ImportPlaylists importPlaylists;

  @override
  State<PlaylistImportScreen> createState() => _PlaylistImportScreenState();
}

class _PlaylistImportScreenState extends State<PlaylistImportScreen> {
  static const _maxContentWidth = 520.0;

  final List<Playlist> _playlists = [];
  bool _isImporting = false;

  bool get _hasPlaylists => _playlists.isNotEmpty;

  int get _totalTracks {
    return _playlists.fold(0, (total, playlist) => total + playlist.trackCount);
  }

  Future<void> _importPlaylists() async {
    if (_isImporting) {
      return;
    }

    setState(() => _isImporting = true);

    try {
      final importResult = await widget.importPlaylists(
        importedSourceFileNames: _playlists.map(
          (playlist) => playlist.sourceFileName,
        ),
      );
      if (!mounted) {
        return;
      }

      if (importResult.playlists.isNotEmpty) {
        setState(() => _playlists.addAll(importResult.playlists));
      }

      _showImportFeedback(
        importedCount: importResult.playlists.length,
        failures: importResult.failures,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('The selected files could not be imported.');
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showImportFeedback({
    required int importedCount,
    required List<PlaylistImportFailure> failures,
  }) {
    final messages = <String>[];

    if (importedCount > 0) {
      final noun = importedCount == 1 ? 'playlist' : 'playlists';
      messages.add('$importedCount $noun imported.');
    }
    messages.addAll(failures.map((failure) => failure.message));

    if (messages.isNotEmpty) {
      _showMessage(messages.join('\n'));
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showExportifyPlaceholder() {
    _showMessage('The Exportify link will be available next.');
  }

  void _goToYouTubeConnection() {
    if (!_hasPlaylists) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const YouTubeConnectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),
                          const TransferHeader(),
                          const SizedBox(height: 42),
                          ImportPlaylistCard(
                            onPressed: _isImporting ? null : _importPlaylists,
                            isLoading: _isImporting,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You can select multiple Exportify CSV files',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _showExportifyPlaceholder,
                            child: const Text(
                              "Don't have CSV files? Get them from Exportify",
                            ),
                          ),
                          const SizedBox(height: 20),
                          PlaylistSectionHeader(
                            playlistCount: _playlists.length,
                          ),
                          const SizedBox(height: 16),
                          if (_playlists.isEmpty)
                            const EmptyPlaylistState()
                          else
                            PlaylistList(playlists: _playlists),
                          const SizedBox(height: 32),
                          const PrivacyNoticeCard(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ImportContinueButton(
                    enabled: _hasPlaylists,
                    trackCount: _totalTracks,
                    onPressed: _goToYouTubeConnection,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
