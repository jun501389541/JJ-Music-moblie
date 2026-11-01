/// Test-only resource lifetime. Register ownership before the next fallible step.
class DiagnosticCleanup {
  DiagnosticCleanup._();
  final _actions = <Future<void> Function()>[];
  bool _closing = false;

  void add(Future<void> Function() action) {
    if (_closing) throw StateError('diagnostic scope already closing');
    _actions.add(action);
  }

  static Future<T> run<T>(
    Future<T> Function(DiagnosticCleanup scope) body, {
    void Function(Object error)? onSecondaryError,
  }) async {
    final scope = DiagnosticCleanup._();
    var primaryFailed = false;
    try {
      return await body(scope);
    } catch (_) {
      primaryFailed = true;
      rethrow;
    } finally {
      scope._closing = true;
      final failures = <(Object, StackTrace)>[];
      for (final action in scope._actions.reversed) {
        try {
          await action();
        } catch (error, trace) {
          failures.add((error, trace));
        }
      }
      scope._actions.clear();
      for (final failure in failures.skip(primaryFailed ? 0 : 1)) {
        // Neither a logger failure nor cleanup may hide the original failure.
        try {
          if (onSecondaryError != null) {
            onSecondaryError(failure.$1);
          } else {
            // ignore: avoid_print
            print('DIAGNOSTIC_CLEANUP_SECONDARY=${failure.$1.runtimeType}');
          }
        } catch (_) {}
      }
      if (!primaryFailed && failures.isNotEmpty) {
        Error.throwWithStackTrace(failures.first.$1, failures.first.$2);
      }
    }
  }
}
