import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app/runtime/local_runtime.dart';
import 'domain/playback/contracts.dart';
import 'domain/playback/recovery_snapshot.dart';
import 'platform/local/native_local_backend.dart';

/// Explicit test entrypoint, never the normal product assembly. Same binary
/// launched twice; external controller kills process after saved receipt.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Text('P1 isolated process recovery probe')),
    ),
  );
  final mode = Platform.isAndroid
      ? await NativeLocalBackend.channel.invokeMethod<String>('launchMode')
      : args.firstOrNull;
  LocalRuntime? r;
  try {
    const runId = String.fromEnvironment('P1_RUN_ID');
    if (runId.isEmpty) {
      throw StateError('explicit-run-id-required');
    }
    r = await LocalRuntime.create(runId: runId);
    final runtime = r;
    final authorityFile = File(
      '${r.store.directory.path}/probe-authority.json',
    );
    if (mode == 'save') {
      if (r.savedRevision != 0) {
        throw StateError('run-id-already-used');
      }
      r.command('a');
      final end = DateTime.now().add(const Duration(seconds: 10));
      while (r.snapshot.currentEntryId != ownedA.entryId &&
          DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (r.snapshot.currentEntryId != ownedA.entryId) {
        throw StateError('native-not-confirmed');
      }
      r.command('pause');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      r.command('seek', position: 2345);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await r.save();
      final claim = r.coordinator.claim;
      await authorityFile.writeAsString(
        jsonEncode({
          'owner': claim.ownerId,
          'epoch': claim.coordinatorEpoch,
          'session': claim.playbackSessionId,
        }),
        flush: true,
      );
    } else if (mode != 'restore') {
      throw StateError('explicit-mode-required');
    }
    final s = r.snapshot;
    if (mode == 'restore' &&
        (r.savedRevision == 0 ||
            s.desired != DesiredTransport.paused ||
            s.positionMs < 2250 ||
            s.positionMs > 2450 ||
            r.backend.consumers != 0 ||
            s.confirmations.isEmpty)) {
      throw StateError('disk-restore-check-failed');
    }
    final disk = (await r.store.load()).snapshot;
    final restored = RecoverySnapshot(
      runId: runId,
      revision: r.savedRevision,
      playbackSessionId: s.playbackSessionId,
      entries: s.entries,
      currentIndex: s.entries.indexWhere((e) => e.entryId == s.currentEntryId),
      positionMs: s.positionMs,
      mode: s.mode,
      preview: s.preview,
      confirmations: s.confirmations,
    );
    if (disk == null ||
        jsonEncode(restored.toJson()) != jsonEncode(disk.toJson())) {
      throw StateError('runtime-disk-snapshot-mismatch');
    }
    final proof = <String, dynamic>{
      'stage': mode == 'save' ? 'saved' : 'loaded',
      'pid': pid,
      'coordinatorEpoch': s.coordinatorEpoch,
      'session': s.playbackSessionId,
      'revision': r.savedRevision,
      'position': s.positionMs,
      'desired': s.desired.name,
      'consumers': r.backend.consumers,
      'fixture': s.entries.first.fixtureId,
      'confirmations': s.confirmations,
      'directory': r.store.directory.path,
      'runId': runId,
      'diskSnapshot': disk.toJson(),
      'runtimeSnapshot': restored.toJson(),
    };
    if (mode == 'restore') {
      final old = jsonDecode(
        await authorityFile.readAsString(),
      ) as Map<String, dynamic>;
      final before = r.snapshot;
      final rejected = r.coordinator.stop(
        CommandContext(
          'previous-process-stop',
          ControllerClaim(
            old['owner'] as String,
            old['epoch'] as int,
            old['session'] as String,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (rejected.accepted ||
          rejected.applied ||
          rejected.failure?.code != 'stale-controller' ||
          r.snapshot.eventCursor != before.eventCursor ||
          r.snapshot.positionMs != before.positionMs ||
          r.snapshot.desired != DesiredTransport.paused ||
          r.backend.consumers != 0 ||
          r.snapshot.tracks.isNotEmpty ||
          (r.backend.lastHost['samples'] as List? ?? []).isNotEmpty) {
        throw StateError('stale-authority-or-auto-resume');
      }
      proof['staleClaimRejected'] = rejected.failure!.code;
      proof['pausedObservationMs'] = 700;
      final ack = r.command('play');
      if (ack?.applied != true) {
        throw StateError('resume-rejected');
      }
      await _until(
        () =>
            runtime.snapshot.desired == DesiredTransport.playing &&
            runtime.snapshot.positionMs > before.positionMs + 300 &&
            runtime.snapshot.tracks.any(
              (t) =>
                  t.role == TrackRole.active &&
                  t.playbackConfirmationId != null,
            ) &&
            (runtime.backend.lastHost['samples'] as List? ?? []).any(
              (v) => v['nativePlaying'] == true,
            ),
      );
      proof['resumedPosition'] = r.snapshot.positionMs;
      proof['resumedConfirmations'] = r.snapshot.confirmations;
      proof['resumeHost'] = Map<String, dynamic>.of(r.backend.lastHost)
        ..remove('lifecycle');
      final confirmed = jsonEncode(r.snapshot.confirmations);
      final handle = r.snapshot.tracks.single.trackHandleId;
      r.command('pause');
      await _until(
        () => (runtime.backend.lastHost['samples'] as List? ?? []).any(
          (v) => v['id'] == handle && v['nativePlaying'] == false,
        ),
      );
      final pausedPosition = r.snapshot.positionMs;
      r.command('play');
      await _until(
        () =>
            runtime.snapshot.positionMs > pausedPosition + 300 &&
            (runtime.backend.lastHost['samples'] as List? ?? []).any(
              (v) => v['id'] == handle && v['nativePlaying'] == true,
            ),
      );
      if (jsonEncode(r.snapshot.confirmations) != confirmed ||
          r.snapshot.tracks.single.trackHandleId != handle) {
        throw StateError('repeat-resume-duplicated-confirmation');
      }
      proof['repeatResumeDeduplicated'] = true;
      final beforeStopHost = r.backend.lastHost;
      r.command('stop');
      await _until(
        () =>
            runtime.backend.consumers == 0 &&
            !identical(runtime.backend.lastHost, beforeStopHost) &&
            (runtime.backend.lastHost['samples'] as List? ?? []).isEmpty &&
            (!Platform.isAndroid ||
                runtime.backend.lastHost['servicePresent'] == false),
      );
      if (r.coordinator.failures.isNotEmpty) {
        throw StateError('recovery-backend-failure');
      }
      proof['stoppedConsumers'] = r.backend.consumers;
      proof['stopHost'] = Map<String, dynamic>.of(r.backend.lastHost)
        ..remove('lifecycle');
    }
    await _proof(proof);
    // Stay alive. The controller must kill us; no graceful stop/save callback.
  } catch (e) {
    await _proof({'stage': 'error', 'pid': pid, 'error': e.toString()});
  }
}

Future<void> _until(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw StateError('recovery-observation-timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> _proof(Map<String, dynamic> proof) async {
  if (Platform.isAndroid) {
    proof['probeToken'] = await NativeLocalBackend.channel.invokeMethod<String>(
      'launchToken',
    );
  }
  final json = jsonEncode(proof);
  final file = File('${Directory.systemTemp.path}/jj-owned-p1/proof-$pid.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(json, flush: true);
  if (Platform.isAndroid) {
    await NativeLocalBackend.channel.invokeMethod<void>('proof', {
      'json': json,
    });
  }
}
