import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app/runtime/local_runtime.dart';
import 'data/prototype_recovery/file_snapshot_store.dart';
import 'domain/playback/contracts.dart';
import 'domain/playback/recovery_snapshot.dart';
import 'platform/local/native_local_backend.dart';

const _cases = {
  'missing',
  'corrupt',
  'unknown-version',
  'unavailable-fixture',
  'partial-temp',
  'corrupt-newest',
};

/// Explicit fixture-only entrypoint. The controller kills seed, then starts a
/// distinct check process. No call to play/prepare or production data access.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(home: Scaffold(body: Text('P1 snapshot fault probe'))),
  );
  try {
    const base = String.fromEnvironment('P1_RUN_ID');
    final mode = Platform.isAndroid
        ? await NativeLocalBackend.channel.invokeMethod<String>('launchMode')
        : args.firstOrNull;
    if (base.isEmpty || mode == null) {
      throw StateError('explicit-run-id-and-mode-required');
    }
    final seed = mode.startsWith('seed-');
    final check = mode.startsWith('check-');
    final scenario = mode.substring(
      seed
          ? 5
          : check
          ? 6
          : mode.length,
    );
    if ((!seed && !check) || !_cases.contains(scenario)) {
      throw StateError('unknown-fault-scenario');
    }
    final runId = '$base-$scenario';
    final store = FileSnapshotStore(
      root: Directory('${Directory.systemTemp.path}/jj-owned-p1/recovery'),
      runId: runId,
      allowedFixtureIds: {'tone-long'},
    );
    final receipts = <int>[];
    if (seed) {
      if (await store.directory.exists()) {
        throw StateError('run-id-already-used');
      }
      await store.directory.create(recursive: true);
      if (scenario != 'missing') {
        for (final revision in [1, 2]) {
          final saved = await store.save(_snapshot(runId, revision));
          if (saved.runId != runId || saved.revision != revision) {
            throw StateError('save-receipt-mismatch');
          }
          receipts.add(saved.revision);
        }
        for (final slot in ['snapshot-a.json', 'snapshot-b.json']) {
          final file = File('${store.directory.path}/$slot');
          if (scenario == 'corrupt' ||
              (scenario == 'corrupt-newest' && slot == 'snapshot-a.json')) {
            await file.writeAsString('{partial', flush: true);
          } else if (scenario == 'unknown-version' ||
              scenario == 'unavailable-fixture') {
            final value =
                jsonDecode(await file.readAsString()) as Map<String, dynamic>;
            if (scenario == 'unknown-version') {
              value['formatVersion'] = 99;
            } else {
              (value['entries'] as List).first['fixtureId'] = 'not-owned';
            }
            await file.writeAsString(jsonEncode(value), flush: true);
          }
        }
        if (scenario == 'partial-temp' || scenario == 'corrupt-newest') {
          // Controlled abandoned-write fixture, not an interrupted save Future
          // or a guarantee about OS/filesystem power-loss behavior.
          await File('${store.directory.path}/snapshot-b.json.tmp')
              .writeAsString('{unfinished-revision-3', flush: true);
        }
      }
      await _proof({
        'stage': 'seeded',
        'scenario': scenario,
        'runId': runId,
        'directory': store.directory.path,
        'savedReceipts': receipts,
        'files': await _files(store.directory),
      });
      return; // Flutter engine remains live until controller force-kills it.
    }

    final before = await _files(store.directory);
    final runtime = await LocalRuntime.create(runId: runId);
    final loaded = await runtime.store.load();
    final revision = switch (scenario) {
      'partial-temp' => 2,
      'corrupt-newest' => 1,
      _ => null,
    };
    final initial = runtime.snapshot;
    Map<String, Object?>? actual;
    if (revision != null) {
      actual = RecoverySnapshot(
        runId: runId,
        revision: runtime.savedRevision,
        playbackSessionId: initial.playbackSessionId,
        entries: initial.entries,
        currentIndex: initial.entries.indexWhere(
          (e) => e.entryId == initial.currentEntryId,
        ),
        positionMs: initial.positionMs,
        mode: initial.mode,
        preview: initial.preview,
        confirmations: initial.confirmations,
      ).toJson();
      if (jsonEncode(actual) !=
              jsonEncode(_snapshot(runId, revision).toJson()) ||
          jsonEncode(actual) != jsonEncode(loaded.snapshot?.toJson()) ||
          initial.desired != DesiredTransport.paused) {
        throw StateError('last-valid-runtime-mismatch');
      }
    } else if (loaded.snapshot != null ||
        runtime.savedRevision != 0 ||
        initial.entries.isNotEmpty ||
        initial.currentEntryId != null ||
        initial.confirmations.isNotEmpty ||
        initial.positionMs != 0 ||
        initial.desired != DesiredTransport.stopped) {
      throw StateError('unsafe-empty-fallback');
    }
    if (scenario != 'missing' &&
        scenario != 'partial-temp' &&
        loaded.issues.isEmpty) {
      throw StateError('invalid-slot-not-diagnosed');
    }
    final observations = <Map<String, Object?>>[];
    Map<String, dynamic>? previousHost;
    final deadline = DateTime.now().add(const Duration(milliseconds: 700));
    while (DateTime.now().isBefore(deadline)) {
      final observed = runtime.backend.lastHost;
      if (!identical(observed, previousHost) &&
          observed.containsKey('samples')) {
        observations.add({
          'samples': observed['samples'],
          'servicePresent': observed['servicePresent'],
          'focusHeld': observed['focusHeld'],
        });
        previousHost = observed;
      }
      if (runtime.backend.consumers != 0 ||
          runtime.snapshot.tracks.isNotEmpty) {
        throw StateError('fallback-allocated-shared-resource');
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    final after = runtime.snapshot;
    final host = runtime.backend.lastHost;
    if (after.eventCursor != initial.eventCursor ||
        after.positionMs != initial.positionMs ||
        after.desired != initial.desired ||
        runtime.backend.consumers != 0 ||
        after.tracks.isNotEmpty ||
        observations.length < 3 ||
        observations.any(
          (v) =>
              (v['samples'] as List).isNotEmpty ||
              (Platform.isAndroid &&
                  (v['servicePresent'] != false || v['focusHeld'] != false)),
        ) ||
        runtime.backend.raw.any(
          (v) => v.containsKey('bridgeError') || v.containsKey('id'),
        ) ||
        !host.containsKey('samples') ||
        (host['samples'] as List).isNotEmpty ||
        (Platform.isAndroid &&
            (host['servicePresent'] != false || host['focusHeld'] != false)) ||
        runtime.coordinator.failures.isNotEmpty ||
        jsonEncode(before) != jsonEncode(await _files(store.directory))) {
      throw StateError('fallback-mutated-or-allocated-resources');
    }
    await _proof({
      'stage': 'checked',
      'scenario': scenario,
      'runId': runId,
      'directory': runtime.store.directory.path,
      'coordinatorEpoch': after.coordinatorEpoch,
      'revision': runtime.savedRevision,
      'desired': after.desired.name,
      'position': after.positionMs,
      'snapshot': actual,
      'issues': loaded.issues,
      'consumers': runtime.backend.consumers,
      'nativeSamples': host['samples'],
      'servicePresent': host['servicePresent'],
      'focusHeld': host['focusHeld'],
      'observationMs': 700,
      'freshNativePolls': observations.length,
      'bridgeErrors': 0,
      'files': before,
    });
  } catch (error) {
    await _proof({'stage': 'error', 'error': error.toString()});
  }
}

RecoverySnapshot _snapshot(String runId, int revision) => RecoverySnapshot(
  runId: runId,
  revision: revision,
  playbackSessionId: 'session-$runId',
  entries: [ownedA, ownedB],
  currentIndex: revision.isOdd ? 1 : 0,
  positionMs: revision.isOdd ? 1234 : 2345,
  confirmations: ['fixture-confirmation:1'],
);

Future<Map<String, String>> _files(Directory directory) async {
  final result = <String, String>{};
  for (final name in [
    'snapshot-a.json',
    'snapshot-b.json',
    'snapshot-b.json.tmp',
  ]) {
    final file = File('${directory.path}/$name');
    if (await file.exists()) {
      result[name] = await file.readAsString();
    }
  }
  return result;
}

Future<void> _proof(Map<String, dynamic> value) async {
  value['pid'] = pid;
  if (Platform.isAndroid) {
    value['probeToken'] = await NativeLocalBackend.channel.invokeMethod<String>(
      'launchToken',
    );
  }
  final json = jsonEncode(value);
  if (utf8.encode(json).length > 3500) {
    throw StateError('probe-receipt-too-large');
  }
  final file = File('${Directory.systemTemp.path}/jj-owned-p1/proof-$pid.json');
  await file.parent.create(recursive: true);
  await File('${file.path}.tmp').writeAsString(json, flush: true);
  await File('${file.path}.tmp').rename(file.path);
  if (Platform.isAndroid) {
    await NativeLocalBackend.channel.invokeMethod<void>('proof', {
      'json': json,
    });
  }
}
