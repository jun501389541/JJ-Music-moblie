import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/diagnostic_cleanup.dart';
import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'cooperative new authority retains native single track',
    (tester) => DiagnosticCleanup.run((cleanup) async {
      if (Platform.isAndroid) {
        cleanup.add(() async {
          await NativeLocalBackend.channel.invokeMethod<bool>(
            'diagnosticScreen',
            {'keepOn': false},
          );
        });
        await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticScreen',
          {'keepOn': true},
        );
      }
      await tester.pumpWidget(
        const MaterialApp(home: Text('Single track handoff')),
      );
      if (Platform.isAndroid) {
        for (var i = 0; i < 30; i++) {
          if (await NativeLocalBackend.channel.invokeMethod<bool>(
                'diagnosticForeground',
              ) ==
              true) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        expect(
          await NativeLocalBackend.channel.invokeMethod<bool>(
            'diagnosticForeground',
          ),
          isTrue,
          reason: 'Unlock selected phone',
        );
      }
      final runtime = await LocalRuntime.create(
        runId: 'handoff-$pid-${DateTime.now().microsecondsSinceEpoch}',
      );
      Future<void>? closing;
      Future<void> close() => closing ??= runtime.close();
      cleanup.add(close);
      runtime.command('a');
      await until(
        () =>
            runtime.snapshot.positionMs > 350 &&
            runtime.snapshot.confirmations.length == 1,
      );
      runtime.command('pause');
      runtime.command('seek', position: 2345);
      await until(
        () =>
            (runtime.snapshot.positionMs - 2345).abs() < 80 &&
            (runtime.backend.lastHost['samples'] as List)
                    .single['nativePlaying'] ==
                false,
      );
      final saving = runtime.save();
      expect(
        runtime.handoffSingleTrack(newOwner: 'save-busy').failure,
        'runtime-busy',
      );
      await saving;
      final disk = (await runtime.store.load()).snapshot!;
      runtime.command('play');
      await until(
        () =>
            runtime.snapshot.positionMs > disk.positionMs + 350 &&
            (runtime.backend.lastHost['samples'] as List)
                    .single['nativePlaying'] ==
                true,
      );
      final old = runtime.coordinator;
      final backend = runtime.backend;
      final before = runtime.snapshot;
      final host = backend.lastHost['host'];
      final handle = before.tracks.single.trackHandleId;
      // No delay inside the successful transfer. Retry only an explicit busy
      // refusal caused by native play acknowledgement or the mirror operation.
      var result = runtime.handoffSingleTrack(newOwner: 'runtime-next');
      for (var i = 0; result.coordinator == null && i < 40; i++) {
        expect(['runtime-busy', 'handoff-busy'], contains(result.failure));
        await Future<void>.delayed(const Duration(milliseconds: 25));
        result = runtime.handoffSingleTrack(newOwner: 'runtime-next');
      }
      expect(result.failure, isNull);
      expect(identical(runtime.coordinator, old), isFalse);
      expect(identical(runtime.coordinator, result.coordinator), isTrue);
      expect(identical(runtime.backend, backend), isTrue);
      expect(runtime.snapshot.coordinatorEpoch, before.coordinatorEpoch + 1);
      expect(runtime.snapshot.backendEpoch, before.backendEpoch);
      expect(runtime.snapshot.positionMs, greaterThan(disk.positionMs + 300));
      expect(runtime.snapshot.tracks.single.trackHandleId, handle);
      expect(runtime.snapshot.confirmations, before.confirmations);
      expect(
        runtime.coordinator
            .stop(CommandContext('old-claim', old.claim))
            .accepted,
        isFalse,
      );
      old.revokeResource(handle);
      await old.dispose();
      final after = runtime.snapshot.positionMs;
      await until(
        () =>
            runtime.snapshot.positionMs > after + 250 &&
            backend.lastHost['host'] == host &&
            (backend.lastHost['samples'] as List).single['id'] == handle &&
            (backend.lastHost['samples'] as List).single['nativePlaying'] ==
                true,
      );
      expect(backend.consumers, 1);
      expect(runtime.snapshot.confirmations, before.confirmations);
      await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
        'command': 'pause',
      });
      await until(
        () =>
            runtime.snapshot.desired == DesiredTransport.paused &&
            (backend.lastHost['samples'] as List).single['nativePlaying'] ==
                false,
      );
      await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
        'command': 'play',
      });
      await until(
        () =>
            runtime.snapshot.desired == DesiredTransport.playing &&
            (backend.lastHost['samples'] as List).single['nativePlaying'] ==
                true,
      );
      if (Platform.isAndroid) {
        await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
          'command': 'stop',
        });
      } else {
        // Existing Windows GSMTC diagnostic supports pause/play, not stop.
        expect(runtime.command('stop')!.applied, isTrue);
      }
      await until(
        () =>
            backend.consumers == 0 &&
            (backend.lastHost['samples'] as List).isEmpty,
      );
      expect(runtime.snapshot.desired, DesiredTransport.stopped);
      expect(runtime.coordinator.failures, isEmpty);
      await close();
      expect(
        runtime.handoffSingleTrack(newOwner: 'closed').failure,
        'runtime-closed',
      );
      final poll = await NativeLocalBackend.channel
          .invokeMapMethod<String, dynamic>('poll');
      expect(poll!['samples'], isEmpty);
      // ignore: avoid_print
      print(
        'COORD_HANDOFF=${jsonEncode({'platform': Platform.operatingSystem, 'pid': pid, 'oldEpoch': before.coordinatorEpoch, 'newEpoch': runtime.snapshot.coordinatorEpoch, 'backendEpoch': before.backendEpoch, 'handle': handle, 'savedPosition': disk.positionMs, 'handoffPosition': after, 'confirmation': before.confirmations, 'host': host, 'finalSamples': poll['samples']})}',
      );
    }),
  );
}
