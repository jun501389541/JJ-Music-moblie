import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app/runtime/local_runtime.dart';
import 'domain/playback/contracts.dart';
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
    r = await LocalRuntime.create(runId: 'process-proof');
    if (mode == 'save') {
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
    };
    await _proof(proof);
    // Stay alive. The controller must kill us; no graceful stop/save callback.
  } catch (e) {
    await _proof({'stage': 'error', 'pid': pid, 'error': e.toString()});
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
