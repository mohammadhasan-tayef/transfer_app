import 'playlist.dart';

class PlaylistImportResult {
  PlaylistImportResult({
    List<Playlist> playlists = const [],
    List<PlaylistImportFailure> failures = const [],
  }) : playlists = List.unmodifiable(playlists),
       failures = List.unmodifiable(failures);

  const PlaylistImportResult.empty()
    : playlists = const [],
      failures = const [];

  final List<Playlist> playlists;
  final List<PlaylistImportFailure> failures;
}

class PlaylistImportFailure {
  const PlaylistImportFailure({required this.fileName, required this.message});

  final String fileName;
  final String message;
}
