import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import '../../integration_test/support/controlled_backend.dart';
import '../../integration_test/support/local_playback_contract.dart';

void main() {
  for (final capability in [false, null]) {
    for (final phase in ['pending', 'incoming', 'outgoing']) {
      test('rejected seek $capability preserves $phase transition', () async {
        final b = ControlledBackend();
        final c = PlaybackCoordinator(b);
        CommandContext cmd(String id) => CommandContext(id, c.claim);
        PlayIntent intent(QueueEntry e) =>
            PlayIntent(entries: [fixtureA, fixtureB], entryId: e.entryId);
        try {
          c.play(cmd('a'), intent(fixtureA));
          b.ready('a', 'ha', canSeek: capability);
          await flushContractEvents();
          b.emit('a', 'ha', BackendEventKind.playing, 1);
          c.play(cmd('b'), intent(fixtureB));
          if (phase != 'pending') {
            b.ready('b', 'hb', canSeek: capability);
            await flushContractEvents();
          }
          if (phase == 'outgoing') {
            b.emit('b', 'hb', BackendEventKind.playing, 1);
          }
          final before = c.snapshot;
          expect(
            before.currentEntryId,
            phase == 'outgoing' ? fixtureB.entryId : fixtureA.entryId,
          );
          expect(
            before.tracks.firstWhere((t) => t.trackHandleId == 'ha').role,
            phase == 'outgoing' ? TrackRole.outgoing : TrackRole.active,
          );
          if (phase != 'pending') {
            expect(
              before.tracks.firstWhere((t) => t.trackHandleId == 'hb').role,
              phase == 'outgoing' ? TrackRole.active : TrackRole.incoming,
            );
          }
          final actions = List.of(b.actions);
          final roles = before.tracks
              .map((t) => '${t.trackHandleId}:${t.role}')
              .toList();
          final ack = c.seek(cmd('rejected'), 9000);
          expect(ack.accepted, isFalse);
          expect(ack.applied, isFalse);
          expect(
            ack.failure?.code,
            capability == false
                ? 'seek-unsupported'
                : 'seek-capability-unknown',
          );
          await flushContractEvents();
          expect(
            b.actions,
            actions,
            reason: 'No seek, cancel, release, or resume may be dispatched',
          );
          expect(c.snapshot.playbackGeneration, before.playbackGeneration);
          expect(c.snapshot.positionMs, before.positionMs);
          expect(c.snapshot.confirmations, before.confirmations);
          expect(
            c.snapshot.tracks
                .map((t) => '${t.trackHandleId}:${t.role}')
                .toList(),
            roles,
          );
          if (phase == 'pending') {
            expect(b.pending['b']!.isCompleted, isFalse);
            b.ready('b', 'hb', canSeek: capability);
            await flushContractEvents();
          }
          if (phase != 'outgoing') {
            b.emit('b', 'hb', BackendEventKind.playing, 1);
          }
          expect(
            c.snapshot.currentEntryId,
            fixtureB.entryId,
            reason: 'The original incoming request must still be valid',
          );
          expect(c.snapshot.confirmations.length, 2);
          expect(
            b.actions,
            isNot(contains('release:ha')),
            reason: 'Incoming confirmation alone must not release outgoing',
          );
          expect(b.actions, isNot(contains('release:hb')));
          c.completeTransition(
            'hb',
            transitionId: b.requests['b']!.transitionId,
          );
          await flushContractEvents();
          expect(b.actions.where((a) => a == 'release:ha'), hasLength(1));
          expect(b.actions, isNot(contains('release:hb')));
          expect(c.failures, isEmpty);
        } finally {
          await c.dispose();
          await b.close();
        }
      });
    }
  }
}
