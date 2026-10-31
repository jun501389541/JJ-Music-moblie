import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('A01/A02 native shell startup control and real-file diagnostics', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('JJ-Music 技术诊断'), findsOneWidget);
    await tester.tap(find.text('运行入口检查'));
    await tester.pumpAndSettle();
    expect(find.textContaining('入口检查通过'), findsOneWidget);
    Future<void> check(String button, String expected) async {
      await tester.tap(find.text(button));
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.textContaining(expected).evaluate().isNotEmpty) {
          return;
        }
      }
      expect(find.textContaining(expected), findsOneWidget);
    }

    await check('运行共享合同自检', '共享合同检查通过');
    await check('保存并读回测试快照', '快照写读检查通过');
    final frame = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('diagnostic-frame')),
    );
    await tester.runAsync(() async {
      final image = await frame.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      // Each verification gets a new output; historical evidence is immutable.
      final path = '${Directory.systemTemp.path}/jj-diagnostic-smoke-$pid.png';
      await File(path).writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      image.dispose();
      // Path contains only this diagnostic app's own cache location.
      // ignore: avoid_print
      print('DIAGNOSTIC_SCREENSHOT=$path');
    });
  });
}
