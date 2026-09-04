import '../file_selection/playlist_file_selector.dart';

import '../../domain/models/playlist.dart';
import '../../domain/models/playlist_import_result.dart';
import '../../domain/repositories/playlist_import_repository.dart';
import '../parsers/exportify_csv_parser.dart';

class FilePickerPlaylistImportRepository implements PlaylistImportRepository {
  const FilePickerPlaylistImportRepository({
    this.fileSelector = const PlatformPlaylistFileSelector(),
    this.parser = const ExportifyCsvParser(),
  });

  static const _unreadableFileMessage = 'The selected file could not be read.';
  static const _unexpectedImportMessage = 'This file could not be imported.';

  final PlaylistFileSelector fileSelector;
  final ExportifyCsvParser parser;

  @override
  Future<PlaylistImportResult> importPlaylists() async {
    final selectedFiles = await fileSelector.selectCsvFiles();

    if (selectedFiles == null) {
      return const PlaylistImportResult.empty();
    }

    final importedPlaylists = <Playlist>[];
    final importFailures = <PlaylistImportFailure>[];

    for (final selectedFile in selectedFiles) {
      final fileBytes = selectedFile.bytes;
      if (fileBytes == null) {
        importFailures.add(
          PlaylistImportFailure(
            fileName: selectedFile.name,
            message: '${selectedFile.name}: $_unreadableFileMessage',
          ),
        );
        continue;
      }

      try {
        importedPlaylists.add(
          parser.parse(bytes: fileBytes, fileName: selectedFile.name),
        );
      } on ExportifyCsvFormatException catch (formatException) {
        importFailures.add(
          PlaylistImportFailure(
            fileName: selectedFile.name,
            message:
                '${selectedFile.name}: ${formatException.message.toString()}',
          ),
        );
      } catch (_) {
        importFailures.add(
          PlaylistImportFailure(
            fileName: selectedFile.name,
            message: '${selectedFile.name}: $_unexpectedImportMessage',
          ),
        );
      }
    }

    return PlaylistImportResult(
      playlists: importedPlaylists,
      failures: importFailures,
    );
  }
}
