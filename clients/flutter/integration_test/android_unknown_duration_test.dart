import 'dart:convert';

import 'package:flutter/material.dart';
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
  for (final mode in ['unknown-natural', 'unknown-stop', 'known']) {
    final unknown = mode != 'known';
    testWidgets('Android real unknown PCM versus known WAV: $mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('自有顺序PCM验证'))),
      );
      await tester.pumpAndSettle();
      await NativeLocalBackend.channel.invokeMethod<bool>('diagnosticScreen', {
        'keepOn': true,
      });
      NativeLocalBackend? backend;
      PlaybackCoordinator? coordinator;
      Map? advancing, afterSeek;
      try {
        var foreground = false;
        for (var i = 0; i < 30; i++) {
          foreground =
              await NativeLocalBackend.channel.invokeMethod<bool>(
                'diagnosticForeground',
              ) ??
              false;
          if (foreground) break;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        expect(
          foreground,
          isTrue,
          reason: 'Unlock selected phone; do not bypass keyguard',
        );
        final uri = await NativeLocalBackend.channel.invokeMethod<String>(
          unknown ? 'unknownPcmFixtureUri' : 'fixtureUri',
        );
        final host = NativeLocalBackend({'owned': uri!});
        backend = host;
        final c = PlaybackCoordinator(host);
        coordinator = c;
        const entry = QueueEntry(
          entryId: 'owned',
          trackKey: 'owned',
          fixtureId: 'owned',
        );
        CommandContext cmd(String id) => CommandContext(id, c.claim);
        Map sample() => (host.lastHost['samples'] as List).single as Map;
        expectControlApplied(
          c.play(cmd('play'), PlayIntent(entries: [entry], entryId: 'owned')),
        );
        await until(
          () =>
              c.snapshot.confirmations.length == 1 &&
              c.snapshot.positionMs > 300,
        );
        advancing = {...sample()};
        if (unknown) {
          final prior = c.snapshot;
          final ack = c.seek(cmd('unsupported-shared'), 9000);
          expect(ack.applied, isFalse);
          expect(ack.failure?.code, 'seek-unsupported');
          expect(c.snapshot.positionMs, prior.positionMs);
          expect(c.snapshot.playbackGeneration, prior.playbackGeneration);
        }
        expect(sample()['canSeek'], !unknown);
        expect(sample()['duration'], unknown ? 0 : 12000);
        if (unknown) {
          expect(sample()['nativeDuration'], -9223372036854775807);
          await expectLater(
            NativeLocalBackend.channel.invokeMethod<void>('seek', {
              'id': 'native-1',
              'position': 9000,
            }),
            throwsA(
              isA<PlatformException>()
                  .having((e) => e.code, 'code', 'android-local')
                  .having(
                    (e) => e.message,
                    'message',
                    'UnsupportedOperationException',
                  ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 200));
          afterSeek = {...sample()};
          expect(sample()['position'], lessThan(3000));
        } else {
          expectControlApplied(c.seek(cmd('seek'), 3000));
          await until(() => c.snapshot.positionMs >= 2900);
        }
        expectControlApplied(c.pause(cmd('pause')));
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(sample()['nativePlaying'], isFalse);
        expectControlApplied(c.resume(cmd('resume')));
        if (unknown && mode != 'unknown-stop') {
          await NativeLocalBackend.channel.invokeMethod<void>(
            'allowOwnedRead',
            {'id': 'native-1'},
          );
        }
        await until(() => sample()['nativePlaying'] == true);
        expect(c.snapshot.confirmations.length, 1);
        if (mode == 'unknown-natural') {
          await until(
            () => host.raw.any((s) => s['ended'] == true),
            seconds: 16,
          );
        }
        if (mode == 'unknown-stop') {
          await until(
            () =>
                ((host.lastHost['readGates'] as Map)['native-1']
                    as Map)['blocked'] ==
                true,
          );
        }
        final stopTimer = Stopwatch()..start();
        expectControlApplied(c.stop(cmd('stop')));
        expect(stopTimer.elapsedMilliseconds, lessThan(500));
        await until(() => host.consumers == 0);
        if (unknown) {
          await until(
            () =>
                ((host.lastHost['pcmStreams'] as Map)['native-1']
                    as Map)['active'] ==
                0,
          );
          final stream =
              (host.lastHost['pcmStreams'] as Map)['native-1'] as Map;
          expect(stream['opens'], stream['closes']);
          expect(stream['bytesRead'], mode == 'unknown-stop' ? 64000 : 384000);
          expect(stream['closeErrors'], 0);
          await until(
            () =>
                ((host.lastHost['readGates'] as Map)['native-1']
                    as Map)['closed'] ==
                true,
          );
          expect(
            ((host.lastHost['readGates'] as Map)['native-1'] as Map)['readers'],
            0,
          );
        }
        expect(c.snapshot.confirmations.length, 1);
        expect(c.failures, isEmpty);
      } finally {
        await coordinator?.dispose();
        await backend?.close();
        await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticScreen',
          {'keepOn': false},
        );
        // ignore: avoid_print
        print(
          'ANDROID_UNKNOWN_$mode=${jsonEncode({'advancing': advancing, 'afterSeek': afterSeek, 'host': backend?.lastHost, 'raw': backend?.raw})}',
        );
      }
    });
  }
}
