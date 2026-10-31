import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android last native release abandons audio focus', (
    tester,
  ) async {
    final runtime = await LocalRuntime.create(runId: 'focus-release-$pid');
    try {
      runtime.command('a');
      await until(() => runtime.snapshot.currentEntryId == ownedA.entryId);
      await until(() => runtime.backend.lastHost['focusHeld'] == true);
      // Natural completion releases the last physical player without stop().
      runtime.command('seek', position: 11000);
      await until(() => runtime.backend.consumers == 0);
      await until(
        () =>
            runtime.backend.lastHost['samples'] is List &&
            (runtime.backend.lastHost['samples'] as List).isEmpty,
      );
      expect(
        runtime.backend.lastHost['focusHeld'],
        isFalse,
        reason: 'No native reader may retain OS audio focus',
      );
      expect(runtime.snapshot.confirmations.length, 1);
    } finally {
      // ignore: avoid_print
      print('FOCUS_RELEASE_HOST=${jsonEncode(runtime.backend.lastHost)}');
      await runtime.close();
    }
  });

  testWidgets(
    'Android OS transient focus loss pauses once and needs explicit resume',
    (tester) async {
      final runtime = await LocalRuntime.create(runId: 'focus-interrupt-$pid');
      try {
        runtime.command('a');
        await until(() => runtime.snapshot.currentEntryId == ownedA.entryId);
        final handle = runtime.snapshot.tracks.single.trackHandleId;
        expect(
          await NativeLocalBackend.channel.invokeMethod<bool>('focusProbe'),
          isTrue,
        );
        await until(() => runtime.snapshot.desired == DesiredTransport.paused);
        await until(() => runtime.backend.lastHost['focusHeld'] == false);
        final paused = runtime.snapshot.positionMs;
        await NativeLocalBackend.channel.invokeMethod<void>(
          'releaseFocusProbe',
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(runtime.snapshot.desired, DesiredTransport.paused);
        expect((runtime.snapshot.positionMs - paused).abs(), lessThan(180));
        expect(runtime.snapshot.confirmations.length, 1);
        runtime.command('play');
        await until(() => runtime.snapshot.positionMs > paused + 300);
        expect(runtime.snapshot.tracks.single.trackHandleId, handle);
        expect(runtime.snapshot.confirmations.length, 1);
        // Stop while an actual OS contender still owns transient focus.
        expect(
          await NativeLocalBackend.channel.invokeMethod<bool>('focusProbe'),
          isTrue,
        );
        await until(() => runtime.snapshot.desired == DesiredTransport.paused);
        runtime.command('stop');
        await until(() => runtime.backend.consumers == 0);
        await NativeLocalBackend.channel.invokeMethod<void>(
          'releaseFocusProbe',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(runtime.snapshot.desired, DesiredTransport.stopped);
        await until(() => runtime.backend.lastHost['focusHeld'] == false);
        expect(runtime.snapshot.confirmations.length, 1);
      } finally {
        await NativeLocalBackend.channel.invokeMethod<void>(
          'releaseFocusProbe',
        );
        // ignore: avoid_print
        print('FOCUS_INTERRUPT_HOST=${jsonEncode(runtime.backend.lastHost)}');
        // ignore: avoid_print
        print('FOCUS_INTERRUPT_RAW=${jsonEncode(runtime.backend.raw)}');
        await runtime.close();
      }
    },
  );

  testWidgets('Android abandoned listener cannot pause a renewed focus lease', (
    tester,
  ) async {
    final runtime = await LocalRuntime.create(runId: 'focus-stale-$pid');
    try {
      runtime.command('a');
      await until(() => runtime.snapshot.currentEntryId == ownedA.entryId);
      await NativeLocalBackend.channel.invokeMethod<void>(
        'captureFocusCallback',
      );
      runtime.command('pause');
      await until(() => runtime.backend.lastHost['focusHeld'] == false);
      runtime.command('play');
      await until(() => runtime.backend.lastHost['focusHeld'] == true);
      final before = runtime.snapshot.positionMs;
      await until(() => runtime.snapshot.positionMs > before + 150);
      // Fault injection into the old listener, explicitly not an OS event.
      await NativeLocalBackend.channel.invokeMethod<void>(
        'deliverCapturedFocusLoss',
      );
      await until(
        () => (runtime.backend.lastHost['lifecycle'] as List).any(
          (e) => (e as Map)['event'] == 'focus-stale-ignored',
        ),
      );
      final position = runtime.snapshot.positionMs;
      await until(() => runtime.snapshot.positionMs > position + 350);
      expect(runtime.snapshot.desired, DesiredTransport.playing);
      expect(runtime.backend.lastHost['focusHeld'], isTrue);
      expect(runtime.snapshot.confirmations.length, 1);
      runtime.command('stop');
      await until(() => runtime.backend.consumers == 0);
    } finally {
      // ignore: avoid_print
      print('FOCUS_STALE_HOST=${jsonEncode(runtime.backend.lastHost)}');
      // ignore: avoid_print
      print('FOCUS_STALE_RAW=${jsonEncode(runtime.backend.raw)}');
      await runtime.close();
    }
  });
}
