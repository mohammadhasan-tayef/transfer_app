import '../models/playlist_import_result.dart';

abstract interface class PlaylistImportRepository {
  /// Imports selected playlist files without applying presentation concerns.
  Future<PlaylistImportResult> importPlaylists();
}
