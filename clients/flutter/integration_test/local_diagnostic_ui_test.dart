import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/main.dart' as app;
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'actual diagnostic buttons and route reconstruction retain playback',
    (tester) async {
      if (Platform.isAndroid) {
        final awake = await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticScreen',
          {'keepOn': true},
        );
        if (awake != true) {
          await NativeLocalBackend.channel.invokeMethod<void>(
            'diagnosticScreen',
            {'keepOn': false},
          );
          fail(
            'Android UI verification requires user-unlocked interactive screen; not a background test',
          );
        }
      }
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开自有样本播放诊断'));
      await tester.pump(const Duration(milliseconds: 400));
      final r = await LocalRuntime.instance();
      final initial = r.snapshot.confirmations.length;
      try {
        await tester.pump();
        await tester.tap(find.text('播放样本A'));
        await until(
          () =>
              r.snapshot.currentEntryId == ownedA.entryId &&
              r.snapshot.confirmations.length == initial + 1,
        );
        await tester.pump();
        await tester.tap(find.text('暂停'));
        await tester.pump();
        expect(r.snapshot.desired, DesiredTransport.paused);
        await tester.tap(find.text('定位3秒'));
        await tester.pump();
        await until(() => r.snapshot.positionMs >= 2900);
        await tester.tap(find.text('继续'));
        await tester.pump();
        await tester.tap(find.text('切换样本B'));
        await tester.pump();
        await until(() => r.snapshot.currentEntryId == ownedB.entryId);
        await until(() => r.backend.consumers == 1);
        final handle = r.snapshot.tracks
            .where((t) => t.role == TrackRole.active)
            .single
            .trackHandleId;
        await tester.tap(find.text('UI重新连接'));
        await tester.pump();
        await tester.tap(find.text('重建组件'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          r.snapshot.tracks
              .where((t) => t.role == TrackRole.active)
              .single
              .trackHandleId,
          handle,
        );
        expect(r.snapshot.confirmations.length, initial + 2);
        await tester.tap(find.text('暂停'));
        await tester.pump();
        final saved = r.savedRevision;
        await tester.tap(find.text('保存恢复快照'));
        await until(() => r.savedRevision > saved);
        await tester.pump();
        await tester.tap(find.text('停止'));
        await tester.pump();
        await until(() => r.backend.consumers == 0);
        // ignore: avoid_print
        print(
          'DIAGNOSTIC_UI_${Platform.operatingSystem}: buttons, real route replacement, saved revision ${r.savedRevision}, consumers0',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await r.close();
        if (Platform.isAndroid) {
          await NativeLocalBackend.channel.invokeMethod<void>(
            'diagnosticScreen',
            {'keepOn': false},
          );
        }
      }
    },
  );
}
