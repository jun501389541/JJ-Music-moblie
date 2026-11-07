import 'dart:async';
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
  for (final mode in ['seek', 'remove', 'resume-incoming', 'resume-prepared']) {
    testWidgets(
      'real transition recovery $mode',
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
          const MaterialApp(home: Text('Transition recovery')),
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
          );
        }
        final r = await LocalRuntime.create(
          runId:
              'transition-$mode-$pid-${DateTime.now().microsecondsSinceEpoch}',
        );
        cleanup.add(r.close);
        r.command('a');
        await until(
          () =>
              r.snapshot.currentEntryId == ownedA.entryId &&
              r.snapshot.positionMs > 300,
        );
        final start = r.snapshot.positionMs;
        var intercepted = false;
        if (mode == 'resume-prepared') {
          r.command('b');
          r.command('pause');
          await until(
            () => r.snapshot.tracks.any(
              (t) =>
                  t.entry.entryId == ownedB.entryId &&
                  t.role == TrackRole.prepared,
            ),
          );
          expect(r.command('play')!.applied, isTrue);
        } else {
          final interceptedFuture = Completer<void>();
          final sub = r.backend.events.listen((event) {
            if (intercepted ||
                event.kind != BackendEventKind.progress ||
                r.snapshot.currentEntryId != ownedA.entryId) {
              return;
            }
            final incoming = r.snapshot.tracks
                .where(
                  (t) =>
                      t.entry.entryId == ownedB.entryId &&
                      t.role == TrackRole.incoming,
                )
                .firstOrNull;
            if (incoming == null ||
                incoming.trackHandleId != event.trackHandleId) {
              return;
            }
            final samples = r.backend.lastHost['samples'] as List? ?? [];
            if (!samples.any(
              (s) =>
                  s['id'] == incoming.trackHandleId &&
                  s['nativePlaying'] == true,
            )) {
              return;
            }
            intercepted = true;
            try {
              if (mode == 'seek') {
                expect(r.command('seek', position: 3000)!.applied, isTrue);
              } else if (mode == 'remove') {
                expect(
                  r.coordinator.replaceQueue(
                    CommandContext('remove-b', r.coordinator.claim),
                    [ownedA],
                    r.snapshot.queueRevision,
                  ).applied,
                  isTrue,
                );
              } else {
                expect(r.command('pause')!.applied, isTrue);
                expect(r.command('play')!.applied, isTrue);
              }
              interceptedFuture.complete();
            } catch (e, s) {
              interceptedFuture.completeError(e, s);
            }
          });
          cleanup.add(sub.cancel);
          r.command('b');
          await interceptedFuture.future.timeout(const Duration(seconds: 10));
        }
        final expected = mode.startsWith('resume')
            ? ownedB.entryId
            : ownedA.entryId;
        await until(
          () =>
              r.snapshot.currentEntryId == expected &&
              r.snapshot.requestedEntryId == expected &&
              r.snapshot.positionMs > (mode == 'seek' ? 3200 : start + 200) &&
              (r.backend.lastHost['samples'] as List? ?? []).any(
                (s) =>
                    s['nativePlaying'] == true &&
                    r.snapshot.tracks.any(
                      (t) =>
                          t.entry.entryId == expected &&
                          t.trackHandleId == s['id'] &&
                          t.role == TrackRole.active,
                    ),
              ),
        );
        expect(
          r.snapshot.confirmations.length,
          mode.startsWith('resume') ? 2 : 1,
        );
        await until(() => r.backend.consumers == 1);
        // ignore: avoid_print
        print(
          'TRANSITION_RECOVERY platform=${Platform.operatingSystem} mode=$mode pid=$pid intercepted=$intercepted current=${r.snapshot.currentEntryId} requested=${r.snapshot.requestedEntryId} position=${r.snapshot.positionMs} confirmations=${r.snapshot.confirmations.length}',
        );
        r.command('stop');
        await until(
          () =>
              r.backend.consumers == 0 &&
              (r.backend.lastHost['samples'] as List? ?? []).isEmpty,
        );
      }),
    );
  }
}
