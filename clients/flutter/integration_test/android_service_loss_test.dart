import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final mode in [
    'service-loss',
    'full-queue-loss',
    'restart-race',
    'background-controls',
  ]) {
    testWidgets('Android lifecycle: $mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('自有样本服务验证'))),
      );
      await tester.pumpAndSettle();
      await NativeLocalBackend.channel.invokeMethod<bool>('diagnosticScreen', {
        'keepOn': true,
      });
      var foreground = false;
      for (var i = 0; i < 30; i++) {
        foreground =
            await NativeLocalBackend.channel.invokeMethod<bool>(
              'diagnosticForeground',
            ) ??
            false;
        if (foreground) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(
        foreground,
        isTrue,
        reason: 'Selected phone must be unlocked; no lock-screen bypass',
      );
      final r = await LocalRuntime.create(runId: 'service-$mode-$pid');
      Map<String, dynamic>? before, afterLoss;
      try {
        r.command('a');
        await until(
          () =>
              r.snapshot.currentEntryId == ownedA.entryId &&
              r.snapshot.positionMs > 350 &&
              r.backend.lastHost['servicePresent'] == true &&
              r.backend.lastHost['pendingServiceStarts'] == 0,
        );
        final handle = r.snapshot.tracks.single.trackHandleId;
        final host = r.backend.lastHost['host'];
        final session = r.snapshot.playbackSessionId;
        before = Map<String, dynamic>.from(r.backend.lastHost);
        if (mode == 'service-loss' || mode == 'full-queue-loss') {
          expect(
            await NativeLocalBackend.channel.invokeMethod<bool>(
              mode == 'full-queue-loss'
                  ? 'destroyServiceFullQueueProbe'
                  : 'destroyServiceProbe',
            ),
            isTrue,
          );
          await until(() => r.backend.lastHost['servicePresent'] == false);
          await Future<void>.delayed(const Duration(milliseconds: 450));
          afterLoss = Map<String, dynamic>.from(r.backend.lastHost);
          expect(
            (afterLoss['samples'] as List).single['nativePlaying'],
            isFalse,
            reason: 'A destroyed playback service must not leave the native player running',
          );
          expect(r.snapshot.desired, DesiredTransport.paused);
          expect(r.backend.lastHost['focusHeld'], isFalse);
          final position = r.snapshot.positionMs;
          await Future<void>.delayed(const Duration(milliseconds: 350));
          expect(r.snapshot.positionMs - position, lessThan(100));
          r.command('play');
        } else if (mode == 'restart-race') {
          int events(String event) => (r.backend.lastHost['lifecycle'] as List)
              .where((e) => e['event'] == event)
              .length;
          final losses = events('service-loss-paused');
          final creates = events('service-create');
          await NativeLocalBackend.channel.invokeMethod<void>(
            'restartServiceProbe',
          );
          await until(
            () =>
                events('service-create') > creates &&
                r.backend.lastHost['pendingServiceStarts'] == 0,
          );
          await Future<void>.delayed(const Duration(milliseconds: 400));
          expect(
            events('service-loss-paused'),
            losses,
            reason: 'Expected old service destruction cannot consume newer registration',
          );
          expect(r.snapshot.desired, DesiredTransport.playing);
        } else {
          await NativeLocalBackend.channel.invokeMethod<void>(
            'backgroundActivity',
          );
          await Future<void>.delayed(const Duration(milliseconds: 450));
          expect(
            await NativeLocalBackend.channel.invokeMethod<bool>(
              'diagnosticForeground',
            ),
            isFalse,
          );
          final position = r.snapshot.positionMs;
          await Future<void>.delayed(const Duration(milliseconds: 450));
          expect(r.snapshot.positionMs, greaterThan(position + 150));
          await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
            'command': 'pause',
          });
          await until(() => r.snapshot.desired == DesiredTransport.paused);
          expect(r.backend.lastHost['servicePresent'], isTrue);
          await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
            'command': 'play',
          });
        }
        final pausedPosition = r.snapshot.positionMs;
        await until(
          () =>
              r.snapshot.desired == DesiredTransport.playing &&
              r.snapshot.positionMs > pausedPosition + 250 &&
              r.backend.lastHost['servicePresent'] == true,
        );
        expect(r.backend.lastHost['host'], host);
        expect(r.snapshot.playbackSessionId, session);
        expect(r.snapshot.tracks.single.trackHandleId, handle);
        expect(r.snapshot.confirmations.length, 1);
        r.command('stop');
        await until(
          () =>
              r.backend.consumers == 0 &&
              r.backend.lastHost['servicePresent'] == false &&
              r.backend.lastHost['pendingServiceStarts'] == 0,
        );
        await Future<void>.delayed(const Duration(milliseconds: 350));
        expect(r.snapshot.desired, DesiredTransport.stopped);
        expect(r.coordinator.failures, isEmpty);
      } finally {
        await NativeLocalBackend.channel.invokeMethod<void>('showActivity');
        await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticScreen',
          {'keepOn': false},
        );
        // ignore: avoid_print
        print(
          'ANDROID_SERVICE_$mode=${jsonEncode({'before': before, 'afterLoss': afterLoss, 'host': r.backend.lastHost, 'raw': r.backend.raw})}',
        );
        await r.close();
      }
    });
  }
}
