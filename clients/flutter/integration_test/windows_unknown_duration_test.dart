import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/local_playback_contract.dart' show expectControlApplied;
import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final unknown in [true, false]) {
    testWidgets('Windows actual unseekable PCM, unknown duration=$unknown', (
      tester,
    ) async {
      final data = await rootBundle.load(
        'fixtures/local_playback/tone-long.wav',
      );
      final token = await NativeLocalBackend.channel.invokeMethod<String>(
        'registerOwnedPcm',
        {
          'bytes': data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          ),
          'unknownDuration': unknown,
        },
      );
      final backend = NativeLocalBackend({'pcm': token!});
      final c = PlaybackCoordinator(backend);
      const entry = QueueEntry(
        entryId: 'pcm',
        trackKey: 'owned',
        fixtureId: 'pcm',
      );
      CommandContext cmd(String id) => CommandContext(id, c.claim);
      Map sample() => (backend.lastHost['samples'] as List).single as Map;
      Map? advancing, afterSeek;
      try {
        expectControlApplied(
          c.play(cmd('play'), PlayIntent(entries: [entry], entryId: 'pcm')),
        );
        await until(
          () =>
              c.snapshot.confirmations.length == 1 &&
              c.snapshot.positionMs > 300,
        );
        advancing = {...sample()};
        final prior = c.snapshot;
        final rejected = c.seek(cmd('unsupported-shared'), 9000);
        expect(rejected.applied, isFalse);
        expect(c.snapshot.playbackGeneration, prior.playbackGeneration);
        expect(c.snapshot.positionMs, prior.positionMs);
        expect(sample()['canSeek'], isFalse);
        expect(sample()['duration'], unknown ? 0 : 12000);
        // Unsupported native capability is tested directly, without pretending
        // the current shared command acknowledgement advertises seekability.
        await expectLater(
          NativeLocalBackend.channel.invokeMethod<void>('seek', {
            'id': 'native-1',
            'position': 9000,
          }),
          throwsA(isA<PlatformException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));
        afterSeek = {...sample()};
        expect(sample()['position'], lessThan(3000));
        expectControlApplied(c.pause(cmd('pause')));
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(sample()['nativePlaying'], isFalse);
        expectControlApplied(c.resume(cmd('resume')));
        await NativeLocalBackend.channel.invokeMethod<void>('allowOwnedRead', {
          'id': 'native-1',
        });
        await until(
          () =>
              sample()['nativePlaying'] == true && c.snapshot.positionMs > 1100,
        );
        expect(c.snapshot.confirmations.length, 1);
        if (unknown) {
          // Actual end-of-input at twelve seconds; duration stays unspecified
          // at startup, rather than being a fabricated empty/failed track.
          await until(
            () => backend.raw.any((s) => s['ended'] == true),
            seconds: 16,
          );
        }
        c.stop(cmd('stop'));
        await until(() => backend.consumers == 0);
        // Native release receipt is independent of the next polling snapshot.
        // Wait for that snapshot rather than asserting stale pre-close evidence.
        await until(
          () =>
              ((backend.lastHost['streamGates'] as Map)['native-1']
                  as Map)['closed'] ==
              true,
        );
        expect(c.snapshot.confirmations.length, 1);
        expect(c.failures, isEmpty);
        final gate =
            (backend.lastHost['streamGates'] as Map)['native-1'] as Map;
        expect(gate['readers'], 0);
        expect(gate['closed'], isTrue);
      } finally {
        await c.dispose();
        await backend.close();
        // ignore: avoid_print
        print(
          'WIN_UNKNOWN_$unknown=${jsonEncode({'advancing': advancing, 'afterSeek': afterSeek, 'host': backend.lastHost, 'raw': backend.raw})}',
        );
      }
    });
  }
}
