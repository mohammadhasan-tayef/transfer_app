import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

class ExportifyCsvParser {
  const ExportifyCsvParser();

  static const _unsupportedCsvMessage =
      'This does not look like a supported Exportify CSV.';
  static const _noValidTracksMessage =
      'No valid tracks were found in this CSV.';

  static const _trackTitleHeaders = ['Track Name'];
  static const _artistHeaders = ['Artist Name(s)', 'Artist Names'];
  static const _durationHeaders = [
    'Track Duration (ms)',
    'Duration (ms)',
    'Duration_ms',
  ];
  static const _albumHeaders = ['Album Name'];
  static const _spotifyUriHeaders = ['Track URI'];
  static const _albumImageHeaders = ['Album Image URL'];
  static const _isrcHeaders = ['ISRC', 'Track ISRC'];
  static const _releaseDateHeaders = ['Album Release Date', 'Release Date'];
  static const _explicitHeaders = ['Explicit', 'Explicit?'];

  Playlist parse({required Uint8List bytes, required String fileName}) {
    final csvText = _decodeUtf8(bytes);
    final rows = csv.decode(csvText);

    if (rows.isEmpty) {
      throw const FormatException(_unsupportedCsvMessage);
    }

    final headerIndexes = _buildHeaderIndexes(rows.first);
    final titleIndex = _findColumn(headerIndexes, _trackTitleHeaders);
    final artistsIndex = _findColumn(headerIndexes, _artistHeaders);
    final durationIndex = _findColumn(headerIndexes, _durationHeaders);

    if (titleIndex == null || artistsIndex == null || durationIndex == null) {
      throw const FormatException(_unsupportedCsvMessage);
    }

    final tracks = <Track>[];
    for (final row in rows.skip(1)) {
      final track = _parseTrack(
        row: row,
        position: tracks.length,
        titleIndex: titleIndex,
        artistsIndex: artistsIndex,
        durationIndex: durationIndex,
        headerIndexes: headerIndexes,
      );
      if (track != null) {
        tracks.add(track);
      }
    }

    if (tracks.isEmpty) {
      throw const FormatException(_noValidTracksMessage);
    }

    return Playlist(
      name: _playlistNameFrom(fileName),
      sourceFileName: fileName,
      tracks: tracks,
    );
  }

  String _decodeUtf8(Uint8List bytes) {
    final decoded = utf8.decode(bytes);
    return decoded.startsWith('\uFEFF') ? decoded.substring(1) : decoded;
  }

  Map<String, int> _buildHeaderIndexes(List<dynamic> headerRow) {
    final indexes = <String, int>{};
    for (var index = 0; index < headerRow.length; index++) {
      indexes[_normalizeHeader(headerRow[index])] = index;
    }
    return indexes;
  }

  int? _findColumn(Map<String, int> indexes, List<String> aliases) {
    for (final alias in aliases) {
      final index = indexes[_normalizeHeader(alias)];
      if (index != null) {
        return index;
      }
    }
    return null;
  }

  Track? _parseTrack({
    required List<dynamic> row,
    required int position,
    required int titleIndex,
    required int artistsIndex,
    required int durationIndex,
    required Map<String, int> headerIndexes,
  }) {
    final title = _valueAt(row, titleIndex).trim();
    final originalArtists = _valueAt(row, artistsIndex);
    final durationMs = _durationAt(row, durationIndex);

    if (title.isEmpty || originalArtists.trim().isEmpty || durationMs == null) {
      return null;
    }

    return Track(
      position: position,
      title: title,
      artists: originalArtists,
      album: _optionalValue(row, headerIndexes, _albumHeaders),
      durationMs: durationMs,
      spotifyUri: _optionalValue(row, headerIndexes, _spotifyUriHeaders),
      albumImageUrl: _optionalValue(row, headerIndexes, _albumImageHeaders),
      isrc: _optionalValue(row, headerIndexes, _isrcHeaders),
      releaseDate: _optionalValue(row, headerIndexes, _releaseDateHeaders),
      explicit: _parseBoolean(
        _optionalValue(row, headerIndexes, _explicitHeaders),
      ),
    );
  }

  String _valueAt(List<dynamic> row, int index) {
    if (index >= row.length) {
      return '';
    }
    return row[index]?.toString() ?? '';
  }

  int? _durationAt(List<dynamic> row, int index) {
    if (index >= row.length) {
      return null;
    }

    final value = row[index];
    final duration = value is num
        ? value.toInt()
        : int.tryParse(value?.toString().trim() ?? '');
    return duration != null && duration >= 0 ? duration : null;
  }

  String? _optionalValue(
    List<dynamic> row,
    Map<String, int> indexes,
    List<String> aliases,
  ) {
    final index = _findColumn(indexes, aliases);
    if (index == null) {
      return null;
    }

    final value = _valueAt(row, index).trim();
    return value.isEmpty ? null : value;
  }

  bool? _parseBoolean(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'true':
      case 'yes':
      case '1':
        return true;
      case 'false':
      case 'no':
      case '0':
        return false;
      default:
        return null;
    }
  }

  String _normalizeHeader(Object? value) {
    return (value?.toString() ?? '')
        .replaceFirst('\uFEFF', '')
        .trim()
        .toLowerCase();
  }

  String _playlistNameFrom(String fileName) {
    final name = fileName.replaceFirst(
      RegExp(r'\.csv$', caseSensitive: false),
      '',
    );
    return name.isEmpty ? fileName : name;
  }
}
