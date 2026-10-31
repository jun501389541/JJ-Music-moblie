import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import 'controlled_backend.dart';

const fixtureA = QueueEntry(
  entryId: 'occurrence-a',
  trackKey: 'tone',
  fixtureId: 'tone-a',
);
const fixtureB = QueueEntry(
  entryId: 'occurrence-b',
  trackKey: 'tone',
  fixtureId: 'tone-a',
);
Future<void> flushContractEvents() => Future<void>.delayed(Duration.zero);

/// Reusable postconditions: future real adapters import these without reusing the fake.
void expectControlApplied(CommandAck ack) {
  expect(ack.accepted, isTrue);
  expect(ack.applied, isTrue);
  expect(ack.failure, isNull);
}

void expectConfirmedIdentity(
  PlaybackSnapshot state,
  String entryId,
  int count,
) {
  expect(state.currentEntryId, entryId);
  expect(state.confirmations.length, count);
  expect(state.confirmations.toSet().length, count);
}

/// Shared assertions for A02. Platform adapters consume the frozen contract later.
void registerLocalPlaybackContract() {
  late ControlledBackend backend;
  late PlaybackCoordinator coordinator;
  CommandContext command(String id) => CommandContext(id, coordinator.claim);
  PlayIntent intent(QueueEntry entry) =>
      PlayIntent(entries: [fixtureA, fixtureB], entryId: entry.entryId);
  setUp(() {
    backend = ControlledBackend();
    coordinator = PlaybackCoordinator(backend);
  });
  tearDown(() async {
    await coordinator.dispose();
    await backend.close();
  });

  for (final control in ['stop', 'pause', 'cancel', 'new-play']) {
    test(
      'TC-56 $control is dispatched before an old prepare Future completes',
      () async {
        coordinator.play(command('old'), intent(fixtureA));
        final ack = switch (control) {
          'stop' => coordinator.stop(command('control')),
          'pause' => coordinator.pause(command('control')),
          'cancel' => coordinator.cancel(command('control'), 'old'),
          _ => coordinator.play(command('new'), intent(fixtureB)),
        };
        expectControlApplied(ack);
        expect(backend.pending['old']!.isCompleted, isFalse);
        expect(
          backend.actions,
          contains(switch (control) {
            'new-play' => 'prepare:new',
            'cancel' => 'cancel:old',
            _ => control,
          }),
        );
        backend.ready('old', 'late-handle');
        await flushContractEvents();
        if (control != 'pause') {
          expect(backend.actions, isNot(contains('play:late-handle')));
        }
        if (control == 'pause') {
          expect(coordinator.snapshot.desired, DesiredTransport.paused);
          expect(backend.actions, isNot(contains('play:late-handle')));
        }
        expect(coordinator.snapshot.confirmations, isEmpty);
      },
    );
  }
  test('TC-57 raw playing, ready and buffering do not confirm; normalized confirmation deduplicates', () async {
    coordinator.play(command('p'), intent(fixtureA));
    backend.ready('p', 'a');
    await flushContractEvents();
    backend.emit('p', 'a', BackendEventKind.ready, 1);
    backend.emit('p', 'a', BackendEventKind.buffering, 2);
    backend.emit('p', 'a', BackendEventKind.playing, 3, evidence: null);
    expect(coordinator.snapshot.confirmations, isEmpty);
    backend.emit('p', 'a', BackendEventKind.playing, 4);
    backend.emit('p', 'a', BackendEventKind.playing, 5);
    expect(coordinator.snapshot.confirmations.length, 1);
    expect(coordinator.snapshot.currentEntryId, 'occurrence-a');
    expect(coordinator.snapshot.durationMs, isNull);
  });
  test('TC-03/32 stale epoch, generation and duplicate events never commit identity', () async {
    coordinator.play(command('p'), intent(fixtureA));
    backend.ready('p', 'a');
    await flushContractEvents();
    backend.emit('p', 'a', BackendEventKind.playing, 1, epoch: 99);
    backend.emit('p', 'a', BackendEventKind.playing, 2, generation: 99);
    expect(coordinator.snapshot.currentEntryId, isNull);
    backend.emit('p', 'a', BackendEventKind.playing, 3);
    backend.emit('p', 'a', BackendEventKind.error, 2);
    expect(coordinator.snapshot.currentEntryId, 'occurrence-a');
    expect(coordinator.snapshot.confirmations.length, 1);
  });
  test('TC-06/07 incoming failure preserves outgoing resource and rollback retains confirmed history', () async {
    coordinator.play(command('p'), intent(fixtureA));
    backend.ready('p', 'a');
    await flushContractEvents();
    backend.emit('p', 'a', BackendEventKind.playing, 1);
    coordinator.play(command('q'), intent(fixtureB));
    backend.ready('q', 'b');
    await flushContractEvents();
    expect(coordinator.snapshot.currentEntryId, 'occurrence-a');
    backend.emit('q', 'b', BackendEventKind.playing, 1);
    expect(coordinator.snapshot.currentEntryId, 'occurrence-b');
    expect(backend.actions, isNot(contains('release:a')));
    backend.emit('q', 'b', BackendEventKind.error, 2);
    await flushContractEvents();
    expect(coordinator.snapshot.currentEntryId, 'occurrence-a');
    expect(coordinator.snapshot.confirmations.length, 2);
  });
  test(
    'TC-09 stop applied is separate from physical release receipt',
    () async {
      backend.holdRelease = true;
      coordinator.play(command('p'), intent(fixtureA));
      backend.ready('p', 'a');
      await flushContractEvents();
      backend.emit('p', 'a', BackendEventKind.playing, 1);
      expect(coordinator.stop(command('s')).applied, isTrue);
      expect(coordinator.snapshot.tracks.single.role, TrackRole.retiring);
      backend.releases['a']!.complete(
        const ReleaseReceipt('a', 'consumer-a', 1),
      );
      await flushContractEvents();
      expect(coordinator.snapshot.tracks.single.role, TrackRole.released);
    },
  );
}
