import 'package:file_picker/file_picker.dart';

import '../../domain/models/playlist.dart';
import '../../domain/models/playlist_import_result.dart';
import '../../domain/repositories/playlist_import_repository.dart';
import '../parsers/exportify_csv_parser.dart';

class FilePickerPlaylistImportRepository implements PlaylistImportRepository {
  const FilePickerPlaylistImportRepository([
    this._parser = const ExportifyCsvParser(),
  ]);

  static const _allowedExtensions = ['csv'];
  static const _unreadableFileMessage = 'The selected file could not be read.';
  static const _unexpectedImportMessage = 'This file could not be imported.';

  final ExportifyCsvParser _parser;

  @override
  Future<PlaylistImportResult> importPlaylists() async {
    final selectedFiles = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
      withData: true,
    );

    if (selectedFiles == null) {
      return const PlaylistImportResult.empty();
    }

    final importedPlaylists = <Playlist>[];
    final importFailures = <PlaylistImportFailure>[];

    for (final selectedFile in selectedFiles.files) {
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
          _parser.parse(bytes: fileBytes, fileName: selectedFile.name),
        );
      } on FormatException catch (formatException) {
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
