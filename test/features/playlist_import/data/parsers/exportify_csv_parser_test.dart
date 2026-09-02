import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/features/playlist_import/data/parsers/exportify_csv_parser.dart';

void main() {
  const parser = ExportifyCsvParser();

  Uint8List csvBytes(String value) {
    return Uint8List.fromList(utf8.encode(value));
  }

  group('ExportifyCsvParser', () {
    test('parses a valid CSV with supported optional columns', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          'Track Name,Artist Name(s),Album Name,Track Duration (ms),'
          'Track URI,Album Image URL,ISRC,Album Release Date,Explicit\n'
          'First Song,Artist A,First Album,123000,spotify:track:1,'
          'https://example.com/cover.jpg,ABC123,2024-01-01,true',
        ),
        fileName: 'Favorites.csv',
      );

      expect(playlist.name, 'Favorites');
      expect(playlist.sourceFileName, 'Favorites.csv');
      expect(playlist.trackCount, 1);
      expect(playlist.tracks.single.position, 0);
      expect(playlist.tracks.single.title, 'First Song');
      expect(playlist.tracks.single.album, 'First Album');
      expect(playlist.tracks.single.durationMs, 123000);
      expect(playlist.tracks.single.spotifyUri, 'spotify:track:1');
      expect(playlist.tracks.single.albumImageUrl, isNotEmpty);
      expect(playlist.tracks.single.isrc, 'ABC123');
      expect(playlist.tracks.single.releaseDate, '2024-01-01');
      expect(playlist.tracks.single.explicit, isTrue);
    });

    test('throws when a required column is missing', () {
      expect(
        () => parser.parse(
          bytes: csvBytes('Track Name,Artist Name(s)\nSong,Artist'),
          fileName: 'Invalid.csv',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'This does not look like a supported Exportify CSV.',
          ),
        ),
      );
    });

    test('throws for an empty CSV', () {
      expect(
        () => parser.parse(bytes: csvBytes(''), fileName: 'Empty.csv'),
        throwsFormatException,
      );
    });

    test('allows optional columns to be missing and supports aliases', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          'Track Name,Artist Names,Duration_ms\nSong,Artist,95000',
        ),
        fileName: 'Minimal.csv',
      );

      final track = playlist.tracks.single;
      expect(track.album, isNull);
      expect(track.spotifyUri, isNull);
      expect(track.albumImageUrl, isNull);
      expect(track.isrc, isNull);
      expect(track.releaseDate, isNull);
      expect(track.explicit, isNull);
    });

    test('parses all supported explicit boolean values', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          'Track Name,Artist Name(s),Duration (ms),Explicit?\n'
          'A,Artist,1,true\n'
          'B,Artist,1,false\n'
          'C,Artist,1,yes\n'
          'D,Artist,1,no\n'
          'E,Artist,1,1\n'
          'F,Artist,1,0\n'
          'G,Artist,1,unknown',
        ),
        fileName: 'Explicit.csv',
      );

      expect(playlist.tracks.map((track) => track.explicit), [
        true,
        false,
        true,
        false,
        true,
        false,
        null,
      ]);
    });

    test('removes the CSV extension case-insensitively', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          'Track Name,Artist Name(s),Track Duration (ms)\nSong,Artist,1',
        ),
        fileName: 'Old Persian.CSV',
      );

      expect(playlist.name, 'Old Persian');
      expect(playlist.sourceFileName, 'Old Persian.CSV');
    });

    test('preserves the original multiple-artists string', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          'Track Name,Artist Name(s),Track Duration (ms)\n'
          'Song,"Artist A, Artist B",1',
        ),
        fileName: 'Artists.csv',
      );

      expect(playlist.tracks.single.artists, 'Artist A, Artist B');
    });

    test('keeps a comma inside a quoted track title', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          'Track Name,Artist Name(s),Track Duration (ms)\n'
          '"Song, Part II",Artist,1000',
        ),
        fileName: 'Quoted.csv',
      );

      expect(playlist.trackCount, 1);
      expect(playlist.tracks.single.title, 'Song, Part II');
    });

    test('removes a UTF-8 BOM and positions only valid tracks', () {
      final playlist = parser.parse(
        bytes: csvBytes(
          '\uFEFFTrack Name,Artist Name(s),Track Duration (ms)\n'
          ',Missing title,1\n'
          'First,Artist,1000\n'
          'Missing artist,,1000\n'
          'Second,Artist,2000',
        ),
        fileName: 'Ordered.csv',
      );

      expect(playlist.tracks.map((track) => track.position), [0, 1]);
      expect(playlist.tracks.map((track) => track.title), ['First', 'Second']);
    });
  });
}
