import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Windows OS SMTC pause/play/seek/next route to shared authority',
    (tester) async {
      final r = await LocalRuntime.create(runId: 'smtc-$pid');
      Future<void> os(String action) async {
        final exe = File(Platform.resolvedExecutable);
        final probe = File(
          '${exe.parent.path}/../../diagnostic_tools/Debug/jj_smtc_probe.exe',
        );
        final result = await Process.run(probe.absolute.path, ['$pid', action]);
        // ignore: avoid_print
        print('SMTC_OS_$action=${result.stdout}');
        expect(result.exitCode, 0);
      }

      try {
        r.command('a');
        await until(() => r.snapshot.currentEntryId == ownedA.entryId);
        await until(
          () =>
              r.backend.lastHost['mirroredStatus'] == 'playing' &&
              r.backend.lastHost['mirroredDuration'] == 12000,
        );
        await os('pause');
        await until(() => r.snapshot.desired == DesiredTransport.paused);
        await until(() => r.backend.lastHost['mirroredStatus'] == 'paused');
        expect(r.snapshot.confirmations.length, 1);
        await os('play');
        await until(() => r.snapshot.desired == DesiredTransport.playing);
        await until(() => r.backend.lastHost['mirroredStatus'] == 'playing');
        await os('seek');
        await until(() => r.snapshot.positionMs >= 2900);
        await os('next');
        await until(() => r.snapshot.currentEntryId == ownedB.entryId);
        await until(() => r.backend.consumers == 1);
        expect(r.snapshot.confirmations.length, 2);
        r.command('stop');
        await until(() => r.backend.consumers == 0);
      } finally {
        // ignore: avoid_print
        print('SMTC_NATIVE_JSON=${jsonEncode(r.backend.lastHost)}');
        await r.close();
      }
    },
  );
}
