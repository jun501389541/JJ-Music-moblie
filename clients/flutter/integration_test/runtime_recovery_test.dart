import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';

import 'package:jj_music_mobile/domain/playback/contracts.dart';

import 'windows_local_playback_test.dart' show until;

class _Subscriber extends StatefulWidget {
  const _Subscriber(this.runtime, {super.key});
  final LocalRuntime runtime;
  @override
  State<_Subscriber> createState() => _SubscriberState();
}

class _SubscriberState extends State<_Subscriber> {
  @override
  void initState() {
    super.initState();
    widget.runtime.reconnect();
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.runtime.snapshot.playbackSessionId);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'R1 widget replacement, exclusive ownership, native destruction and paused resume',
    (tester) async {
      final r = await LocalRuntime.create(runId: 'runtime-$pid');
      try {
        r.command('a');
        await until(() => r.snapshot.currentEntryId == ownedA.entryId);
        final first = r.snapshot;
        await tester.pumpWidget(
          MaterialApp(home: _Subscriber(r, key: const ValueKey(1))),
        );
        await tester.pumpWidget(
          MaterialApp(home: _Subscriber(r, key: const ValueKey(2))),
        );
        expect(r.snapshot.playbackSessionId, first.playbackSessionId);
        expect(
          r.snapshot.tracks.single.trackHandleId,
          first.tracks.single.trackHandleId,
        );
        expect(r.snapshot.confirmations, first.confirmations);
        final stale = r.coordinator.claim;
        final next = r.coordinator.acquireController(
          expectedOwner: stale.ownerId,
          newOwner: 'reconnected-owner',
        );
        expect(next, isNotNull);
        expect(
          r.coordinator.pause(CommandContext('stale', stale)).accepted,
          isFalse,
        );
        expect(
          r.snapshot.tracks.single.trackHandleId,
          first.tracks.single.trackHandleId,
        );
        r.command('pause');
        final before = r.snapshot;
        await r.destroyBackend();
        expect(r.snapshot.backendEpoch, before.backendEpoch + 1);
        expect(r.snapshot.coordinatorEpoch, before.coordinatorEpoch);
        expect(r.snapshot.brokerEpoch, before.brokerEpoch);
        expect(r.backend.consumers, 0);
        expect(r.snapshot.desired, DesiredTransport.paused);
        r.command('play');
        await until(
          () => r.snapshot.tracks.any((t) => t.role == TrackRole.active),
        );
        expect(
          r.snapshot.tracks.last.trackHandleId,
          isNot(first.tracks.single.trackHandleId),
        );
        r.command('stop');
        await until(() => r.backend.consumers == 0);
        // ignore: avoid_print
        print(
          'RUNTIME_RECOVERY=${jsonEncode({'platform': Platform.operatingSystem, 'pid': pid, 'oldHandle': first.tracks.single.trackHandleId, 'coordinatorEpoch': r.snapshot.coordinatorEpoch, 'backendEpoch': r.snapshot.backendEpoch, 'confirmations': r.snapshot.confirmations})}',
        );
      } finally {
        await r.close();
      }
    },
  );
}
