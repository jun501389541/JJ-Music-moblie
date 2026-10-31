import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/platform/local/native_evidence.dart';

void main() {
  Map<String, dynamic> sample(
    String platform,
    int position, {
    int state = 3,
    bool ready = true,
    bool playing = true,
    int suppression = 0,
  }) => {
    'platform': platform,
    'state': state,
    'ready': ready,
    'nativePlaying': playing,
    'suppression': suppression,
    'position': position,
    'playWhenReady': playing,
  };
  test(
    'native confirmation requires observed running and advancing samples',
    () {
      for (final platform in ['windows', 'android']) {
        final e = NativeEvidence();
        expect(e.observe(sample(platform, 0), intended: true), isFalse);
        expect(e.observe(sample(platform, 150), intended: true), isTrue);
      }
    },
  );
  test('ready/intent/buffering/paused/seek jumps cannot alone confirm', () {
    for (final platform in ['windows', 'android']) {
      final e = NativeEvidence();
      e.observe(sample(platform, 0), intended: true);
      expect(
        e.observe(sample(platform, 100, state: 2), intended: true),
        isFalse,
      );
      expect(e.observe(sample(platform, 200), intended: false), isFalse);
      expect(
        e.observe(sample(platform, 300, playing: false), intended: true),
        isFalse,
      );
      expect(
        e.observe(sample(platform, 400, suppression: 1), intended: true),
        isFalse,
      );
      e.reset();
      expect(e.observe(sample(platform, 5000), intended: true), isFalse);
      expect(e.observe(sample(platform, 5000), intended: true), isFalse);
      expect(e.observe(sample(platform, 5100), intended: true), isTrue);
    }
  });
}
