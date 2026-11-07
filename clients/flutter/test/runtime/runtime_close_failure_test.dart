import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'runtime_handoff_busy_test.dart' show NativeHost, Gate;

class ClosingHost extends NativeHost {
  bool failRelease = true;
  final ids = <String>{};
  final releases = <String>[];
  int gatedPolls = 0;
  final laterPolls = Completer<void>();
  @override
  Future<Object?> call(MethodCall call) async {
    if (call.method == 'prepare') {
      ids.add((call.arguments as Map)['id'] as String);
    }
    if (call.method == 'release') {
      final id = (call.arguments as Map)['id'] as String;
      releases.add(id);
      if (failRelease && id == 'native-1') {
        throw PlatformException(code: 'owned-persistent-release');
      }
      ids.remove(id);
      return null;
    }
    if (call.method == 'poll') {
      if (mirror?.entered.isCompleted == true &&
          ++gatedPolls >= 5 &&
          !laterPolls.isCompleted) {
        laterPolls.complete();
      }
      if (playing) position += 120;
      return {
        'commands': [],
        'samples': [
          for (final id in ids)
            {
              'id': id,
              'state': 3,
              'ready': true,
              'nativePlaying': playing,
              'playWhenReady': playing,
              'position': position,
              'duration': 12000,
              'canSeek': true,
            },
        ],
      };
    }
    return super.call(call);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ClosingHost host;
  late LocalRuntime runtime;
  setUp(() async {
    host = ClosingHost();
    messenger.setMockMethodCallHandler(NativeLocalBackend.channel, host.call);
    addTearDown(
      () =>
          messenger.setMockMethodCallHandler(NativeLocalBackend.channel, null),
    );
    final run = 'close-fail-$pid-${DateTime.now().microsecondsSinceEpoch}';
    runtime = await LocalRuntime.create(runId: run);
    addTearDown(() async {
      host.failRelease = false;
      host.mirror?.open();
      await runtime.backend.destroyNativeResources();
      try {
        await runtime.close();
      } on PlatformException catch (error) {
        if (error.code != 'owned-persistent-release') rethrow;
      }
      final dir = runtime.store.directory;
      if (!dir.absolute.path.endsWith('${Platform.pathSeparator}$run')) {
        throw StateError('Unsafe cleanup');
      }
      if (await dir.exists()) await dir.delete(recursive: true);
    });
  });
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

  Future<void> failedClose() => expectLater(
    runtime.close(),
    throwsA(
      isA<PlatformException>().having(
        (e) => e.code,
        'first error',
        'owned-persistent-release',
      ),
    ),
  );

  test('persistent release failure still disposes runtime notifier and backend streams', () async {
    await active();
    runtime.addListener(() {});
    final eventsDone = Completer<void>(), commandsDone = Completer<void>();
    final events = runtime.backend.events.listen(
      (_) {},
      onDone: eventsDone.complete,
    );
    final commands = runtime.backend.systemCommands.listen(
      (_) {},
      onDone: commandsDone.complete,
    );
    addTearDown(events.cancel);
    addTearDown(commands.cancel);
    await failedClose();
    final attempts = host.releases.length;
    final memo = runtime.close();
    expect(identical(memo, runtime.close()), isTrue);
    await expectLater(memo, throwsA(isA<PlatformException>()));
    expect(
      host.releases.length,
      attempts,
      reason: 'Failed close is cached, not retried',
    );
    expect(
      () => ChangeNotifier.debugAssertNotDisposed(runtime),
      throwsFlutterError,
    );
    expect(eventsDone.isCompleted, isTrue);
    expect(commandsDone.isCompleted, isTrue);
    expect(
      runtime.backend.consumers,
      1,
      reason: 'Failed native resource remains honestly owned',
    );
    expect(
      runtime.handoffSingleTrack(newOwner: 'closed').failure,
      'runtime-closed',
    );
    expect(runtime.command('play')!.failure?.code, 'runtime-closed');
    runtime.reconnect();
  });
  test(
    'persistent release failure still closes writer lock (Windows host)',
    () async {
      await active();
      await failedClose();
      // On this Windows host an open writer.lock prevents recursive deletion.
      // This is host filesystem evidence, not a cross-process or phone lock proof.
      final dir = runtime.store.directory;
      expect(
        dir.absolute.path.endsWith(
          '${Platform.pathSeparator}${runtime.store.runId}',
        ),
        isTrue,
      );
      await dir.delete(recursive: true);
      expect(await dir.exists(), isFalse);
    },
  );
  test('concurrent and repeated runtime close share one completion', () async {
    final first = runtime.close();
    final second = runtime.close();
    final observedFirst = first.then<Object?>(
      (_) => null,
      onError: (Object e) => e,
    );
    final observedSecond = second.then<Object?>(
      (_) => null,
      onError: (Object e) => e,
    );
    expect(identical(first, second), isTrue);
    expect(await observedFirst, isNull);
    expect(await observedSecond, isNull);
    expect(identical(first, runtime.close()), isTrue);
  });
  test('close awaits actual mirror after later timer ticks', () async {
    final gate = host.mirror = Gate();
    await gate.entered.future.timeout(const Duration(seconds: 3));
    await host.laterPolls.future.timeout(const Duration(seconds: 3));
    var completed = false;
    final close = runtime.close().then((_) {
      completed = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      completed,
      isFalse,
      reason: 'Periodic skip must not overwrite the pending mirror Future',
    );
    gate.open();
    await close;
    expect(completed, isTrue);
  });
  test('backend close attempts later handles and closes streams despite release and log errors', () async {
    final dir = await Directory.systemTemp.createTemp('jj-close-owned-');
    final backend = NativeLocalBackend({
      'tone-long': 'file:///owned.wav',
    }, logFile: File(dir.path));
    final eventDone = Completer<void>(), commandDone = Completer<void>();
    final eventSub = backend.events.listen((_) {}, onDone: eventDone.complete);
    final commandSub = backend.systemCommands.listen(
      (_) {},
      onDone: commandDone.complete,
    );
    try {
      await Future.wait([
        for (var i = 0; i < 2; i++)
          backend.prepare(
            PrepareRequest(
              requestId: 'request-$i',
              entry: i == 0 ? ownedA : ownedB,
              generation: 1,
              backendEpoch: 1,
            ),
          ),
      ]);
      await expectLater(
        backend.close(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'first fault not replaced by log failure',
            'owned-persistent-release',
          ),
        ),
      );
      expect(host.releases, contains('native-2'));
      expect(eventDone.isCompleted, isTrue);
      expect(commandDone.isCompleted, isTrue);
      expect(backend.consumers, 1);
      expect(
        backend.closeFailures.length,
        2,
        reason: 'Release and log faults both remain observable',
      );
    } finally {
      host.failRelease = false;
      await backend.destroyNativeResources();
      await eventSub.cancel();
      await commandSub.cancel();
      // Also cancel its timer if prepare failed before the body called close.
      try {
        await backend.close();
      } on PlatformException catch (error) {
        if (error.code != 'owned-persistent-release') rethrow;
      } on FileSystemException {
        // Intentional directory-as-log fixture, including early setup failure.
      }
      await dir.delete(recursive: true);
    }
  });
}
