import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import '../../integration_test/support/controlled_backend.dart';
import '../../integration_test/support/local_playback_contract.dart';

void main() {
  late ControlledBackend b;
  late PlaybackCoordinator c;
  CommandContext cmd(String id) => CommandContext(id, c.claim);
  PlayIntent intent(QueueEntry e) =>
      PlayIntent(entries: [fixtureA, fixtureB], entryId: e.entryId);
  setUp(() {
    b = ControlledBackend();
    c = PlaybackCoordinator(b);
  });
  tearDown(() async {
    await c.dispose();
    await b.close();
  });
  Future<void> prepareA() async {
    c.play(cmd('a'), intent(fixtureA));
    b.ready('a', 'ha');
    await flushContractEvents();
  }

  test(
    'superseding a ready but unconfirmed prepare releases its consumer',
    () async {
      await prepareA();
      c.play(cmd('b'), intent(fixtureB));
      await flushContractEvents();
      expect(b.actions, contains('release:ha'));
    },
  );
  test(
    'cancel after prepare but before confirmation cannot later commit playing',
    () async {
      await prepareA();
      c.cancel(cmd('cancel'), 'a');
      b.emit('a', 'ha', BackendEventKind.playing, 1);
      await flushContractEvents();
      expect(c.snapshot.confirmations, isEmpty);
      expect(b.actions, contains('release:ha'));
    },
  );
  test('pause and resume keep one confirmation even when play Future stays pending', () async {
    b.holdPlay = true;
    await prepareA();
    b.emit('a', 'ha', BackendEventKind.playing, 1);
    c.pause(cmd('pause'));
    expect(c.resume(cmd('resume')).applied, isTrue);
    b.emit('a', 'ha', BackendEventKind.playing, 2);
    expect(c.snapshot.confirmations.length, 1);
    expect(b.playing.isCompleted, isFalse);
    expect(c.stop(cmd('stop')).applied, isTrue);
    expect(b.actions, contains('stop'));
  });
  test(
    'authority CAS rejects old owner and invalidates its pending completion',
    () async {
      final old = c.claim;
      c.play(cmd('a'), intent(fixtureA));
      expect(
        c.acquireController(expectedOwner: 'wrong', newOwner: 'owner-2'),
        isNull,
      );
      expect(
        c.acquireController(expectedOwner: old.ownerId, newOwner: 'owner-2'),
        isNotNull,
      );
      expect(c.stop(CommandContext('stale', old)).accepted, isFalse);
      b.ready('a', 'late');
      await flushContractEvents();
      expect(b.actions, isNot(contains('play:late')));
      expect(b.actions, contains('release:late'));
    },
  );
  test(
    'R1 UI reconnect does not reload handles or change epochs and confirmation',
    () async {
      await prepareA();
      b.emit('a', 'ha', BackendEventKind.playing, 1);
      final before = c.snapshot;
      final actions = b.actions.length;
      final after = c.attachUi('ui-new');
      expect(after.coordinatorEpoch, before.coordinatorEpoch);
      expect(after.backendEpoch, before.backendEpoch);
      expect(after.confirmations, before.confirmations);
      expect(b.actions.length, actions);
    },
  );
  test('queue revision conflicts and same request id with changed payload are rejected', () async {
    await prepareA();
    expect(c.replaceQueue(cmd('conflict'), [fixtureA], 999).accepted, isFalse);
    expect(c.replaceQueue(cmd('q'), [fixtureA, fixtureB], 1).applied, isTrue);
    const changed = QueueEntry(
      entryId: 'occurrence-a',
      trackKey: 'other',
      fixtureId: 'tone-a',
    );
    expect(c.replaceQueue(cmd('q'), [changed, fixtureB], 1).accepted, isFalse);
  });
  test('two live tracks forbid a third and old outgoing release still works across generations', () async {
    await prepareA();
    b.emit('a', 'ha', BackendEventKind.playing, 1);
    c.play(cmd('b'), intent(fixtureB));
    b.ready('b', 'hb');
    await flushContractEvents();
    b.emit('b', 'hb', BackendEventKind.playing, 1);
    expect(c.play(cmd('third'), intent(fixtureA)).accepted, isFalse);
    b.emit('a', 'ha', BackendEventKind.released, 2);
    expect(c.snapshot.tracks.first.role, TrackRole.released);
    expect(c.snapshot.currentEntryId, 'occurrence-b');
  });
  test(
    'revocation wins over rollback without erasing already confirmed history',
    () async {
      await prepareA();
      b.emit('a', 'ha', BackendEventKind.playing, 1);
      c.play(cmd('b'), intent(fixtureB));
      b.ready('b', 'hb');
      await flushContractEvents();
      b.emit('b', 'hb', BackendEventKind.playing, 1);
      c.revokeResource('ha');
      b.emit('b', 'hb', BackendEventKind.error, 2);
      await flushContractEvents();
      expect(c.snapshot.currentEntryId, isNull);
      expect(c.snapshot.desired, DesiredTransport.paused);
      expect(c.snapshot.confirmations.length, 2);
    },
  );
  test(
    'TC-08 stale transition completion cannot release a valid outgoing track',
    () async {
      await prepareA();
      b.emit('a', 'ha', BackendEventKind.playing, 1);
      c.play(cmd('b'), intent(fixtureB));
      b.ready('b', 'hb');
      await flushContractEvents();
      b.emit('b', 'hb', BackendEventKind.playing, 1);
      c.completeTransition('hb', transitionId: 'stale-transition');
      expect(b.actions, isNot(contains('release:ha')));
      expect(b.requests['b']!.transitionId, isNotNull);
      c.completeTransition('hb', transitionId: b.requests['b']!.transitionId);
      await flushContractEvents();
      expect(b.actions, contains('release:ha'));
    },
  );
  test(
    'TC-31 preview natural end stops without changing the selected mode',
    () async {
      c.play(
        cmd('preview'),
        PlayIntent(
          entries: [fixtureA],
          entryId: fixtureA.entryId,
          preview: true,
          mode: PlaybackMode.repeatOne,
        ),
      );
      b.ready('preview', 'preview-handle');
      await flushContractEvents();
      b.emit('preview', 'preview-handle', BackendEventKind.playing, 1);
      b.emit('preview', 'preview-handle', BackendEventKind.ended, 2);
      expect(c.snapshot.desired, DesiredTransport.stopped);
      expect(c.snapshot.mode, PlaybackMode.repeatOne);
      expect(c.snapshot.preview, isTrue);
    },
  );
  test(
    'removing a pending entry fences and releases its later completion',
    () async {
      c.play(cmd('a'), intent(fixtureA));
      expect(c.replaceQueue(cmd('replace'), [fixtureB], 1).applied, isTrue);
      b.ready('a', 'removed');
      await flushContractEvents();
      b.emit('a', 'removed', BackendEventKind.playing, 1);
      expect(c.snapshot.currentEntryId, isNull);
      expect(b.actions, contains('release:removed'));
    },
  );
  test(
    'late retiring allocation reserves a slot before the next prepare',
    () async {
      await prepareA();
      b.emit('a', 'ha', BackendEventKind.playing, 1);
      c.play(cmd('b'), intent(fixtureB));
      expect(c.play(cmd('c'), intent(fixtureA)).applied, isTrue);
      b.holdRelease = true;
      b.ready('b', 'late-b');
      await flushContractEvents();
      expect(
        c.snapshot.tracks.where((t) => t.role != TrackRole.released).length,
        2,
      );
      expect(b.requests.containsKey('c'), isFalse);
      b.releases['late-b']!.complete(
        const ReleaseReceipt('late-b', 'consumer-late-b', 1),
      );
      await flushContractEvents();
      expect(b.requests.containsKey('c'), isTrue);
      b.ready('c', 'hc');
      await flushContractEvents();
      expect(
        c.snapshot.tracks.where((t) => t.role != TrackRole.released).length,
        2,
      );
      b.holdRelease = false;
    },
  );
  test('first confirmation is independent from transition policy', () async {
    await prepareA();
    b.emit('a', 'ha', BackendEventKind.playing, 1);
    c.play(cmd('b'), intent(fixtureB));
    b.ready('b', 'hb');
    await flushContractEvents();
    b.emit(
      'b',
      'hb',
      BackendEventKind.playing,
      1,
      transitionId: 'wrong-transition',
    );
    expect(c.snapshot.currentEntryId, 'occurrence-a');
    expect(c.snapshot.confirmations.length, 2);
    b.emit('b', 'hb', BackendEventKind.playing, 2);
    expect(c.snapshot.currentEntryId, 'occurrence-b');
    expect(c.snapshot.confirmations.length, 2);
  });
  test('cancel waiting intent removes its capacity deadline without dispatching an unknown prepare', () async {
    await c.dispose();
    c = PlaybackCoordinator(
      b,
      releaseTimeout: const Duration(milliseconds: 20),
    );
    await prepareA();
    b.emit('a', 'ha', BackendEventKind.playing, 1);
    c.play(cmd('b'), intent(fixtureB));
    c.play(cmd('c'), intent(fixtureA));
    c.cancel(cmd('cancel-c'), 'c');
    expect(b.actions, isNot(contains('cancel:c')));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.failures, isEmpty);
  });
}
