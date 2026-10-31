import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/local_playback_contract.dart';
import 'support/native_failure_cases.dart';
import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerNativeFailureCases();
  testWidgets('Android Media3 content URI transport, denial and release', (
    tester,
  ) async {
    final uri = await NativeLocalBackend.channel.invokeMethod<String>(
      'fixtureUri',
    );
    final backend = NativeLocalBackend({
      'tone-a': uri!,
    }, logFile: File('${Directory.systemTemp.path}/android-raw.jsonl'));
    final c = PlaybackCoordinator(backend);
    CommandContext cmd(String id) => CommandContext(id, c.claim);
    PlayIntent intent(QueueEntry e) =>
        PlayIntent(entries: [fixtureA, fixtureB], entryId: e.entryId);
    try {
      expectControlApplied(c.play(cmd('a'), intent(fixtureA)));
      await until(() => c.snapshot.currentEntryId == fixtureA.entryId);
      expectConfirmedIdentity(c.snapshot, fixtureA.entryId, 1);
      await until(() => c.snapshot.positionMs > 400);
      c.pause(cmd('pause'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final paused = c.snapshot.positionMs;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect((c.snapshot.positionMs - paused).abs(), lessThan(150));
      c.seek(cmd('seek'), 3000);
      await until(() => c.snapshot.positionMs >= 2900);
      c.resume(cmd('resume'));
      await until(() => c.snapshot.positionMs > 3400);
      expect(c.snapshot.confirmations.length, 1);
      c.play(cmd('b'), intent(fixtureB));
      c.stop(cmd('cancel'));
      await until(() => backend.consumers == 0);
      c.play(cmd('c'), intent(fixtureB));
      await until(() => c.snapshot.currentEntryId == fixtureB.entryId);
      expectConfirmedIdentity(c.snapshot, fixtureB.entryId, 2);
      c.stop(cmd('stop'));
      await until(() => backend.consumers == 0);
      await NativeLocalBackend.channel.invokeMethod<void>('revokeFixture', {
        'revoked': true,
      });
      c.play(cmd('denied'), intent(fixtureA));
      await until(() => c.failures.isNotEmpty);
      expect(c.snapshot.confirmations.length, 2);
      await until(() => backend.consumers == 0);
    } finally {
      await NativeLocalBackend.channel.invokeMethod<void>('revokeFixture', {
        'revoked': false,
      });
      await c.dispose();
      await backend.close();
      // Only owned fixture native samples; no device/library data.
      // ignore: avoid_print
      print('ANDROID_RAW_LOG=${backend.logFile!.path}');
      // ignore: avoid_print
      print('ANDROID_RAW_JSON=${jsonEncode(backend.raw)}');
    }
  });
}
