import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'support/local_playback_contract.dart' show expectControlApplied;
import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Actual post-start read timeout closes A then permits B', (
    tester,
  ) async {
    final android = Platform.isAndroid;
    Directory? directory;
    NativeLocalBackend? backend;
    PlaybackCoordinator? coordinator;
    Map? confirmed, buffering;
    int? elapsedMs;
    try {
      String slow, normal;
      if (android) {
        await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticScreen',
          {'keepOn': true},
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('自有读取超时验证'))),
        );
        await tester.pumpAndSettle();
        expect(
          await NativeLocalBackend.channel.invokeMethod<bool>(
            'diagnosticForeground',
          ),
          isTrue,
          reason: 'Selected phone must remain unlocked; background eligibility is separate',
        );
        slow = (await NativeLocalBackend.channel.invokeMethod<String>(
          'rebufferFixtureUri',
        ))!;
        normal = (await NativeLocalBackend.channel.invokeMethod<String>(
          'fixtureUri',
        ))!;
      } else {
        final data = await rootBundle.load(
          'fixtures/local_playback/tone-long.wav',
        );
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        slow = (await NativeLocalBackend.channel.invokeMethod<String>(
          'registerOwnedPcm',
          {'bytes': bytes},
        ))!;
        directory = await Directory.systemTemp.createTemp('jj-timeout-owned-');
        final file = await File('${directory.path}/tone.wav')
            .writeAsBytes(bytes);
        normal = file.uri.toString();
      }
      final host = NativeLocalBackend({'a': slow, 'b': normal});
      backend = host;
      final c = PlaybackCoordinator(host);
      coordinator = c;
      const a = QueueEntry(entryId: 'a', trackKey: 'owned', fixtureId: 'a');
      const b = QueueEntry(entryId: 'b', trackKey: 'owned', fixtureId: 'b');
      CommandContext cmd(String id) => CommandContext(id, c.claim);
      Map gate() =>
          (host.lastHost[android ? 'readGates' : 'streamGates']
                  as Map?)?['native-1']
              as Map? ??
          {};
      expectControlApplied(
        c.play(cmd('a'), PlayIntent(entries: [a, b], entryId: 'a')),
      );
      await until(
        () => c.snapshot.currentEntryId == 'a' && c.snapshot.positionMs > 300,
      );
      confirmed = {
        'position': c.snapshot.positionMs,
        'confirmations': c.snapshot.confirmations.toList(),
      };
      await until(
        () =>
            gate()['blocked'] == true &&
            (host.lastHost['samples'] as List).single['state'] == 2,
      );
      buffering = {
        'gate': {...gate()},
        'sample': {...(host.lastHost['samples'] as List).single as Map},
      };
      final watch = Stopwatch()..start();
      // Do not allow/cancel/inject failure: wait out the actual native budget.
      await until(
        () => c.failures.any((f) => f.code == 'backend-error'),
        seconds: 35,
      );
      elapsedMs = watch.elapsedMilliseconds;
      expect(elapsedMs, greaterThan(12000));
      expect(c.snapshot.desired, DesiredTransport.paused);
      await until(
        () =>
            host.consumers == 0 &&
            gate()['closed'] == true &&
            gate()['readers'] == 0,
      );
      expect(gate()['waitedMs'], greaterThanOrEqualTo(14500));
      expect(
        host.raw.any((s) => s['id'] == 'native-1' && s['error'] == true),
        isTrue,
      );
      expect(c.snapshot.confirmations.length, 1);
      final failureCount = c.failures.length;
      expectControlApplied(
        c.play(cmd('b'), PlayIntent(entries: [a, b], entryId: 'b')),
      );
      await until(
        () => c.snapshot.currentEntryId == 'b' && c.snapshot.positionMs > 300,
      );
      expect(c.snapshot.confirmations.length, 2);
      await NativeLocalBackend.channel.invokeMethod<void>('allowOwnedRead', {
        'id': 'native-1',
      });
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(c.snapshot.currentEntryId, 'b');
      expect(c.snapshot.confirmations.length, 2);
      expect(c.failures.length, failureCount);
      expectControlApplied(c.stop(cmd('stop')));
      await until(() => host.consumers == 0);
    } finally {
      await coordinator?.dispose();
      await backend?.close();
      if (android) {
        await NativeLocalBackend.channel.invokeMethod<bool>(
          'diagnosticScreen',
          {'keepOn': false},
        );
      }
      // ignore: avoid_print
      print(
        'READ_TIMEOUT_${android ? 'android' : 'windows'}=${jsonEncode({'confirmed': confirmed, 'buffering': buffering, 'elapsedMs': elapsedMs, 'host': backend?.lastHost, 'raw': backend?.raw})}',
      );
      await directory?.delete(recursive: true);
    }
  });
}
