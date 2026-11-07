import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/domain/playback/recovery_snapshot.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/diagnostic_cleanup.dart';
import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'fresh coordinator after closed runtime restores paused, not R2',
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
        const MaterialApp(home: Text('Runtime restart test')),
      );
      if (Platform.isAndroid) {
        for (var attempt = 0; attempt < 30; attempt++) {
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
      final run = 'coord-$pid-${DateTime.now().microsecondsSinceEpoch}';
      final first = await LocalRuntime.create(runId: run);
      Future<void>? closing;
      Future<void> closeFirst() => closing ??= first.close();
      cleanup.add(closeFirst);
      first.command('a');
      await until(
        () =>
            first.snapshot.currentEntryId == ownedA.entryId &&
            first.snapshot.positionMs > 300,
      );
      first.command('pause');
      first.command('seek', position: 2345);
      await until(
        () =>
            (first.snapshot.positionMs - 2345).abs() < 80 &&
            (first.backend.lastHost['samples'] as List? ?? []).any(
              (v) => v['nativePlaying'] == false,
            ),
      );
      final receipt = await first.save();
      final disk = (await first.store.load()).snapshot!;
      final oldClaim = first.coordinator.claim;
      first.command('play');
      await until(
        () =>
            first.snapshot.positionMs > disk.positionMs + 300 &&
            (first.backend.lastHost['samples'] as List? ?? []).any(
              (v) => v['nativePlaying'] == true,
            ),
      );
      await closeFirst();
      final released = await NativeLocalBackend.channel
          .invokeMapMethod<String, dynamic>('poll');
      expect(released!['samples'], isEmpty);
      expect(first.backend.consumers, 0);
      final second = await LocalRuntime.create(runId: run);
      cleanup.add(second.close);
      expect(identical(first.coordinator, second.coordinator), isFalse);
      final restored = second.snapshot;
      expect(restored.coordinatorEpoch, isNot(oldClaim.coordinatorEpoch));
      final actual = RecoverySnapshot(
        runId: run,
        revision: second.savedRevision,
        playbackSessionId: restored.playbackSessionId,
        entries: restored.entries,
        currentIndex: restored.entries.indexWhere(
          (e) => e.entryId == restored.currentEntryId,
        ),
        positionMs: restored.positionMs,
        mode: restored.mode,
        preview: restored.preview,
        confirmations: restored.confirmations,
      );
      expect(actual.toJson(), disk.toJson());
      expect(second.savedRevision, receipt.revision);
      expect(restored.desired, DesiredTransport.paused);
      expect(restored.tracks, isEmpty);
      expect(second.backend.consumers, 0);
      final rejected = second.coordinator.stop(
        CommandContext('old-stop', oldClaim),
      );
      expect(rejected.accepted, isFalse);
      expect(rejected.failure?.code, 'stale-controller');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(second.snapshot.eventCursor, restored.eventCursor);
      expect(second.snapshot.positionMs, disk.positionMs);
      expect(second.snapshot.desired, DesiredTransport.paused);
      expect(second.backend.consumers, 0);
      expect(second.backend.lastHost['samples'], isEmpty);
      second.command('play');
      await until(
        () =>
            second.snapshot.positionMs > disk.positionMs + 300 &&
            (second.backend.lastHost['samples'] as List? ?? []).any(
              (v) => v['nativePlaying'] == true,
            ),
      );
      second.command('stop');
      await until(
        () =>
            second.backend.consumers == 0 &&
            (second.backend.lastHost['samples'] as List? ?? []).isEmpty,
      );
      expect(second.coordinator.failures, isEmpty);
      // ignore: avoid_print
      print(
        'COORD_RESTART=${jsonEncode({'platform': Platform.operatingSystem, 'pid': pid, 'oldEpoch': oldClaim.coordinatorEpoch, 'newEpoch': restored.coordinatorEpoch, 'revision': receipt.revision, 'snapshot': actual.toJson(), 'stale': rejected.failure?.code, 'releasedSamples': released['samples'], 'finalSamples': second.backend.lastHost['samples']})}',
      );
    }),
  );
}
