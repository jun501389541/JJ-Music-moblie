import 'dart:convert';
import 'dart:io';

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
  for (final control in ['recover', 'pause', 'stop', 'new-play']) {
    testWidgets('Windows actual post-start rebuffer: $control', (tester) async {
      final data = await rootBundle.load(
        'fixtures/local_playback/tone-long.wav',
      );
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final token = await NativeLocalBackend.channel.invokeMethod<String>(
        'registerOwnedPcm',
        {'bytes': bytes},
      );
      final dir = await Directory.systemTemp.createTemp('jj-owned-pcm-');
      final file = await File('${dir.path}/tone.wav').writeAsBytes(bytes);
      final backend = NativeLocalBackend({
        'a': token!,
        'b': file.uri.toString(),
      });
      final c = PlaybackCoordinator(backend);
      const a = QueueEntry(entryId: 'a', trackKey: 'owned', fixtureId: 'a');
      const b = QueueEntry(entryId: 'b', trackKey: 'owned', fixtureId: 'b');
      CommandContext cmd(String id) => CommandContext(id, c.claim);
      Map gate() =>
          (backend.lastHost['streamGates'] as Map?)?['native-1'] as Map? ?? {};
      Map sample() => (backend.lastHost['samples'] as List).firstWhere(
        (s) => s['id'] == 'native-1',
        orElse: () => <String, dynamic>{},
      ) as Map;
      final subscription = backend.events.listen((event) {
        if (event.kind == BackendEventKind.playing &&
            c.snapshot.currentEntryId == 'b') {
          c.completeTransition(
            event.trackHandleId,
            transitionId: event.transitionId,
          );
        }
      });
      Map? before;
      int? commitMs;
      try {
        expectControlApplied(
          c.play(cmd('first'), PlayIntent(entries: [a, b], entryId: 'a')),
        );
        await until(
          () => c.snapshot.currentEntryId == 'a' && c.snapshot.positionMs > 300,
        );
        expect(c.snapshot.confirmations.length, 1);
        await until(
          () => gate()['blocked'] == true && sample()['nativeState'] == 2,
        );
        expect(sample()['position'], greaterThan(300));
        expect(sample()['nativePlaying'], isFalse);
        before = {
          'sample': {...sample()},
          'gate': {...gate()},
        };
        final position = sample()['position'] as int;
        final timer = Stopwatch()..start();
        if (control == 'pause') {
          expectControlApplied(c.pause(cmd('pause')));
        } else if (control == 'stop') {
          expectControlApplied(c.stop(cmd('stop')));
        } else if (control == 'new-play') {
          expectControlApplied(
            c.play(cmd('new'), PlayIntent(entries: [a, b], entryId: 'b')),
          );
        }
        commitMs = timer.elapsedMilliseconds;
        expect(commitMs, lessThan(500));
        if (control == 'recover' || control == 'pause') {
          await NativeLocalBackend.channel.invokeMethod<void>(
            'allowOwnedRead',
            {'id': 'native-1'},
          );
          if (control == 'pause') {
            await until(() => gate()['readers'] == 0);
            await Future<void>.delayed(const Duration(milliseconds: 450));
            expect(c.snapshot.desired, DesiredTransport.paused);
            expect(sample()['nativePlaying'], isFalse);
            final paused = sample()['position'] as int;
            await Future<void>.delayed(const Duration(milliseconds: 350));
            expect((sample()['position'] as int) - paused, lessThan(100));
            expectControlApplied(c.resume(cmd('resume')));
          }
          await until(
            () =>
                sample()['nativePlaying'] == true &&
                (sample()['position'] as int) > position + 350,
          );
          expect(c.snapshot.currentEntryId, 'a');
          expect(c.snapshot.confirmations.length, 1);
          c.stop(cmd('finish'));
        } else if (control == 'new-play') {
          await until(() => c.snapshot.currentEntryId == 'b');
          expect(c.snapshot.confirmations.length, 2);
        }
        await until(() => gate()['closed'] == true && gate()['readers'] == 0);
        expect(gate()['cancelled'], isTrue);
        await NativeLocalBackend.channel.invokeMethod<void>('allowOwnedRead', {
          'id': 'native-1',
        });
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(c.snapshot.confirmations.length, control == 'new-play' ? 2 : 1);
        c.stop(cmd('cleanup'));
        await until(() => backend.consumers == 0);
        expect(c.failures, isEmpty);
      } finally {
        await subscription.cancel();
        await c.dispose();
        await backend.close();
        // ignore: avoid_print
        print(
          'WIN_REBUFFER_$control=${jsonEncode({'before': before, 'commitMs': commitMs, 'host': backend.lastHost, 'raw': backend.raw})}',
        );
        await dir.delete(recursive: true);
      }
    });
  }
}
