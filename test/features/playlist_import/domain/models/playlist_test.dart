import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/playlist.dart';
import 'package:transfer_aplicationn/features/playlist_import/domain/models/track.dart';

void main() {
  test('protects its track collection from external mutation', () {
    const track = Track(
      position: 0,
      title: 'Song',
      artists: 'Artist',
      durationMs: 1000,
    );
    final sourceTracks = <Track>[track];
    final playlist = Playlist(
      name: 'Gym',
      sourceFileName: 'Gym.csv',
      tracks: sourceTracks,
    );

    sourceTracks.clear();

    expect(playlist.trackCount, 1);
    expect(() => playlist.tracks.add(track), throwsUnsupportedError);
  });
}
