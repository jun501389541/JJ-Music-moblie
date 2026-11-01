import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/diagnostic_cleanup.dart';
import 'windows_local_playback_test.dart' show until;

Future<void> _visible(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    if (await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticForeground',
        ) ==
        true) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(
    await NativeLocalBackend.channel.invokeMethod<bool>('diagnosticForeground'),
    isTrue,
    reason: 'Unlock selected phone; no background-start or lock-screen bypass',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final mode in ['pause-first', 'recreate-first']) {
    testWidgets(
      'Android recreate and media pause: $mode',
      (tester) => DiagnosticCleanup.run((cleanup) async {
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
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('自有样本重建交错验证'))),
        );
        await tester.pumpAndSettle();
        await _visible(tester);
        final r = await LocalRuntime.create(
          runId: 'recreate-$mode-${DateTime.now().microsecondsSinceEpoch}',
        );
        cleanup.add(r.close);
        List<Map> events(String name) =>
            (r.backend.lastHost['lifecycle'] as List)
                .cast<Map>()
                .where((e) => e['event'] == name)
                .toList();
        Map sample() => (r.backend.lastHost['samples'] as List).single as Map;
        int mediaCount(String action) => r.backend.raw.where((row) {
          final command = row['systemCommand'];
          return command is Map &&
              command['command'] == action &&
              !command.containsKey('focusEpoch');
        }).length;
        Map? before, paused, resumed;
        try {
          r.command('a');
          await until(
            () =>
                r.snapshot.currentEntryId == ownedA.entryId &&
                r.snapshot.positionMs > 300 &&
                r.backend.lastHost['servicePresent'] == true,
          );
          final host = r.backend.lastHost['host'];
          final session = r.snapshot.playbackSessionId;
          final handle = r.snapshot.tracks.single.trackHandleId;
          final activity = events('activity-create').last['activity'];
          final engine = events('activity-create').last['engine'];
          final creates = events('activity-create').length;
          final serviceCreates = events('service-create').length;
          final pauses = mediaCount('pause');
          final plays = mediaCount('play');
          before = Map.from(r.backend.lastHost);
          Future<void> pause() => NativeLocalBackend.channel.invokeMethod<void>(
            'osCommand',
            {'command': 'pause'},
          );
          Future<void> recreate() =>
              NativeLocalBackend.channel.invokeMethod<void>('recreateActivity');
          // Both requests are submitted before either result is awaited. Android
          // serializes callbacks; this does not claim physical simultaneity.
          await Future.wait(
            mode == 'pause-first'
                ? [pause(), recreate()]
                : [recreate(), pause()],
          );
          await until(
            () =>
                events('activity-create').length > creates &&
                events('activity-destroy')
                    .any((e) => e['activity'] == activity) &&
                r.snapshot.desired == DesiredTransport.paused &&
                sample()['nativePlaying'] == false &&
                sample()['playWhenReady'] == false &&
                mediaCount('pause') > pauses,
          );
          expect(events('activity-create').last['activity'], isNot(activity));
          expect(events('activity-create').last['engine'], engine);
          expect(r.backend.lastHost['host'], host);
          expect(r.snapshot.playbackSessionId, session);
          expect(r.snapshot.tracks.single.trackHandleId, handle);
          expect(r.backend.consumers, 1);
          expect(r.snapshot.confirmations.length, 1);
          expect(events('service-create').length, serviceCreates);
          paused = Map.from(r.backend.lastHost);
          final position = r.snapshot.positionMs;
          final nativePosition = sample()['position'] as int;
          final pausedHost = r.backend.lastHost;
          await Future<void>.delayed(const Duration(milliseconds: 450));
          await until(() => !identical(r.backend.lastHost, pausedHost));
          expect(r.snapshot.desired, DesiredTransport.paused);
          expect(sample()['nativePlaying'], isFalse);
          expect(sample()['playWhenReady'], isFalse);
          expect((r.snapshot.positionMs - position).abs(), lessThan(100));
          expect(
            ((sample()['position'] as int) - nativePosition).abs(),
            lessThan(100),
          );
          await _visible(tester);
          expect(r.snapshot.desired, DesiredTransport.paused);
          expect(sample()['nativePlaying'], isFalse);
          await NativeLocalBackend.channel.invokeMethod<bool>(
            'diagnosticScreen',
            {'keepOn': true},
          );
          await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
            'command': 'play',
          });
          await until(
            () =>
                r.snapshot.desired == DesiredTransport.playing &&
                sample()['nativePlaying'] == true &&
                r.snapshot.positionMs > position + 300 &&
                mediaCount('play') > plays,
          );
          expect(r.snapshot.playbackSessionId, session);
          expect(r.snapshot.tracks.single.trackHandleId, handle);
          expect(r.snapshot.confirmations.length, 1);
          resumed = Map.from(r.backend.lastHost);
          r.command('stop');
          await until(
            () =>
                r.backend.consumers == 0 &&
                r.backend.lastHost['servicePresent'] == false,
          );
          expect(r.coordinator.failures, isEmpty);
        } finally {
          // ignore: avoid_print
          print(
            'RECREATE_$mode=${jsonEncode({'before': before, 'paused': paused, 'resumed': resumed, 'host': r.backend.lastHost, 'raw': r.backend.raw})}',
          );
        }
      }),
    );
  }
}
