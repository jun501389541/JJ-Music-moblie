import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/domain/playback/recovery_snapshot.dart';

import '../../integration_test/support/controlled_backend.dart';

void main() {
  test(
    'valid empty persisted snapshot restores safe paused empty state',
    () async {
      final b = ControlledBackend();
      final c = PlaybackCoordinator(b, sessionId: 'empty');
      c.restoreSnapshot(
        RecoverySnapshot(
          runId: 'owned',
          revision: 1,
          playbackSessionId: 'empty',
          entries: [],
          currentIndex: -1,
        ),
      );
      expect(c.snapshot.entries, isEmpty);
      expect(c.snapshot.desired, DesiredTransport.paused);
      expect(b.actions, isEmpty);
      await c.dispose();
      await b.close();
    },
  );
  test('confirmed backend destruction advances only backend epoch and rejects stale events', () async {
    final b = ControlledBackend();
    final c = PlaybackCoordinator(b);
    const e = QueueEntry(entryId: 'a', trackKey: 'owned', fixtureId: 'tone-a');
    c.play(
      CommandContext('p', c.claim),
      PlayIntent(entries: [e], entryId: 'a'),
    );
    b.ready('p', 'h');
    await Future<void>.delayed(Duration.zero);
    b.emit('p', 'h', BackendEventKind.playing, 1);
    final before = c.snapshot;
    expect(
      c.backendReleased(CommandContext('lost', c.claim), [
        const ReleaseReceipt('h', 'consumer-h', 1),
      ]).applied,
      isTrue,
    );
    expect(c.snapshot.backendEpoch, before.backendEpoch + 1);
    expect(c.snapshot.coordinatorEpoch, before.coordinatorEpoch);
    expect(c.snapshot.brokerEpoch, before.brokerEpoch);
    expect(c.snapshot.desired, DesiredTransport.paused);
    b.emit('p', 'h', BackendEventKind.ended, 9);
    expect(c.snapshot.confirmations.length, 1);
    await c.dispose();
    await b.close();
  });
  test('R3 restore stays paused without native handles and resumes at saved position', () async {
    final b = ControlledBackend();
    final c = PlaybackCoordinator(b, sessionId: 'logical');
    const e = QueueEntry(
      entryId: 'saved',
      trackKey: 'owned',
      fixtureId: 'tone-a',
    );
    final s = RecoverySnapshot(
      runId: 'owned',
      revision: 2,
      playbackSessionId: 'logical',
      entries: [e],
      currentIndex: 0,
      positionMs: 2345,
      confirmations: ['logical:4'],
    );
    // This callable is introduced as an A02-owned additive v2 recovery extension.
    c.restoreSnapshot(s);
    expect(c.snapshot.desired, DesiredTransport.paused);
    expect(c.snapshot.positionMs, 2345);
    expect(c.snapshot.currentEntryId, 'saved');
    expect(b.actions, isEmpty);
    c.resume(CommandContext('resume', c.claim));
    expect(c.resume(CommandContext('resume', c.claim)).applied, isTrue);
    expect(b.pending.values, isNotEmpty);
    expect(b.requests.values.single.startPositionMs, 2345);
    await c.dispose();
    await b.close();
  });
}
