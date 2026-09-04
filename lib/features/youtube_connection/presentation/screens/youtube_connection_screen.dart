import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/use_cases/connect_youtube_music.dart';
import '../../application/use_cases/disconnect_youtube_music.dart';
import '../../application/use_cases/restore_youtube_connection.dart';
import '../../application/use_cases/run_youtube_write_capability_check.dart';
import '../../domain/models/youtube_connection.dart';
import '../../domain/models/youtube_connection_failure.dart';
import '../../domain/models/youtube_connection_status.dart';
import '../mappers/youtube_connection_failure_message.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/youtube_connect_card.dart';
import '../widgets/youtube_continue_button.dart';

class YouTubeConnectionScreen extends StatefulWidget {
  const YouTubeConnectionScreen({
    required this.connectYouTubeMusic,
    required this.restoreYouTubeConnection,
    required this.disconnectYouTubeMusic,
    required this.runWriteCapabilityCheck,
    required this.homeBuilder,
    super.key,
  });

  final ConnectYouTubeMusic connectYouTubeMusic;
  final RestoreYouTubeConnection restoreYouTubeConnection;
  final DisconnectYouTubeMusic disconnectYouTubeMusic;
  final RunYouTubeWriteCapabilityCheck runWriteCapabilityCheck;
  final WidgetBuilder homeBuilder;

  @override
  State<YouTubeConnectionScreen> createState() =>
      _YouTubeConnectionScreenState();
}

class _YouTubeConnectionScreenState extends State<YouTubeConnectionScreen> {
  static const _maxContentWidth = 520.0;
  static const _writePocEnabled = bool.fromEnvironment(
    'ENABLE_YOUTUBE_WRITE_POC',
  );
  static const _pocVideoId = String.fromEnvironment('YOUTUBE_POC_VIDEO_ID');

  YouTubeConnection _connection = const YouTubeConnection.disconnected();
  bool _isRunningConnectionFlow = false;
  bool _isNavigating = false;
  bool _isRunningWriteCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _runConnectionFlow(widget.restoreYouTubeConnection());
    });
  }

  Future<void> _connect() {
    return _runConnectionFlow(widget.connectYouTubeMusic());
  }

  Future<void> _runConnectionFlow(Stream<YouTubeConnection> flow) async {
    if (!mounted || _isRunningConnectionFlow) {
      return;
    }
    setState(() => _isRunningConnectionFlow = true);

    try {
      await for (final connection in flow) {
        if (!mounted) {
          return;
        }
        setState(() => _connection = connection);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _connection = const YouTubeConnection.error(
            YouTubeConnectionFailure(YouTubeConnectionFailureType.unknown),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningConnectionFlow = false);
      }
    }
  }

  Future<void> _disconnect() async {
    if (_isRunningConnectionFlow || _isRunningWriteCheck) {
      return;
    }
    setState(() => _isRunningConnectionFlow = true);
    try {
      await widget.disconnectYouTubeMusic();
      if (mounted) {
        setState(() => _connection = const YouTubeConnection.disconnected());
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _connection = const YouTubeConnection.error(
            YouTubeConnectionFailure(YouTubeConnectionFailureType.unknown),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningConnectionFlow = false);
      }
    }
  }

  Future<void> _continue() async {
    if (!_connection.canContinue ||
        _isNavigating ||
        _isRunningConnectionFlow ||
        _isRunningWriteCheck) {
      return;
    }
    setState(() => _isNavigating = true);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: widget.homeBuilder));
    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  Future<void> _runDevelopmentWriteCheck() async {
    if (_isRunningConnectionFlow ||
        _isRunningWriteCheck ||
        !_connection.canContinue) {
      return;
    }
    setState(() => _isRunningWriteCheck = true);

    var message = 'Write capability check failed.';
    try {
      final result = await widget.runWriteCapabilityCheck(
        videoId: _pocVideoId.isEmpty ? null : _pocVideoId,
      );
      if (!mounted) {
        return;
      }
      message = result.succeeded
          ? 'Temporary playlist created${result.itemAdded ? ' and test item added' : ''}.'
          : youtubeConnectionFailureMessage(
              result.failure,
              fallbackMessage: 'Write capability check failed.',
            );
    } catch (_) {
      message = 'Write capability check failed.';
    } finally {
      if (mounted) {
        setState(() => _isRunningWriteCheck = false);
      }
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final status = _connection.status;
    final isBusy =
        _isRunningConnectionFlow ||
        _isRunningWriteCheck ||
        status == YouTubeConnectionStatus.authenticating ||
        status == YouTubeConnectionStatus.validating;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Connect YouTube Music',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sign in securely, then we will verify real YouTube Music access.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          YouTubeConnectCard(
                            status: status,
                            isBusy: isBusy,
                            onConnect: _connect,
                          ),
                          const SizedBox(height: 18),
                          ConnectionStatusCard(connection: _connection),
                          if (_connection.canContinue) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: isBusy ? null : _disconnect,
                              child: const Text('Disconnect'),
                            ),
                          ],
                          if (kDebugMode &&
                              _writePocEnabled &&
                              _connection.canContinue) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : _runDevelopmentWriteCheck,
                              icon: _isRunningWriteCheck
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.science_outlined),
                              label: const Text('Run development write check'),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Creates one clearly named temporary private playlist. It never edits existing playlists.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  YouTubeContinueButton(
                    enabled:
                        _connection.canContinue && !_isNavigating && !isBusy,
                    onPressed: _continue,
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
