class Track {
  const Track({
    required this.position,
    required this.title,
    required this.artists,
    required this.durationMs,
    this.album,
    this.spotifyUri,
    this.albumImageUrl,
    this.isrc,
    this.releaseDate,
    this.explicit,
  });

  final int position;
  final String title;

  /// Original artist text from Exportify, intentionally not normalized.
  final String artists;

  final String? album;
  final int durationMs;
  final String? spotifyUri;
  final String? albumImageUrl;
  final String? isrc;
  final String? releaseDate;
  final bool? explicit;
}
