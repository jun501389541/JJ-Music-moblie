import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import '../../integration_test/support/controlled_backend.dart';
import '../../integration_test/support/local_playback_contract.dart';

class GatedControls extends ControlledBackend {
  Completer<void>? gate;
  bool failSync = false;
  bool errorNext = false;
  @override
  Stream<BackendEvent> get events => super.events.transform(
    StreamTransformer.fromHandlers(
      handleData: (event, sink) {
        if (errorNext) {
          errorNext = false;
          sink.addError(StateError('stream-error'));
        } else {
          sink.add(event);
        }
      },
    ),
  );
  @override
  Future<void> pause() {
    if (failSync) throw StateError('pause');
    return gate?.future ?? super.pause();
  }
}

void main() {
  late GatedControls b;
  late PlaybackCoordinator c;
  final owners = <PlaybackCoordinator>[];
  CommandContext cmd(String id) => CommandContext(id, c.claim);
  setUp(() {
    owners.clear();
    b = GatedControls();
    c = PlaybackCoordinator(b);
    owners.add(c);
  });
  tearDown(() async {
    for (final owner in owners) {
      await owner.dispose();
    }
    await b.close();
  });
  Future<void> active() async {
    c.play(
      cmd('a'),
      PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureA.entryId),
    );
    b.ready('a', 'ha');
    await flushContractEvents();
    b.emit('a', 'ha', BackendEventKind.playing, 1);
    await flushContractEvents();
  }

  PlaybackCoordinator transfer() {
    final result = c.handoffSingleTrack(
      expectedClaim: c.claim,
      newOwner: 'next-owner',
    );
    expect(result.failure, isNull);
    final next = result.coordinator!;
    owners.add(next);
    return next;
  }

  for (final paused in [false, true]) {
    test(
      'new authority preserves one resource and confirmation paused=$paused',
      () async {
        await active();
        if (paused) {
          c.pause(cmd('pause'));
          await flushContractEvents();
        }
        final before = c.snapshot;
        final old = c;
        final oldClaim = c.claim;
        final actions = List.of(b.actions);
        c = transfer();
        expect(identical(c, old), isFalse);
        expect(identical(c.backend, old.backend), isTrue);
        expect(c.claim.coordinatorEpoch, oldClaim.coordinatorEpoch + 1);
        expect(c.snapshot.backendEpoch, before.backendEpoch);
        expect(c.snapshot.playbackGeneration, before.playbackGeneration);
        expect(c.snapshot.queueRevision, before.queueRevision);
        expect(c.snapshot.tracks.single.trackHandleId, 'ha');
        expect(c.snapshot.confirmations, before.confirmations);
        expect(c.snapshot.desired, before.desired);
        expect(old.stop(CommandContext('stale', oldClaim)).accepted, isFalse);
        expect(
          c.stop(CommandContext('also-stale', oldClaim)).accepted,
          isFalse,
        );
        expect(
          old
              .handoffSingleTrack(expectedClaim: oldClaim, newOwner: 'third')
              .failure,
          isNotNull,
        );
        old.revokeResource('ha');
        old.completeTransition('ha');
        await old.dispose();
        expect(b.actions, actions);
        final cursor = c.snapshot.eventCursor;
        b.emit('a', 'ha', BackendEventKind.playing, 1);
        expect(c.snapshot.eventCursor, cursor);
        b.emit('a', 'ha', BackendEventKind.playing, 2);
        expect(c.snapshot.confirmations, before.confirmations);
        expect(c.snapshot.eventCursor, cursor + (paused ? 0 : 1));
        b.emit('a', 'ha', BackendEventKind.progress, 3);
        expect(c.snapshot.eventCursor, cursor + (paused ? 1 : 2));
        expect(c.seek(cmd('seek'), 100).applied, isTrue);
        await flushContractEvents();
        c.stop(cmd('stop'));
        await flushContractEvents();
        expect(b.actions.where((v) => v == 'release:ha').length, 1);
      },
    );
  }
  test(
    'wrong claim and same owner reject without changing live authority',
    () async {
      await active();
      final claim = c.claim;
      expect(
        c
            .handoffSingleTrack(
              expectedClaim: ControllerClaim(
                claim.ownerId,
                claim.coordinatorEpoch + 1,
                claim.playbackSessionId,
              ),
              newOwner: 'next',
            )
            .failure,
        isNotNull,
      );
      expect(
        c
            .handoffSingleTrack(expectedClaim: claim, newOwner: claim.ownerId)
            .failure,
        isNotNull,
      );
      expect(c.pause(cmd('valid')).applied, isTrue);
    },
  );
  test('pending prepare and two live tracks reject', () async {
    await active();
    c.play(
      cmd('b'),
      PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureB.entryId),
    );
    expect(
      c.handoffSingleTrack(expectedClaim: c.claim, newOwner: 'next').failure,
      'handoff-busy',
    );
    b.ready('b', 'hb');
    await flushContractEvents();
    b.emit('b', 'hb', BackendEventKind.playing, 1);
    expect(
      c.handoffSingleTrack(expectedClaim: c.claim, newOwner: 'next').failure,
      'handoff-unsupported',
    );
  });
  test('inflight control rejects until failure callback finishes; sync throw does not leak', () async {
    await active();
    b.gate = Completer<void>();
    c.pause(cmd('pause'));
    expect(
      c.handoffSingleTrack(expectedClaim: c.claim, newOwner: 'next').failure,
      'handoff-busy',
    );
    b.gate!.completeError(StateError('async-pause'));
    await flushContractEvents();
    b.gate = null;
    b.failSync = true;
    c.pause(cmd('pause-sync'));
    await flushContractEvents();
    c = transfer();
  });
  test('released event does not bypass outstanding release Future', () async {
    await active();
    c.play(
      cmd('b'),
      PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureB.entryId),
    );
    b.ready('b', 'hb');
    await flushContractEvents();
    b.emit('b', 'hb', BackendEventKind.playing, 1);
    b.holdRelease = true;
    c.completeTransition('hb', transitionId: b.requests['b']!.transitionId);
    b.emit('a', 'ha', BackendEventKind.released, 2);
    expect(
      c.handoffSingleTrack(expectedClaim: c.claim, newOwner: 'next').failure,
      'handoff-busy',
    );
    b.releases['ha']!.complete(const ReleaseReceipt('ha', 'consumer-ha', 1));
    await flushContractEvents();
    b.holdRelease = false;
    c = transfer();
    expect(c.snapshot.tracks.single.trackHandleId, 'hb');
  });
  test('stop first cannot be revived by handoff', () async {
    await active();
    c.stop(cmd('stop'));
    await flushContractEvents();
    expect(
      c.handoffSingleTrack(expectedClaim: c.claim, newOwner: 'next').failure,
      'handoff-unsupported',
    );
  });

  test('route errors reach only new authority', () async {
    await active();
    final old = c;
    c = transfer();
    b.errorNext = true;
    b.emit('a', 'ha', BackendEventKind.progress, 2);
    expect(old.failures, isEmpty);
    expect(c.failures.single.code, 'backend-stream');
    b.emit('a', 'ha', BackendEventKind.playing, 3);
    expect(c.snapshot.confirmations.length, 1);
  });
  for (final newFirst in [false, true]) {
    test('dispose live new owner releases once, newFirst=$newFirst', () async {
      await active();
      final old = c;
      c = transfer();
      if (newFirst) {
        await c.dispose();
        await old.dispose();
      } else {
        await old.dispose();
        expect(b.actions.where((a) => a == 'release:ha'), isEmpty);
        await c.dispose();
      }
      await flushContractEvents();
      expect(b.actions.where((a) => a == 'release:ha').length, 1);
      b.emit('a', 'ha', BackendEventKind.playing, 2);
      expect(c.stop(cmd('closed-stop')).accepted, isFalse);
    });
  }
}
