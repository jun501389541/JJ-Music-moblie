import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/runtime/local_runtime.dart';
import 'domain/playback/contracts.dart';
import 'platform/local/native_local_backend.dart';

/// Explicit release-only owned-media verification. Never normal app assembly.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold(body: Text('P1 focus probe'))));
  final token = await NativeLocalBackend.channel.invokeMethod<String>(
    'launchToken',
  );
  LocalRuntime? runtime;
  final checks = <String>[];
  Map<String, dynamic> proof;
  try {
    _require(
      kReleaseMode && token != null && token.isNotEmpty,
      'explicit-release-token-required',
    );
    final r = runtime = await LocalRuntime.create(runId: 'focus-$token');
    r.command('a');
    await _until(() => r.snapshot.currentEntryId == ownedA.entryId);
    final handle = r.snapshot.tracks.single.trackHandleId;
    _require(
      await NativeLocalBackend.channel.invokeMethod<bool>('focusProbe') == true,
      'os-focus-request-denied',
    );
    await _until(
      () =>
          r.snapshot.desired == DesiredTransport.paused &&
          r.backend.lastHost['focusHeld'] == false,
    );
    final paused = r.snapshot.positionMs;
    await NativeLocalBackend.channel.invokeMethod<void>('releaseFocusProbe');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _require(
      r.snapshot.desired == DesiredTransport.paused &&
          (r.snapshot.positionMs - paused).abs() < 180,
      'unexpected-auto-resume',
    );
    checks.add('os-transient-loss-pauses-without-auto-resume');
    r.command('play');
    await _until(() => r.snapshot.positionMs > paused + 300);
    _require(
      r.snapshot.tracks.single.trackHandleId == handle &&
          r.snapshot.confirmations.length == 1,
      'resume-identity-changed',
    );
    checks.add('explicit-resume-same-confirmation');
    await NativeLocalBackend.channel.invokeMethod<void>('captureFocusCallback');
    r.command('pause');
    await _until(() => r.backend.lastHost['focusHeld'] == false);
    r.command('play');
    await _until(() => r.backend.lastHost['focusHeld'] == true);
    final before = r.snapshot.positionMs;
    await NativeLocalBackend.channel.invokeMethod<void>(
      'deliverCapturedFocusLoss',
    );
    await _until(() => r.snapshot.positionMs > before + 350);
    _require(
      r.snapshot.desired == DesiredTransport.playing &&
          r.snapshot.confirmations.length == 1,
      'stale-listener-paused-new-lease',
    );
    checks.add('injected-stale-listener-ignored');
    _require(
      await NativeLocalBackend.channel.invokeMethod<bool>('focusProbe') == true,
      'second-focus-request-denied',
    );
    await _until(() => r.snapshot.desired == DesiredTransport.paused);
    r.command('stop');
    await _until(
      () =>
          r.backend.consumers == 0 && r.backend.lastHost['focusHeld'] == false,
    );
    await NativeLocalBackend.channel.invokeMethod<void>('releaseFocusProbe');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _require(
      r.snapshot.desired == DesiredTransport.stopped,
      'stop-auto-resumed',
    );
    checks.add('stop-during-interruption-remains-stopped');
    r.command('a');
    await _until(
      () =>
          r.snapshot.confirmations.length == 2 &&
          r.snapshot.tracks.any((t) => t.role == TrackRole.active),
    );
    r.command('seek', position: 11000);
    await _until(
      () =>
          r.backend.consumers == 0 &&
          r.backend.lastHost['focusHeld'] == false &&
          (r.backend.lastHost['samples'] as List).isEmpty,
    );
    checks.add('natural-end-final-release-abandons-focus');
    proof = {
      'stage': 'focus-passed',
      'checks': checks,
      'consumers': r.backend.consumers,
      'focusHeld': r.backend.lastHost['focusHeld'],
      'events': (r.backend.lastHost['lifecycle'] as List)
          .map((e) => (e as Map)['event'])
          .toList(),
    };
  } catch (e) {
    proof = {'stage': 'error', 'error': e.toString(), 'checks': checks};
  } finally {
    await NativeLocalBackend.channel.invokeMethod<void>('releaseFocusProbe');
    await runtime?.close();
  }
  await NativeLocalBackend.channel.invokeMethod<void>('proof', {
    'json': jsonEncode({
      ...proof,
      'pid': pid,
      'probeToken': token,
      'releaseMode': kReleaseMode,
    }),
  });
}

void _require(bool value, String failure) {
  if (!value) throw StateError(failure);
}

Future<void> _until(bool Function() check) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!check() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  _require(check(), 'native-condition-timeout');
}
