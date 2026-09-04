import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/features/playlist_import/data/file_selection/playlist_file_selector.dart';
import 'package:transfer_aplicationn/features/playlist_import/data/repositories/file_picker_playlist_import_repository.dart';

void main() {
  test('returns an empty result when file selection is cancelled', () async {
    final repository = FilePickerPlaylistImportRepository(
      fileSelector: const _FakePlaylistFileSelector(null),
    );

    final result = await repository.importPlaylists();

    expect(result.playlists, isEmpty);
    expect(result.failures, isEmpty);
  });

  test('imports valid files and returns safe per-file failures', () async {
    final repository = FilePickerPlaylistImportRepository(
      fileSelector: _FakePlaylistFileSelector([
        SelectedPlaylistFile(
          name: 'Valid.csv',
          bytes: Uint8List.fromList(
            utf8.encode(
              'Track Name,Artist Name(s),Track Duration (ms)\n'
              'Song,Artist,1000',
            ),
          ),
        ),
        const SelectedPlaylistFile(name: 'Unreadable.csv', bytes: null),
        SelectedPlaylistFile(
          name: 'Malformed.csv',
          bytes: Uint8List.fromList([0xC3, 0x28]),
        ),
      ]),
    );

    final result = await repository.importPlaylists();

    expect(result.playlists.single.name, 'Valid');
    expect(result.failures, hasLength(2));
    expect(
      result.failures.map((failure) => failure.message),
      containsAll([
        'Unreadable.csv: The selected file could not be read.',
        'Malformed.csv: This does not look like a supported Exportify CSV.',
      ]),
    );
  });
}

class _FakePlaylistFileSelector implements PlaylistFileSelector {
  const _FakePlaylistFileSelector(this.files);

  final List<SelectedPlaylistFile>? files;

  @override
  Future<List<SelectedPlaylistFile>?> selectCsvFiles() async => files;
}
