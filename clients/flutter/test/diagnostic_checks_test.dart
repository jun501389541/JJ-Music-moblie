import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/app/diagnostic_checks.dart';

void main() {
  test(
    'manual control diagnostic verifies dispatch and late consumer cleanup',
    () async {
      final result = await DiagnosticChecks.control();
      expect(result.passed, isTrue);
    },
  );
  test(
    'manual recovery diagnostic actually writes then reads through a new store',
    () async {
      final result = await DiagnosticChecks.recovery();
      expect(result.passed, isTrue);
    },
  );
}
