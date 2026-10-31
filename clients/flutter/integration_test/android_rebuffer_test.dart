import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/local_playback_contract.dart' show expectControlApplied;
import 'windows_local_playback_test.dart' show until;

const a = QueueEntry(
  entryId: 'rebuffer-a',
  trackKey: 'owned',
  fixtureId: 'gated',
);
const b = QueueEntry(
  entryId: 'normal-b',
  trackKey: 'owned',
  fixtureId: 'normal',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await NativeLocalBackend.channel.invokeMethod<bool>('diagnosticScreen', {
      'keepOn': true,
    });
  });
  tearDownAll(() async {
    await NativeLocalBackend.channel.invokeMethod<bool>('diagnosticScreen', {
      'keepOn': false,
    });
  });
  for (final control in ['recover', 'pause', 'stop', 'new-play']) {
    testWidgets('Android confirmed playback then actual rebuffer: $control', (
      tester,
    ) async {
      // Produce the first real frame before asking whether this Activity owns
      // window focus; setUpAll can still be behind Android's launch window.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('自有样本再缓冲自动验证'))),
      );
      await tester.pumpAndSettle();
      var foreground = false;
      for (var i = 0; i < 20; i++) {
        foreground =
            await NativeLocalBackend.channel.invokeMethod<bool>(
              'diagnosticForeground',
            ) ??
            false;
        if (foreground) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(
        foreground,
        isTrue,
        reason: 'Unlock selected phone and keep diagnostic Activity visible; background FGS starts are separate',
      );
      final uri = await NativeLocalBackend.channel.invokeMethod<String>(
        'rebufferFixtureUri',
      );
      final normalUri = await NativeLocalBackend.channel.invokeMethod<String>(
        'fixtureUri',
      );
      final backend = NativeLocalBackend({'gated': uri!, 'normal': normalUri!});
      final c = PlaybackCoordinator(backend);
      CommandContext cmd(String id) => CommandContext(id, c.claim);
      final transitions = backend.events.listen((event) {
        if (event.kind == BackendEventKind.playing &&
            c.snapshot.currentEntryId == b.entryId) {
          c.completeTransition(
            event.trackHandleId,
            transitionId: event.transitionId,
          );
        }
      });
      Map<String, dynamic> gate() => Map<String, dynamic>.from(
        ((backend.lastHost['readGates'] as Map?)?['native-1'] as Map?) ?? {},
      );
      Map<String, dynamic>? beforeControl;
      List<String>? firstConfirmation;
      int? controlMs, settledMs;
      try {
        expectControlApplied(
          c.play(cmd('a'), PlayIntent(entries: [a, b], entryId: a.entryId)),
        );
        await until(() => c.snapshot.currentEntryId == a.entryId);
        await until(() => c.snapshot.positionMs > 300);
        firstConfirmation = c.snapshot.confirmations;
        expect(firstConfirmation, hasLength(1));
        await until(
          () =>
              gate()['blocked'] == true &&
              (backend.lastHost['samples'] as List).any(
                (s) => s['id'] == 'native-1' && s['state'] == 2,
              ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final buffered = (backend.lastHost['samples'] as List).single as Map;
        expect(buffered['state'], 2);
        expect(buffered['nativePlaying'], isFalse);
        expect(buffered['position'], greaterThan(300));
        expect(gate()['bytesRead'], greaterThan(0));
        expect(gate()['furthestPosition'], lessThanOrEqualTo(64044));
        expect(c.snapshot.confirmations, firstConfirmation);
        beforeControl = {'gate': gate(), 'sample': buffered};
        final timer = Stopwatch()..start();
        if (control == 'pause') {
          expectControlApplied(c.pause(cmd('pause')));
        } else if (control == 'stop') {
          expectControlApplied(c.stop(cmd('stop')));
        } else if (control == 'new-play') {
          expectControlApplied(
            c.play(cmd('b'), PlayIntent(entries: [a, b], entryId: b.entryId)),
          );
        }
        controlMs = timer.elapsedMilliseconds;
        expect(controlMs, lessThan(500));
        if (control == 'recover' || control == 'pause') {
          final pausedAt = c.snapshot.positionMs;
          await NativeLocalBackend.channel.invokeMethod<void>(
            'allowOwnedRead',
            {'id': 'native-1'},
          );
          if (control == 'pause') {
            await until(
              () => (backend.lastHost['samples'] as List).any(
                (s) => s['state'] == 3,
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 500));
            expect(c.snapshot.desired, DesiredTransport.paused);
            expect((c.snapshot.positionMs - pausedAt).abs(), lessThan(150));
            expect(
              (backend.lastHost['samples'] as List).single['nativePlaying'],
              isFalse,
            );
            expect(c.snapshot.confirmations, firstConfirmation);
            expectControlApplied(c.resume(cmd('resume')));
          }
          await until(() => c.snapshot.positionMs > pausedAt + 400);
          expect(c.snapshot.currentEntryId, a.entryId);
          expect(c.snapshot.tracks.single.trackHandleId, 'native-1');
          expect(c.snapshot.confirmations, firstConfirmation);
          settledMs = timer.elapsedMilliseconds;
          c.stop(cmd('finish'));
        } else {
          if (control == 'new-play') {
            await until(() => c.snapshot.currentEntryId == b.entryId);
            expect(c.snapshot.confirmations.length, 2);
          }
          await until(() => gate()['readers'] == 0 && gate()['closed'] == true);
          settledMs = timer.elapsedMilliseconds;
          expect(settledMs, lessThan(2500));
          expect(gate()['cancelled'], isTrue);
          await NativeLocalBackend.channel.invokeMethod<void>(
            'allowOwnedRead',
            {'id': 'native-1'},
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(
            c.snapshot.confirmations.length,
            control == 'new-play' ? 2 : 1,
          );
          c.stop(cmd('cleanup'));
        }
        await until(() => backend.consumers == 0);
        expect(c.failures, isEmpty);
      } finally {
        await transitions.cancel();
        await c.dispose();
        await backend.close();
        // ignore: avoid_print
        print(
          'REBUFFER_$control=${jsonEncode({'controlMs': controlMs, 'settledMs': settledMs, 'confirmation': firstConfirmation, 'beforeControl': beforeControl, 'failures': c.failures.map((f) => '${f.code}:${f.stage}').toList(), 'host': backend.lastHost, 'raw': backend.raw})}',
        );
      }
    });
  }
}
