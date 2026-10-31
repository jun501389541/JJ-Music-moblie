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

const slow = QueueEntry(entryId: 'slow', trackKey: 'owned', fixtureId: 'slow');
const normal = QueueEntry(
  entryId: 'normal',
  trackKey: 'owned',
  fixtureId: 'normal',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final control in ['pause', 'stop', 'cancel', 'new-play']) {
    testWidgets('Windows actual pending stream read: $control', (tester) async {
      final asset = await rootBundle.load(
        'fixtures/local_playback/tone-long.wav',
      );
      final bytes = asset.buffer.asUint8List(
        asset.offsetInBytes,
        asset.lengthInBytes,
      );
      final token = await NativeLocalBackend.channel.invokeMethod<String>(
        'registerOwnedGate',
        {'bytes': bytes},
      );
      final dir = await Directory.systemTemp.createTemp('jj-owned-win-stream-');
      final file = File('${dir.path}/tone.wav');
      await file.writeAsBytes(bytes, flush: true);
      final backend = NativeLocalBackend({
        'slow': token!,
        'normal': file.uri.toString(),
      });
      final c = PlaybackCoordinator(backend);
      int? commitMs, drainedMs;
      Map<String, dynamic>? beforeControl;
      CommandContext cmd(String id) => CommandContext(id, c.claim);
      Map<String, dynamic> gate() => Map<String, dynamic>.from(
        ((backend.lastHost['streamGates'] as Map?)?['native-1'] as Map?) ?? {},
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
        expect(gate()['readers'], greaterThan(0));
        expect(gate()['bytesRead'], 0);
        final sample = (backend.lastHost['samples'] as List).single as Map;
        // Native WinRT enum verified against the installed SDK: Opening=1,
        // Buffering=2. Initial Opening is not yet a buffering-recovery proof.
        expect(sample['nativeState'], anyOf(1, 2));
        expect(sample['ready'], isFalse);
        expect(c.snapshot.confirmations, isEmpty);
        beforeControl = {...gate(), 'nativeState': sample['nativeState']};
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
        expect(commitMs, lessThan(500));
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
        drainedMs = timer.elapsedMilliseconds;
        if (control != 'pause') {
          expect(gate()['cancelled'], isTrue);
          expect(drainedMs, lessThan(2500));
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
        // ignore: avoid_print
        print(
          'WIN_LOADING_$control=${jsonEncode({'commitMs': commitMs, 'drainedMs': drainedMs, 'beforeControl': beforeControl, 'host': backend.lastHost, 'raw': backend.raw})}',
        );
      }
    });
  }
  testWidgets('Windows gated release completes without a Dart polling timer', (
    tester,
  ) async {
    final asset = await rootBundle.load(
      'fixtures/local_playback/tone-long.wav',
    );
    final token = await NativeLocalBackend.channel.invokeMethod<String>(
      'registerOwnedGate',
      {
        'bytes': asset.buffer.asUint8List(
          asset.offsetInBytes,
          asset.lengthInBytes,
        ),
      },
    );
    const id = 'direct-native-release';
    Map<String, dynamic> host = {};
    try {
      await NativeLocalBackend.channel.invokeMethod<void>('prepare', {
        'id': id,
        'path': token,
      });
      for (var i = 0; i < 60; i++) {
        host = Map<String, dynamic>.from(
          await NativeLocalBackend.channel.invokeMapMethod<String, dynamic>(
                'poll',
              ) ??
              {},
        );
        if ((host['streamGates'] as Map)[id]['blocked'] == true) break;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect((host['streamGates'] as Map)[id]['blocked'], isTrue);
      // There is no NativeLocalBackend and no further poll until release replies.
      final timer = Stopwatch()..start();
      await NativeLocalBackend.channel
          .invokeMethod<void>('release', {'id': id})
          .timeout(const Duration(seconds: 2));
      host = Map<String, dynamic>.from(
        await NativeLocalBackend.channel.invokeMapMethod<String, dynamic>(
              'poll',
            ) ??
            {},
      );
      expect((host['streamGates'] as Map)[id]['readers'], 0);
      expect((host['streamGates'] as Map)[id]['closed'], isTrue);
      expect(host['samples'], isEmpty);
      // ignore: avoid_print
      print(
        'WIN_LOADING_NO_POLL=${jsonEncode({'elapsedMs': timer.elapsedMilliseconds, 'host': host})}',
      );
    } finally {
      await NativeLocalBackend.channel.invokeMethod<void>('release', {
        'id': id,
      });
    }
  });
  testWidgets(
    'Windows close error cannot turn retry into false release success',
    (tester) async {
      final asset = await rootBundle.load(
        'fixtures/local_playback/tone-long.wav',
      );
      final token = await NativeLocalBackend.channel.invokeMethod<String>(
        'registerOwnedGate',
        {
          'bytes': asset.buffer.asUint8List(
            asset.offsetInBytes,
            asset.lengthInBytes,
          ),
        },
      );
      const id = 'close-error-native';
      try {
        await NativeLocalBackend.channel.invokeMethod<void>('prepare', {
          'id': id,
          'path': token,
        });
        await NativeLocalBackend.channel.invokeMethod<void>('failOwnedClose', {
          'id': id,
        });
        await expectLater(
          NativeLocalBackend.channel.invokeMethod<void>('release', {'id': id}),
          throwsA(isA<PlatformException>()),
        );
        final firstFailure = await NativeLocalBackend.channel
            .invokeMapMethod<String, dynamic>('poll');
        final partial = (firstFailure!['streamGates'] as Map)[id] as Map;
        expect(partial['sourceClosed'], isFalse);
        expect(
          partial['streamClosed'],
          isTrue,
          reason: 'Source failure must not skip the later stream cleanup',
        );
        // ignore: avoid_print
        print('WIN_LOADING_CLOSE_ERROR_FIRST=${jsonEncode(firstFailure)}');
        await NativeLocalBackend.channel
            .invokeMethod<void>('release', {'id': id})
            .timeout(const Duration(seconds: 2));
        final host = await NativeLocalBackend.channel
            .invokeMapMethod<String, dynamic>('poll');
        final closed = (host!['streamGates'] as Map)[id] as Map;
        expect(
          closed['sourceClosed'],
          isTrue,
          reason: 'A retry must actually finish the skipped source.Close',
        );
        expect(closed['streamClosed'], isTrue);
        expect(closed['closed'], isTrue);
        expect(closed['readers'], 0);
        // ignore: avoid_print
        print('WIN_LOADING_CLOSE_ERROR=${jsonEncode(host)}');
      } finally {
        await NativeLocalBackend.channel.invokeMethod<void>('release', {
          'id': id,
        });
      }
    },
  );
}
