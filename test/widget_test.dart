import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/app.dart';
import 'package:transfer_aplicationn/core/theme/app_theme.dart';
import 'package:transfer_aplicationn/features/playlist_import/application/use_cases/import_playlists.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/playlist.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/playlist_import_result.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/track.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/repositories/playlist_import_repository.dart';
import 'package:transfer_aplicationn/features/playlist_import/presentation/screens/playlist_import_screen.dart';

void main() {
  testWidgets('shows the playlist import screen', (tester) async {
    await tester.pumpWidget(const MusicTransferApp());

    expect(find.text('Move your music'), findsOneWidget);
    expect(find.text('Import your playlists'), findsOneWidget);
    expect(find.text('0 playlists'), findsOneWidget);
    expect(find.text('No playlists imported yet'), findsOneWidget);
  });

  testWidgets('fits a small mobile viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MusicTransferApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('opens the Exportify URL from the helper action', (tester) async {
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PlaylistImportScreen(
          importPlaylists: const ImportPlaylists(
            _FakePlaylistImportRepository(PlaylistImportResult.empty()),
          ),
          launchExportify: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );

    await _tapExportifyAction(tester);

    expect(openedUri?.scheme, 'https');
    expect(openedUri?.host, 'exportify.net');
    expect(openedUri?.path, '/');
    expect(
      find.text('Could not open Exportify. Please try again.'),
      findsNothing,
    );
  });

  testWidgets('shows an error when Exportify cannot be opened', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PlaylistImportScreen(
          importPlaylists: const ImportPlaylists(
            _FakePlaylistImportRepository(PlaylistImportResult.empty()),
          ),
          launchExportify: (_) async => false,
        ),
      ),
    );

    await _tapExportifyAction(tester);

    expect(
      find.text('Could not open Exportify. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error when opening Exportify throws', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PlaylistImportScreen(
          importPlaylists: const ImportPlaylists(
            _FakePlaylistImportRepository(PlaylistImportResult.empty()),
          ),
          launchExportify: (_) =>
              Future<bool>.error(Exception('launch failed')),
        ),
      ),
    );

    await _tapExportifyAction(tester);

    expect(
      find.text('Could not open Exportify. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('imports a playlist, updates totals, and continues', (
    tester,
  ) async {
    final playlist = Playlist(
      name: 'Gym',
      sourceFileName: 'Gym.csv',
      tracks: [
        Track(position: 0, title: 'First', artists: 'Artist', durationMs: 1000),
        Track(
          position: 1,
          title: 'Second',
          artists: 'Artist',
          durationMs: 2000,
        ),
      ],
    );
    final repository = _FakePlaylistImportRepository(
      PlaylistImportResult(playlists: [playlist]),
    );
    final importPlaylists = ImportPlaylists(repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PlaylistImportScreen(importPlaylists: importPlaylists),
      ),
    );

    await tester.tap(find.text('Import your playlists'));
    await tester.pump();

    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('1 playlist'), findsOneWidget);
    expect(find.text('2 tracks'), findsOneWidget);
    expect(find.text('Continue with 2 tracks'), findsOneWidget);

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue with 2 tracks'),
    );
    expect(continueButton.onPressed, isNotNull);
    continueButton.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Connect YouTube Music'), findsOneWidget);
  });

  testWidgets('does not add an imported source file twice', (tester) async {
    final playlist = Playlist(
      name: 'Gym',
      sourceFileName: 'Gym.csv',
      tracks: [
        Track(position: 0, title: 'Song', artists: 'Artist', durationMs: 1000),
      ],
    );
    final repository = _FakePlaylistImportRepository(
      PlaylistImportResult(playlists: [playlist]),
    );
    final importPlaylists = ImportPlaylists(repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PlaylistImportScreen(importPlaylists: importPlaylists),
      ),
    );

    await tester.tap(find.text('Import your playlists'));
    await tester.pump();
    await tester.tap(find.text('Import your playlists'));
    await tester.pump();

    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('1 playlist'), findsOneWidget);
    expect(find.text('Gym.csv has already been imported.'), findsOneWidget);
  });
}

Future<void> _tapExportifyAction(WidgetTester tester) async {
  final action = find.text("Don't have CSV files? Get them from Exportify");
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump();
}

class _FakePlaylistImportRepository implements PlaylistImportRepository {
  const _FakePlaylistImportRepository(this.result);

  final PlaylistImportResult result;

  @override
  Future<PlaylistImportResult> importPlaylists() async => result;
}
