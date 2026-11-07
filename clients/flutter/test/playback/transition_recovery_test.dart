import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import '../../integration_test/support/controlled_backend.dart';
import '../../integration_test/support/local_playback_contract.dart';

void main() {
  late ControlledBackend b;
  late PlaybackCoordinator c;
  CommandContext cmd(String id) => CommandContext(id, c.claim);
  setUp(() {
    b = ControlledBackend();
    c = PlaybackCoordinator(b);
  });
  tearDown(() async {
    await c.dispose();
    await flushContractEvents();
    await b.close();
  });
  Future<void> setup({bool ready = true}) async {
    c.play(
      cmd('a'),
      PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureA.entryId),
    );
    b.ready('a', 'ha');
    await flushContractEvents();
    b.emit('a', 'ha', BackendEventKind.playing, 1);
    c.play(
      cmd('b'),
      PlayIntent(entries: [fixtureA, fixtureB], entryId: fixtureB.entryId),
    );
    if (ready) {
      b.ready('b', 'hb');
      await flushContractEvents();
    }
  }

  for (final remainPaused in [false, true]) {
    test(
      'pending B failure restores A only if resumed remainPaused=$remainPaused',
      () async {
        await setup(ready: false);
        c.pause(cmd('pause'));
        if (!remainPaused) c.resume(cmd('resume'));
        final start = b.actions.length;
        b.pending['b']!.completeError(StateError('owned-prepare-failure'));
        await flushContractEvents();
        expect(b.actions.skip(start).contains('play:ha'), !remainPaused);
        expect(
          c.snapshot.desired,
          remainPaused ? DesiredTransport.paused : DesiredTransport.playing,
        );
        expect(c.snapshot.requestedEntryId, fixtureA.entryId);
        expect(c.snapshot.confirmations.length, 1);
      },
    );
  }

  for (final action in ['seek', 'remove']) {
    for (final paused in [false, true]) {
      test(
        'GR01 $action rolls back only with playing intent paused=$paused',
        () async {
          await setup();
          if (paused) c.pause(cmd('pause'));
          final start = b.actions.length;
          if (action == 'seek') {
            expect(c.seek(cmd('seek'), 3000).applied, isTrue);
          } else {
            expect(
              c.replaceQueue(cmd('remove'), [
                fixtureA,
              ], c.snapshot.queueRevision).applied,
              isTrue,
            );
          }
          await flushContractEvents();
          final actions = b.actions.skip(start).toList();
          expect(actions, contains('release:hb'));
          expect(actions.contains('play:ha'), !paused);
          expect(c.snapshot.requestedEntryId, fixtureA.entryId);
          b.emit('b', 'hb', BackendEventKind.playing, 1);
          expect(c.snapshot.currentEntryId, fixtureA.entryId);
          expect(c.snapshot.confirmations.length, 1);
        },
      );
    }
  }
  for (final timing in [
    'ready-before-pause',
    'ready-during-pause',
    'ready-after-resume',
  ]) {
    test('GR02 resume follows latest B $timing', () async {
      await setup(ready: timing == 'ready-before-pause');
      c.pause(cmd('pause'));
      if (timing == 'ready-during-pause') {
        b.ready('b', 'hb');
        await flushContractEvents();
      }
      final start = b.actions.length;
      expect(c.resume(cmd('resume')).applied, isTrue);
      expect(b.actions.skip(start), isNot(contains('play:ha')));
      if (timing == 'ready-after-resume') {
        b.ready('b', 'hb');
        await flushContractEvents();
      }
      expect(b.actions.skip(start), contains('play:hb'));
      b.emit('b', 'hb', BackendEventKind.playing, 1);
      expect(c.snapshot.currentEntryId, fixtureB.entryId);
      expect(c.snapshot.requestedEntryId, fixtureB.entryId);
      expect(c.snapshot.confirmations.length, 2);
      c.completeTransition('hb', transitionId: b.requests['b']!.transitionId);
      await flushContractEvents();
      expect(b.actions, contains('release:ha'));
    });
  }
}
