import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/diagnostic_cleanup.dart';

void main() {
  test(
    'a throwing cleanup observer cannot replace the primary failure',
    () async {
      final primary = StateError('body failed');
      var observed = 0;
      await expectLater(
        DiagnosticCleanup.run<void>(
          (scope) async {
            scope.add(() async {
              throw ArgumentError('cleanup failed');
            });
            throw primary;
          },
          onSecondaryError: (_) {
            observed++;
            throw FormatException('observer failed');
          },
        ),
        throwsA(same(primary)),
      );
      expect(observed, 1);
    },
  );
  test(
    'multiple cleanup failures throw the first and report later failures',
    () async {
      final first = StateError('first');
      final later = ArgumentError('later');
      final reported = <Object>[];
      await expectLater(
        DiagnosticCleanup.run<void>((scope) async {
          scope.add(() async {
            throw later;
          });
          scope.add(() async {
            throw first;
          });
        }, onSecondaryError: reported.add),
        throwsA(same(first)),
      );
      expect(reported, [same(later)]);
    },
  );
  test(
    'setup failure removes an already-created temporary directory',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'jj-cleanup-test-',
      );
      final failure = StateError('setup failed');
      await expectLater(
        DiagnosticCleanup.run<void>((scope) async {
          scope.add(() => directory.delete(recursive: true));
          throw failure;
        }),
        throwsA(same(failure)),
      );
      expect(directory.existsSync(), isFalse);
    },
  );
  test(
    'partial initialization unwinds all acquired resources in reverse order',
    () async {
      final closed = <String>[];
      await expectLater(
        DiagnosticCleanup.run<void>((scope) async {
          scope.add(() async {
            closed.add('screen');
          });
          scope.add(() async {
            closed.add('input');
          });
          scope.add(() async {
            closed.add('backend');
          });
          throw StateError('prepare failed');
        }),
        throwsStateError,
      );
      expect(closed, ['backend', 'input', 'screen']);
    },
  );
  test(
    'one failing release cannot skip remaining releases or temp cleanup',
    () async {
      final closed = <String>[];
      final error = StateError('release failed');
      await expectLater(
        DiagnosticCleanup.run<void>((scope) async {
          scope.add(() async {
            closed.add('directory');
          });
          scope.add(() async {
            closed.add('a');
          });
          scope.add(() async {
            closed.add('b');
            throw error;
          });
          scope.add(() async {
            closed.add('c');
          });
        }),
        throwsA(same(error)),
      );
      expect(closed, ['c', 'b', 'a', 'directory']);
    },
  );
  test(
    'cleanup failures preserve the primary failure and report secondary types',
    () async {
      final primary = StateError('body failed');
      final secondary = <Object>[];
      await expectLater(
        DiagnosticCleanup.run<void>((scope) async {
          scope.add(() async {
            throw ArgumentError('release failed');
          });
          throw primary;
        }, onSecondaryError: secondary.add),
        throwsA(same(primary)),
      );
      expect(secondary.single, isA<ArgumentError>());
    },
  );
  test(
    'scope waits for asynchronous cleanup before returning its result',
    () async {
      final permit = Completer<void>();
      var returned = false;
      final pending =
          DiagnosticCleanup.run<int>((scope) async {
            scope.add(() => permit.future);
            return 7;
          }).then((value) {
            returned = true;
            return value;
          });
      await Future<void>.delayed(Duration.zero);
      expect(returned, isFalse);
      permit.complete();
      expect(await pending, 7);
    },
  );
}
