import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'runtime_destroy_failure_test.dart' show ReleaseFailureHost;
import 'runtime_handoff_busy_test.dart' show Gate;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('close observes owned failure even while mirror remains blocked', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final host = ReleaseFailureHost();
    messenger.setMockMethodCallHandler(NativeLocalBackend.channel, host.call);
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(NativeLocalBackend.channel, null),
    );
    final run = 'close-observe-$pid-${DateTime.now().microsecondsSinceEpoch}';
    final r = await LocalRuntime.create(runId: run);
    var zoneOwnsClose = false;
    addTearDown(() async {
      host.failuresRemaining = 0;
      host.releaseGate?.open();
      host.mirror?.open();
      await r.backend.destroyNativeResources();
      if (!zoneOwnsClose) await r.close().catchError((Object _) {});
      final dir = r.store.directory;
      if (!dir.absolute.path.endsWith('${Platform.pathSeparator}$run')) {
        throw StateError('Unsafe cleanup');
      }
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final ready = Completer<void>();
    void observe() {
      if (r.snapshot.confirmations.length == 1 && !ready.isCompleted) {
        ready.complete();
      }
    }

    r.addListener(observe);
    r.command('a');
    await ready.future.timeout(const Duration(seconds: 5));
    r.removeListener(observe);
    final mirror = host.mirror = Gate();
    await mirror.entered.future.timeout(const Duration(seconds: 3));
    final release = host.releaseGate = Gate();
    final unhandled = <Object>[];
    final done = Completer<void>();
    Object? original, closeError;
    // Run all failing Futures in one error zone; only the success receipt
    // crosses back to the test zone. An unhandled error must not hang the test.
    runZonedGuarded(
      () async {
        try {
          final destroying = r.destroyBackend();
          await release.entered.future;
          zoneOwnsClose = true;
          final closing = r.close();
          release.open();
          await Future<void>.delayed(Duration.zero);
          final operationResult = destroying.then<Object?>(
            (_) => null,
            onError: (Object e) => e,
          );
          final closeResult = closing.then<Object?>(
            (_) => null,
            onError: (Object e) => e,
          );
          mirror.open();
          original = await operationResult;
          closeError = await closeResult;
          done.complete();
        } catch (e, s) {
          done.completeError(e, s);
        }
      },
      (error, stack) {
        unhandled.add(error);
      },
    );
    await done.future.timeout(const Duration(seconds: 5));
    expect(original, isA<PlatformException>());
    expect(identical(original, closeError), isTrue);
    expect(
      unhandled,
      isEmpty,
      reason: 'close took ownership before failure and must observe promptly',
    );
    expect(r.backend.consumers, 0);
  });
}
