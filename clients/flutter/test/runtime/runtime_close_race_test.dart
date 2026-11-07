import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/recovery_snapshot.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'runtime_destroy_failure_test.dart' show ReleaseFailureHost;
import 'runtime_handoff_busy_test.dart' show Gate;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ReleaseFailureHost host;
  late LocalRuntime r;
  setUp(() async {
    host = ReleaseFailureHost()..failuresRemaining = 0;
    messenger.setMockMethodCallHandler(NativeLocalBackend.channel, host.call);
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(NativeLocalBackend.channel, null),
    );
    final run = 'close-race-$pid-${DateTime.now().microsecondsSinceEpoch}';
    r = await LocalRuntime.create(runId: run);
    addTearDown(() async {
      host.failuresRemaining = 0;
      host.releaseGate?.open();
      await r.backend.destroyNativeResources();
      // The body observes expected operation/close errors before teardown.
      await r.close().catchError((Object _) {});
      final dir = r.store.directory;
      if (!dir.absolute.path.endsWith('${Platform.pathSeparator}$run')) {
        throw StateError('Unsafe cleanup');
      }
      if (await dir.exists()) await dir.delete(recursive: true);
    });
  });
  Future<void> active() async {
    final ready = Completer<void>();
    void observe() {
      if (r.snapshot.confirmations.length == 1 && !ready.isCompleted) {
        ready.complete();
      }
    }

    r.addListener(observe);
    try {
      r.command('a');
      await ready.future.timeout(const Duration(seconds: 5));
    } finally {
      r.removeListener(observe);
    }
  }

  test(
    'close joins in-flight actual save and suppresses late notifications',
    () async {
      await active();
      var notifications = 0;
      r.addListener(() => notifications++);
      final saving = r.save().then<Object?>((v) => v, onError: (Object e) => e);
      final closed = r.close();
      await closed;
      expect(await saving, isA<SnapshotSaveReceipt>());
      expect(notifications, 0);
      expect((await r.store.load()).snapshot!.revision, r.savedRevision);
      expect(r.closeFailures, isEmpty);
    },
  );
  for (final fails in [false, true]) {
    test(
      'close joins gated destruction and preserves outcome fails=$fails',
      () async {
        await active();
        host.failuresRemaining = fails ? 1 : 0;
        final gate = host.releaseGate = Gate();
        var notifications = 0;
        r.addListener(() => notifications++);
        final destroying = r.destroyBackend().then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );
        await gate.entered.future.timeout(const Duration(seconds: 3));
        await expectLater(r.save(), throwsStateError);
        await expectLater(r.destroyBackend(), throwsStateError);
        final closing = r.close().then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );
        await Future<void>.delayed(Duration.zero);
        gate.open();
        final destroyed = await destroying;
        final closed = await closing;
        if (fails) {
          expect(destroyed, isA<PlatformException>());
          expect(identical(destroyed, closed), isTrue);
        } else {
          expect(destroyed, isNull);
          expect(closed, isNull);
        }
        expect(notifications, 0);
        expect(r.backend.consumers, 0);
        expect(
          r.handoffSingleTrack(newOwner: 'closed').failure,
          'runtime-closed',
        );
      },
    );
  }

  for (final operation in ['save', 'destroy']) {
    test('listener can reenter close from $operation completion', () async {
      await active();
      Future<void>? closing;
      r.addListener(() {
        if ((operation == 'save' && r.savedRevision > 0) ||
            (operation == 'destroy' && r.snapshot.backendEpoch > 1)) {
          closing ??= r.close();
        }
      });
      if (operation == 'save') {
        await r.save();
      } else {
        await r.destroyBackend();
      }
      expect(closing, isNotNull);
      await closing!;
      expect(r.closeFailures, isEmpty);
      expect(r.backend.consumers, 0);
    });
  }
}
