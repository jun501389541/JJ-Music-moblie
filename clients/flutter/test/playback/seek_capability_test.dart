import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import '../../integration_test/support/controlled_backend.dart';
import '../../integration_test/support/local_playback_contract.dart';

void main() {
  for (final capability in [true, false, null]) {
    test('seek capability $capability gates all side effects', () async {
      final backend = ControlledBackend();
      final c = PlaybackCoordinator(backend);
      try {
        c.play(
          CommandContext('play', c.claim),
          PlayIntent(entries: [fixtureA], entryId: fixtureA.entryId),
        );
        backend.ready('play', 'a', canSeek: capability);
        await flushContractEvents();
        backend.emit('play', 'a', BackendEventKind.playing, 1);
        final before = c.snapshot;
        final actions = List.of(backend.actions);
        final ack = c.seek(CommandContext('seek', c.claim), 9000);
        expect(ack.applied, capability == true);
        if (capability != true) {
          expect(ack.accepted, isFalse);
          expect(
            ack.failure?.code,
            capability == false
                ? 'seek-unsupported'
                : 'seek-capability-unknown',
          );
          expect(c.snapshot.positionMs, before.positionMs);
          expect(c.snapshot.playbackGeneration, before.playbackGeneration);
          expect(backend.actions, actions);
          expect(c.snapshot.confirmations, before.confirmations);
        } else {
          expect(backend.actions, contains('seek:a:9000'));
        }
      } finally {
        await c.dispose();
      }
    });
  }
}
