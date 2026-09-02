import 'track.dart';

class Playlist {
  Playlist({
    required this.name,
    required this.sourceFileName,
    required List<Track> tracks,
  }) : tracks = List.unmodifiable(tracks);

  final String name;
  final String sourceFileName;
  final List<Track> tracks;

  int get trackCount => tracks.length;

  List<String> get coverImageUrls {
    return tracks
        .map((track) => track.albumImageUrl)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(4)
        .toList();
  }
}
