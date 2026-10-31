import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';

import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('owned sample progresses while actual screen is off', (
    tester,
  ) async {
    final r = await LocalRuntime.create(runId: 'screen-off-$pid');
    try {
      r.command('a');
      await until(() => r.snapshot.currentEntryId == ownedA.entryId);
      final before = r.snapshot.positionMs;
      // Host controller must actually issue sleep/wake and save display evidence.
      // ignore: avoid_print
      print('READY_FOR_SCREEN_OFF');
      var observedOff = false;
      for (var i = 0; i < 16; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (r.backend.lastHost['screenInteractive'] == false) {
          observedOff = true;
        }
      }
      expect(
        observedOff,
        isTrue,
        reason: 'Host must prove actual display-off; timer progress alone is insufficient',
      );
      expect(r.snapshot.positionMs, greaterThan(before + 4000));
      expect(r.snapshot.confirmations.length, 1);
      r.command('stop');
      await until(() => r.backend.consumers == 0);
    } finally {
      // ignore: avoid_print
      print('SCREEN_OFF_NATIVE=${jsonEncode(r.backend.lastHost)}');
      await r.close();
    }
  });
}
