import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

class Gate {
  final entered = Completer<void>();
  final completion = Completer<void>();
  Future<void> wait() {
    if (!entered.isCompleted) entered.complete();
    return completion.future;
  }

  void open() {
    if (!completion.isCompleted) completion.complete();
  }
}

/// Host-only native transport. No decoder, device, or physical audio output.
class NativeHost {
  final actions = <String>[];
  Gate? mirror, release;
  String? handle;
  bool playing = false;
  int position = 0;
  Future<Object?> call(MethodCall call) async {
    switch (call.method) {
      case 'prepare':
        handle = (call.arguments as Map)['id'] as String;
        actions.add('prepare');
      case 'play':
        playing = true;
        actions.add('play');
      case 'pause':
      case 'stop':
        playing = false;
        actions.add(call.method);
      case 'release':
        actions.add('release');
        await release?.wait();
        handle = null;
        playing = false;
      case 'mirror':
        await mirror?.wait();
      case 'poll':
        if (playing) position += 120;
        return {
          'samples': [
            if (handle != null)
              {
                'id': handle,
                'ready': true,
                'state': 3,
                'nativePlaying': playing,
                'playWhenReady': playing,
                'position': position,
                'duration': 12000,
                'canSeek': true,
              },
          ],
          'commands': [],
        };
      default:
        throw StateError('Unexpected native method ${call.method}');
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NativeHost host;
  late LocalRuntime runtime;
  Future<void> active() async {
    final confirmed = Completer<void>();
    void observe() {
      if (runtime.snapshot.confirmations.length == 1 &&
          !confirmed.isCompleted) {
        confirmed.complete();
      }
    }

    runtime.addListener(observe);
    try {
      runtime.command('a');
      await confirmed.future.timeout(const Duration(seconds: 5));
    } finally {
      runtime.removeListener(observe);
    }
  }

  setUp(() async {
    host = NativeHost();
    messenger.setMockMethodCallHandler(NativeLocalBackend.channel, host.call);
    addTearDown(() {
      messenger.setMockMethodCallHandler(NativeLocalBackend.channel, null);
    });
    final run = 'busy-$pid-${DateTime.now().microsecondsSinceEpoch}';
    runtime = await LocalRuntime.create(runId: run);
    addTearDown(() async {
      // Release test-owned gates before closing timers/locks on assertion failure.
      host.mirror?.open();
      host.release?.open();
      try {
        await runtime.close();
      } finally {
        final dir = runtime.store.directory;
        if (!dir.absolute.path.endsWith('${Platform.pathSeparator}$run')) {
          throw StateError('Refuse cleanup outside this test run');
        }
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });
  });

  for (final fails in [false, true]) {
    test(
      'mirror gate rejects handoff without side effects, then clears fails=$fails',
      () async {
        await active();
        final old = runtime.coordinator;
        final before = runtime.snapshot;
        final actions = List.of(host.actions);
        final gate = host.mirror = Gate();
        await gate.entered.future.timeout(const Duration(seconds: 3));
        expect(
          runtime.handoffSingleTrack(newOwner: 'busy-attempt').failure,
          'runtime-busy',
        );
        expect(identical(runtime.coordinator, old), isTrue);
        expect(runtime.snapshot.coordinatorEpoch, before.coordinatorEpoch);
        expect(runtime.backend.consumers, 1);
        expect(host.actions, actions);
        final settled = Completer<CoordinatorHandoffResult>();
        void afterMirror() {
          // Mirror notifies after clearing its flag. Transfer in that same stack,
          // before any later periodic mirror can begin; remove to avoid reentry.
          runtime.removeListener(afterMirror);
          settled.complete(
            runtime.handoffSingleTrack(newOwner: 'after-mirror'),
          );
        }

        runtime.addListener(afterMirror);
        if (fails) {
          gate.completion.completeError(
            PlatformException(code: 'owned-mirror-fault'),
          );
        } else {
          gate.open();
        }
        final result = await settled.future.timeout(const Duration(seconds: 3));
        expect(result.failure, isNull);
        expect(identical(runtime.coordinator, result.coordinator), isTrue);
        expect(identical(runtime.coordinator, old), isFalse);
        expect(runtime.snapshot.coordinatorEpoch, before.coordinatorEpoch + 1);
        expect(runtime.snapshot.confirmations, before.confirmations);
        expect(
          runtime.snapshot.tracks.single.trackHandleId,
          before.tracks.single.trackHandleId,
        );
        expect(host.actions, actions);
        if (fails) expect(runtime.message, contains('系统镜像失败'));
      },
    );
  }

  test(
    'destroy pending release rejects handoff and overlapping save/destroy',
    () async {
      await active();
      final old = runtime.coordinator;
      final before = runtime.snapshot;
      final gate = host.release = Gate();
      final destruction = runtime.destroyBackend();
      await gate.entered.future.timeout(const Duration(seconds: 3));
      final actions = List.of(host.actions);
      expect(
        runtime.handoffSingleTrack(newOwner: 'during-destroy').failure,
        'runtime-busy',
      );
      await expectLater(runtime.save(), throwsStateError);
      await expectLater(runtime.destroyBackend(), throwsStateError);
      expect(identical(runtime.coordinator, old), isTrue);
      expect(runtime.snapshot.coordinatorEpoch, before.coordinatorEpoch);
      expect(runtime.snapshot.backendEpoch, before.backendEpoch);
      expect(
        runtime.snapshot.tracks.single.trackHandleId,
        before.tracks.single.trackHandleId,
      );
      expect(runtime.backend.consumers, 1);
      expect(host.actions, actions);
      gate.open();
      await destruction;
      expect(runtime.snapshot.backendEpoch, before.backendEpoch + 1);
      expect(runtime.snapshot.desired, DesiredTransport.paused);
      expect(runtime.snapshot.tracks, isEmpty);
      expect(runtime.backend.consumers, 0);
      expect(host.actions.where((a) => a == 'release').length, 1);
      expect(
        runtime.handoffSingleTrack(newOwner: 'after-destroy').failure,
        'handoff-unsupported',
      );
    },
  );

  test(
    'save validation failure clears busy without pretending a save succeeded',
    () async {
      final before = runtime.snapshot;
      await expectLater(runtime.save(), throwsStateError);
      expect(runtime.savedRevision, 0);
      expect(runtime.snapshot.coordinatorEpoch, before.coordinatorEpoch);
      expect(
        runtime.handoffSingleTrack(newOwner: 'after-failed-save').failure,
        'handoff-unsupported',
      );
      expect((await runtime.store.load()).snapshot, isNull);
      expect(host.actions, isEmpty);
    },
  );
}
