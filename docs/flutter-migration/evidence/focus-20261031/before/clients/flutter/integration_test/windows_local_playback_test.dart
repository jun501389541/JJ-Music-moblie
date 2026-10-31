import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/local_playback_contract.dart';
import 'support/native_failure_cases.dart';

Future<void> until(bool Function() check, {int seconds = 10}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!check() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(check(), isTrue, reason: 'native condition timed out');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerNativeFailureCases();
  testWidgets(
    'Windows native local transport uses shared identities and releases',
    (tester) async {
      final dir = await Directory.systemTemp.createTemp('jj-owned-playback-');
      final file = File('${dir.path}/tone-long.wav');
      final bytes = await rootBundle.load(
        'fixtures/local_playback/tone-long.wav',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      final backend = NativeLocalBackend(
        {'tone-a': file.uri.toString()},
        logFile: File(
          'E:/Workspace/project/JJ-Music-mobile/docs/flutter-migration/evidence/p1-a/20261031/windows-raw.jsonl',
        ),
      );
      final coordinator = PlaybackCoordinator(backend);
      CommandContext cmd(String id) => CommandContext(id, coordinator.claim);
      try {
        expectControlApplied(
          coordinator.play(
            cmd('a'),
            PlayIntent(
              entries: [fixtureA, fixtureB],
              entryId: fixtureA.entryId,
            ),
          ),
        );
        await until(
          () => coordinator.snapshot.currentEntryId == fixtureA.entryId,
        );
        expectConfirmedIdentity(coordinator.snapshot, fixtureA.entryId, 1);
        await until(() => coordinator.snapshot.positionMs > 400);
        expectControlApplied(coordinator.pause(cmd('pause')));
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final paused = coordinator.snapshot.positionMs;
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect((coordinator.snapshot.positionMs - paused).abs(), lessThan(150));
        expectControlApplied(coordinator.seek(cmd('seek'), 3000));
        await until(() => coordinator.snapshot.positionMs >= 2900);
        expectControlApplied(coordinator.resume(cmd('resume')));
        await until(() => coordinator.snapshot.positionMs > 3400);
        expect(coordinator.snapshot.confirmations.length, 1);
        // Old load invalidated by stop without awaiting prepare; physical close observed.
        coordinator.play(
          cmd('b'),
          PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureB.entryId),
        );
        coordinator.stop(cmd('stop-immediate'));
        await until(() => backend.consumers == 0);
        coordinator.play(
          cmd('c'),
          PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureB.entryId),
        );
        await until(
          () => coordinator.snapshot.currentEntryId == fixtureB.entryId,
        );
        expectConfirmedIdentity(coordinator.snapshot, fixtureB.entryId, 2);
        coordinator.stop(cmd('stop'));
        await until(() => backend.consumers == 0);
        expect(
          coordinator.snapshot.tracks.every(
            (t) => t.role == TrackRole.released,
          ),
          isTrue,
        );
        // On Windows this additionally proves no retained file read handle.
        await file.rename('${dir.path}/released.wav');
      } finally {
        await coordinator.dispose();
        await backend.close();
      }
    },
  );
}
