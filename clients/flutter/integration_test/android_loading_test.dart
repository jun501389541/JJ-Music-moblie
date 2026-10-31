import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/local_playback_contract.dart' show expectControlApplied;
import 'windows_local_playback_test.dart' show until;

const slow = QueueEntry(entryId: 'slow', trackKey: 'owned', fixtureId: 'slow');
const normal = QueueEntry(
  entryId: 'normal',
  trackKey: 'owned',
  fixtureId: 'normal',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final control in ['pause', 'stop', 'cancel', 'new-play']) {
    testWidgets('Android actual pending local read: $control', (tester) async {
      final uri = await NativeLocalBackend.channel.invokeMethod<String>(
        'gatedFixtureUri',
      );
      final normalUri = await NativeLocalBackend.channel.invokeMethod<String>(
        'fixtureUri',
      );
      final backend = NativeLocalBackend({'slow': uri!, 'normal': normalUri!});
      final c = PlaybackCoordinator(backend);
      int? commitMs, readerClosedMs;
      Map<String, dynamic>? beforeControl;
      CommandContext cmd(String id) => CommandContext(id, c.claim);
      Map<String, dynamic> gate() => Map<String, dynamic>.from(
        ((backend.lastHost['readGates'] as Map?)?['native-1'] as Map?) ?? {},
      );
      try {
        expectControlApplied(
          c.play(
            cmd('old'),
            PlayIntent(entries: [slow, normal], entryId: slow.entryId),
          ),
        );
        await until(() => gate()['blocked'] == true);
        await Future<void>.delayed(const Duration(milliseconds: 650));
        expect(gate()['readers'], 1);
        expect(gate()['bytesRead'], 0);
        expect((backend.lastHost['samples'] as List).single['state'], 2);
        expect(c.snapshot.confirmations, isEmpty);
        beforeControl = gate();
        final timer = Stopwatch()..start();
        final ack = switch (control) {
          'pause' => c.pause(cmd('control')),
          'stop' => c.stop(cmd('control')),
          'cancel' => c.cancel(cmd('control'), 'old'),
          _ => c.play(
            cmd('control'),
            PlayIntent(entries: [slow, normal], entryId: normal.entryId),
          ),
        };
        expectControlApplied(ack);
        commitMs = timer.elapsedMilliseconds;
        expect(
          timer.elapsedMilliseconds,
          lessThan(500),
          reason: 'Command must not wait for the blocked read',
        );
        if (control == 'pause') {
          expect(gate()['blocked'], isTrue);
          await NativeLocalBackend.channel.invokeMethod<void>(
            'allowOwnedRead',
            {'id': 'native-1'},
          );
          await until(
            () => (backend.lastHost['samples'] as List).any(
              (s) => s['ready'] == true,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          expect(c.snapshot.desired, DesiredTransport.paused);
          expect(c.snapshot.confirmations, isEmpty);
          expect(
            (backend.lastHost['samples'] as List).single['nativePlaying'],
            isFalse,
          );
          expectControlApplied(c.resume(cmd('resume')));
          await until(() => c.snapshot.currentEntryId == slow.entryId);
          expect(c.snapshot.confirmations.length, 1);
          c.pause(cmd('pause-again'));
          c.resume(cmd('resume-again'));
          await until(() => c.snapshot.positionMs > 350);
          expect(c.snapshot.confirmations.length, 1);
          c.stop(cmd('finish'));
        } else if (control == 'new-play') {
          await until(() => c.snapshot.currentEntryId == normal.entryId);
          expect(c.snapshot.confirmations.length, 1);
        }
        await until(() => gate()['readers'] == 0 && gate()['closed'] == true);
        readerClosedMs = timer.elapsedMilliseconds;
        if (control != 'pause') {
          expect(gate()['cancelled'], isTrue);
          expect(
            timer.elapsedMilliseconds,
            lessThan(2500),
            reason: 'Physical cancel/next must not wait for gate timeout',
          );
          await NativeLocalBackend.channel.invokeMethod<void>(
            'allowOwnedRead',
            {'id': 'native-1'},
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(
            c.snapshot.confirmations.length,
            control == 'new-play' ? 1 : 0,
          );
        }
        c.stop(cmd('cleanup'));
        await until(() => backend.consumers == 0);
        expect(c.failures, isEmpty);
      } finally {
        await c.dispose();
        await backend.close();
        // Only self-owned local fixture state, never private library data.
        // ignore: avoid_print
        print(
          'LOADING_$control=${jsonEncode({'commitMs': commitMs, 'readerClosedMs': readerClosedMs, 'beforeControl': beforeControl, 'host': backend.lastHost, 'raw': backend.raw})}',
        );
      }
    });
  }
}
