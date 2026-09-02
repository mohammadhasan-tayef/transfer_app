import '../../domain/models/playlist.dart';
import '../../domain/models/playlist_import_result.dart';
import '../../domain/repositories/playlist_import_repository.dart';

class ImportPlaylists {
  const ImportPlaylists(this._repository);

  final PlaylistImportRepository _repository;

  /// Imports playlists and excludes source files imported previously or twice.
  Future<PlaylistImportResult> call({
    Iterable<String> importedSourceFileNames = const [],
  }) async {
    final repositoryResult = await _repository.importPlaylists();
    if (repositoryResult.playlists.isEmpty) {
      return repositoryResult;
    }

    final knownSourceFileNames = importedSourceFileNames
        .map(_normalizeSourceFileName)
        .toSet();
    final uniquePlaylists = <Playlist>[];
    final failures = <PlaylistImportFailure>[...repositoryResult.failures];

    for (final playlist in repositoryResult.playlists) {
      final normalizedFileName = _normalizeSourceFileName(
        playlist.sourceFileName,
      );
      final isDuplicate = !knownSourceFileNames.add(normalizedFileName);

      if (isDuplicate) {
        failures.add(
          PlaylistImportFailure(
            fileName: playlist.sourceFileName,
            message: '${playlist.sourceFileName} has already been imported.',
          ),
        );
        continue;
      }

      uniquePlaylists.add(playlist);
    }

    return PlaylistImportResult(playlists: uniquePlaylists, failures: failures);
  }

  String _normalizeSourceFileName(String fileName) {
    return fileName.trim().toLowerCase();
  }
}
