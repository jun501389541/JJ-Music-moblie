import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'local_playback_contract.dart';

void registerNativeFailureCases() {
  testWidgets('native preconfirmation play failure resumes old real track', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('jj-owned-rollback-');
    final file = File('${dir.path}/long.wav');
    final data = await rootBundle.load('fixtures/local_playback/tone-long.wav');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    final b = NativeLocalBackend({'tone-a': file.uri.toString()});
    final c = PlaybackCoordinator(b);
    Future<void> until(bool Function() check) async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!check() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(check(), isTrue);
    }

    try {
      c.play(
        CommandContext('a', c.claim),
        PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureA.entryId),
      );
      await until(() => c.snapshot.currentEntryId == fixtureA.entryId);
      final old = c.snapshot.tracks.single.trackHandleId;
      final oldPosition = c.snapshot.positionMs;
      await NativeLocalBackend.channel.invokeMethod<void>('failNextPlay');
      c.play(
        CommandContext('b', c.claim),
        PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureB.entryId),
      );
      await until(() => c.failures.isNotEmpty && b.consumers == 1);
      await until(
        () => (b.lastHost['samples'] as List? ?? []).any(
          (s) =>
              s['id'] == old &&
              s['nativePlaying'] == true &&
              (s['position'] as int) > oldPosition + 200,
        ),
      );
      expectConfirmedIdentity(c.snapshot, fixtureA.entryId, 1);
      c.stop(CommandContext('stop', c.claim));
      await until(() => b.consumers == 0);
    } finally {
      await c.dispose();
      await b.close();
      // ignore: avoid_print
      print('NATIVE_ROLLBACK_${Platform.operatingSystem}=${jsonEncode(b.raw)}');
    }
  });
  testWidgets(
    'native file URI natural end and malformed owned file never confirms',
    (tester) async {
      final root = await Directory.systemTemp.createTemp('jj-owned-cases-');
      final short = File('${root.path}/short.wav');
      final data = await rootBundle.load('fixtures/local_playback/tone-a.wav');
      await short.writeAsBytes(data.buffer.asUint8List(), flush: true);
      final bad = File('${root.path}/bad.wav');
      await bad.writeAsBytes([1, 2, 3, 4], flush: true);
      final backend = NativeLocalBackend({
        'short': short.uri.toString(),
        'bad': bad.uri.toString(),
      });
      final c = PlaybackCoordinator(backend);
      Future<void> until(bool Function() check) async {
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!check() && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(check(), isTrue);
      }

      try {
        await until(() => backend.lastHost.isNotEmpty);
        final serviceStopsBefore = Platform.isAndroid
            ? (backend.lastHost['lifecycle'] as List)
                  .where((v) => v['event'] == 'service-destroy')
                  .length
            : 0;
        const item = QueueEntry(
          entryId: 'short-owned',
          trackKey: 'short',
          fixtureId: 'short',
        );
        expectControlApplied(
          c.play(
            CommandContext('short', c.claim),
            PlayIntent(entries: [item], entryId: item.entryId),
          ),
        );
        await until(() => c.snapshot.confirmations.length == 1);
        await until(() => backend.consumers == 0);
        if (Platform.isAndroid) {
          await until(
            () =>
                (backend.lastHost['lifecycle'] as List? ?? [])
                    .where((v) => v['event'] == 'service-destroy')
                    .length >
                serviceStopsBefore,
          );
        }
        expect(c.snapshot.desired, DesiredTransport.paused);
        const broken = QueueEntry(
          entryId: 'bad-owned',
          trackKey: 'bad',
          fixtureId: 'bad',
        );
        c.play(
          CommandContext('bad', c.claim),
          PlayIntent(entries: [broken], entryId: broken.entryId),
        );
        await until(() => c.failures.isNotEmpty && backend.consumers == 0);
        expect(c.snapshot.confirmations.length, 1);
      } finally {
        await c.dispose();
        await backend.close();
        // ignore: avoid_print
        print(
          'NATIVE_FAILURE_CASES_${Platform.operatingSystem}=${jsonEncode(backend.raw)}',
        );
      }
    },
  );
}
