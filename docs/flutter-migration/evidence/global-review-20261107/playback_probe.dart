import 'package:jj_music_mobile/application/playback/playback_coordinator.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import '../../../../clients/flutter/integration_test/support/controlled_backend.dart';

const a = QueueEntry(entryId: 'a', trackKey: 'a', fixtureId: 'a');
const b = QueueEntry(entryId: 'b', trackKey: 'b', fixtureId: 'b');
Future<void> flush() => Future<void>.delayed(Duration.zero);
Future<void> main() async {
  for (final action in ['seek', 'remove-incoming', 'pause-resume-ready', 'pause-resume-pending']) {
    final backend = ControlledBackend();
    final c = PlaybackCoordinator(backend);
    CommandContext cmd(String id) => CommandContext(id, c.claim);
    c.play(cmd('a'), PlayIntent(entries: [a,b], entryId: 'a'));
    backend.ready('a', 'ha');
    await flush();
    backend.emit('a', 'ha', BackendEventKind.playing, 1);
    c.play(cmd('b'), PlayIntent(entries: [a,b], entryId: 'b'));
    if (action != 'pause-resume-pending') {
      backend.ready('b', 'hb');
      await flush();
    }
    final start = backend.actions.length;
    if (action == 'seek') {
      c.seek(cmd('seek'), 3000);
    } else if (action == 'remove-incoming') {
      c.replaceQueue(cmd('queue'), [a], c.snapshot.queueRevision);
    } else {
      c.pause(cmd('pause'));
      if (action == 'pause-resume-pending') {
        backend.ready('b', 'hb');
        await flush();
      }
      c.resume(cmd('resume'));
    }
    await flush();
    print('$action actions=${backend.actions.skip(start).toList()} current=${c.snapshot.currentEntryId} requested=${c.snapshot.requestedEntryId} desired=${c.snapshot.desired.name} roles=${c.snapshot.tracks.map((t) => '${t.trackHandleId}:${t.role.name}').toList()}');
    await c.dispose();
    await flush();
    await backend.close();
  }
}
