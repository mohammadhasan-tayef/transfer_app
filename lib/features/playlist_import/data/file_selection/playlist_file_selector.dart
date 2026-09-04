import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class SelectedPlaylistFile {
  const SelectedPlaylistFile({required this.name, required this.bytes});

  final String name;
  final Uint8List? bytes;
}

abstract interface class PlaylistFileSelector {
  Future<List<SelectedPlaylistFile>?> selectCsvFiles();
}

class PlatformPlaylistFileSelector implements PlaylistFileSelector {
  const PlatformPlaylistFileSelector();

  static const _allowedExtensions = ['csv'];

  @override
  Future<List<SelectedPlaylistFile>?> selectCsvFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) {
      return null;
    }

    return [
      for (final file in result.files)
        SelectedPlaylistFile(name: file.name, bytes: file.bytes),
    ];
  }
}
