import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'runtime_handoff_busy_test.dart' show NativeHost, Gate;

class ReleaseFailureHost extends NativeHost {
  int failuresRemaining = 1;
  bool failPause = false;
  Gate? releaseGate;
  @override
  Future<Object?> call(MethodCall call) async {
    if (call.method == 'pause' && failPause) {
      throw PlatformException(code: 'owned-pause-fault');
    }
    if (call.method == 'release') await releaseGate?.wait();
    if (call.method == 'release' && failuresRemaining > 0) {
      failuresRemaining--;
      actions.add('release-failed');
      throw PlatformException(code: 'owned-release-fault');
    }
    return super.call(call);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ReleaseFailureHost host;
  late LocalRuntime runtime;
  Future<void> active() async {
    final ready = Completer<void>();
    void observe() {
      if (runtime.snapshot.confirmations.length == 1 && !ready.isCompleted) {
        ready.complete();
      }
    }

    runtime.addListener(observe);
    try {
      runtime.command('a');
      await ready.future.timeout(const Duration(seconds: 5));
    } finally {
      runtime.removeListener(observe);
    }
  }

  setUp(() async {
    host = ReleaseFailureHost();
    messenger.setMockMethodCallHandler(NativeLocalBackend.channel, host.call);
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(NativeLocalBackend.channel, null),
    );
    final run = 'destroy-fail-$pid-${DateTime.now().microsecondsSinceEpoch}';
    runtime = await LocalRuntime.create(runId: run);
    addTearDown(() async {
      host.failuresRemaining = 0;
      host.releaseGate?.open();
      try {
        await runtime.close();
      } finally {
        final dir = runtime.store.directory;
        if (!dir.absolute.path.endsWith('${Platform.pathSeparator}$run')) {
          throw StateError('Unsafe test cleanup');
        }
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });
  });

  test(
    'failed destruction cannot transfer or restart uncertain live resource',
    () async {
      await active();
      final old = runtime.coordinator;
      final before = runtime.snapshot;
      await expectLater(
        runtime.destroyBackend(),
        throwsA(isA<PlatformException>()),
      );
      expect(
        runtime.handoffSingleTrack(newOwner: 'unsafe-next').failure,
        'runtime-backend-uncertain',
      );
      expect(identical(runtime.coordinator, old), isTrue);
      expect(runtime.snapshot.coordinatorEpoch, before.coordinatorEpoch);
      expect(runtime.snapshot.backendEpoch, before.backendEpoch);
      expect(runtime.snapshot.desired, DesiredTransport.paused);
      expect(
        runtime.backend.consumers,
        1,
        reason: 'No release receipt, cannot claim resource gone',
      );
      final actions = List.of(host.actions);
      for (final name in ['a', 'b', 'next', 'previous', 'play', 'seek']) {
        expect(runtime.command(name)!.failure?.code, 'backend-state-uncertain');
      }
      expect(host.actions, actions);
      expect(runtime.snapshot.confirmations, before.confirmations);
    },
  );
  test(
    'explicit destruction retry uses new release attempt and trusted receipt',
    () async {
      await active();
      final before = runtime.snapshot;
      await expectLater(
        runtime.destroyBackend(),
        throwsA(isA<PlatformException>()),
      );
      expect(host.actions.where((a) => a == 'release-failed').length, 1);
      await runtime.destroyBackend();
      expect(host.actions.where((a) => a == 'release').length, 1);
      expect(runtime.backend.consumers, 0);
      expect(runtime.snapshot.tracks, isEmpty);
      expect(runtime.snapshot.desired, DesiredTransport.paused);
      expect(runtime.snapshot.backendEpoch, before.backendEpoch + 1);
      expect(
        runtime.handoffSingleTrack(newOwner: 'empty').failure,
        'handoff-unsupported',
      );
      expect(runtime.command('play')!.applied, isTrue);
    },
  );

  test(
    'repeated failures remain uncertain without automatic release retries',
    () async {
      await active();
      host.failuresRemaining = 2;
      final epoch = runtime.snapshot.backendEpoch;
      for (var attempt = 1; attempt <= 2; attempt++) {
        await expectLater(
          runtime.destroyBackend(),
          throwsA(isA<PlatformException>()),
        );
        expect(
          host.actions.where((a) => a == 'release-failed').length,
          attempt,
        );
        expect(runtime.backend.consumers, 1);
        expect(runtime.snapshot.backendEpoch, epoch);
        expect(runtime.snapshot.desired, DesiredTransport.paused);
        expect(
          runtime.command('play')!.failure?.code,
          'backend-state-uncertain',
        );
      }
      await runtime.destroyBackend();
      expect(host.actions.where((a) => a == 'release').length, 1);
      expect(runtime.backend.consumers, 0);
      expect(runtime.snapshot.backendEpoch, epoch + 1);
    },
  );

  test(
    'failed pause does not unlock uncertain backend or replace original error',
    () async {
      await active();
      host.failPause = true;
      await expectLater(
        runtime.destroyBackend(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'original fault',
            'owned-release-fault',
          ),
        ),
      );
      // Observe completion of the separately dispatched pause error handler.
      await Future<void>.delayed(Duration.zero);
      expect(runtime.snapshot.desired, DesiredTransport.paused);
      expect(
        runtime.handoffSingleTrack(newOwner: 'unsafe').failure,
        'runtime-backend-uncertain',
      );
      expect(runtime.command('play')!.failure?.code, 'backend-state-uncertain');
      expect(
        runtime.coordinator.failures.any((f) => f.stage == 'pause'),
        isTrue,
      );
      expect(
        host.playing,
        isTrue,
        reason: 'Mock physical pause failed; no claim of silence',
      );
    },
  );

  test(
    'concurrent cleanup callers share one pending native release attempt',
    () async {
      await active();
      host.failuresRemaining = 0;
      final gate = host.releaseGate = Gate();
      final track = runtime.snapshot.tracks.single;
      final first = runtime.backend.release(
        track.trackHandleId,
        track.consumerId,
        track.backendEpoch,
      );
      final second = runtime.backend.release(
        track.trackHandleId,
        track.consumerId,
        track.backendEpoch,
      );
      await gate.entered.future.timeout(const Duration(seconds: 3));
      expect(runtime.backend.consumers, 1);
      gate.open();
      final receipts = await Future.wait([first, second]);
      expect(host.actions.where((a) => a == 'release').length, 1);
      expect(
        receipts.every(
          (r) =>
              r.trackHandleId == track.trackHandleId &&
              r.consumerId == track.consumerId,
        ),
        isTrue,
      );
      expect(runtime.backend.consumers, 0);
    },
  );
}
