import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import '../../integration_test/support/controlled_backend.dart';
import '../../integration_test/support/local_playback_contract.dart';

void main() {
  for (final failure in ['cancel', 'error']) {
    test(
      'preconfirmation $failure resumes still-valid old physical track',
      () async {
        final b = ControlledBackend();
        final c = PlaybackCoordinator(b);
        CommandContext cmd(String id) => CommandContext(id, c.claim);
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
        b.ready('b', 'hb');
        await flushContractEvents();
        // Real adapters hard-switch: play(hb) physically paused ha, before hb confirms.
        final before = b.actions.where((a) => a == 'play:ha').length;
        if (failure == 'cancel') {
          c.cancel(cmd('cancel'), 'b');
        } else {
          b.emit('b', 'hb', BackendEventKind.error, 1);
        }
        expect(b.actions.where((a) => a == 'play:ha').length, before + 1);
        expect(c.snapshot.currentEntryId, fixtureA.entryId);
        expect(c.snapshot.confirmations.length, 1);
        await c.dispose();
        await b.close();
      },
    );
  }
}
