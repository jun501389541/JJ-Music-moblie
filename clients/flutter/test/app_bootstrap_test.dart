import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/main.dart';

void main() {
  testWidgets(
    'diagnostic shell identifies itself and never claims audio playback',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('JJ-Music 技术诊断'), findsOneWidget);
      expect(find.textContaining('不播放音频'), findsOneWidget);
      expect(find.text('运行入口检查'), findsOneWidget);
      await tester.tap(find.text('运行入口检查'));
      await tester.pump();
      expect(find.textContaining('入口检查通过'), findsOneWidget);
    },
  );
}
