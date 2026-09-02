import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/features/playlist_import/application/use_cases/import_playlists.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/playlist.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/playlist_import_result.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/track.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/repositories/playlist_import_repository.dart';

void main() {
  group('ImportPlaylists', () {
    test('returns newly imported playlists', () async {
      final gymPlaylist = _playlist('Gym.csv');
      final repository = _StubPlaylistImportRepository(
        PlaylistImportResult(playlists: [gymPlaylist]),
      );

      final importResult = await ImportPlaylists(repository)();

      expect(importResult.playlists, [gymPlaylist]);
      expect(importResult.failures, isEmpty);
    });

    test(
      'excludes a previously imported source file case-insensitively',
      () async {
        final repository = _StubPlaylistImportRepository(
          PlaylistImportResult(playlists: [_playlist('Gym.csv')]),
        );

        final importResult = await ImportPlaylists(repository)(
          importedSourceFileNames: const ['GYM.CSV'],
        );

        expect(importResult.playlists, isEmpty);
        expect(importResult.failures, hasLength(1));
        expect(importResult.failures.single.fileName, 'Gym.csv');
        expect(
          importResult.failures.single.message,
          'Gym.csv has already been imported.',
        );
      },
    );

    test(
      'excludes duplicate files returned in the same import batch',
      () async {
        final repository = _StubPlaylistImportRepository(
          PlaylistImportResult(
            playlists: [_playlist('Drive.csv'), _playlist('drive.csv')],
          ),
        );

        final importResult = await ImportPlaylists(repository)();

        expect(importResult.playlists, hasLength(1));
        expect(importResult.failures, hasLength(1));
        expect(
          importResult.failures.single.message,
          'drive.csv has already been imported.',
        );
      },
    );

    test('preserves failures returned by the repository', () async {
      const repositoryFailure = PlaylistImportFailure(
        fileName: 'Broken.csv',
        message: 'Broken.csv: Unsupported format.',
      );
      final repository = _StubPlaylistImportRepository(
        PlaylistImportResult(failures: const [repositoryFailure]),
      );

      final importResult = await ImportPlaylists(repository)();

      expect(importResult.failures, [repositoryFailure]);
    });
  });
}

Playlist _playlist(String sourceFileName) {
  return Playlist(
    name: sourceFileName.replaceFirst('.csv', ''),
    sourceFileName: sourceFileName,
    tracks: const [
      Track(position: 0, title: 'Song', artists: 'Artist', durationMs: 1000),
    ],
  );
}

class _StubPlaylistImportRepository implements PlaylistImportRepository {
  const _StubPlaylistImportRepository(this.importResult);

  final PlaylistImportResult importResult;

  @override
  Future<PlaylistImportResult> importPlaylists() async => importResult;
}
