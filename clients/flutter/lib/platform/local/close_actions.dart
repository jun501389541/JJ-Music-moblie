import 'dart:async';

/// Ordered best-effort teardown. Failures do not prevent later independent steps.
/// A never-completing action still remains pending; this is not a timeout policy.
class CloseActions {
  final _failures = <(Object, StackTrace)>[];
  List<Object> get failures => List.unmodifiable(_failures.map((f) => f.$1));
  Future<void> run(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      _failures.add((error, stack));
    }
  }

  void throwIfFailed() {
    if (_failures.isNotEmpty) {
      Error.throwWithStackTrace(_failures.first.$1, _failures.first.$2);
    }
  }
}
