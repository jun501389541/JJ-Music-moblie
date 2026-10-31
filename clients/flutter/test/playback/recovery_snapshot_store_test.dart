import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/data/prototype_recovery/file_snapshot_store.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/domain/playback/recovery_snapshot.dart';

import '../../integration_test/support/local_playback_contract.dart';

void main() {
  late Directory root;
  FileSnapshotStore store() => FileSnapshotStore(
    root: root,
    runId: 'run-a',
    allowedFixtureIds: {'tone-a'},
  );
  RecoverySnapshot snapshot(int revision) => RecoverySnapshot(
    runId: 'run-a',
    revision: revision,
    playbackSessionId: 'session-a',
    entries: [fixtureA, fixtureB],
    currentIndex: 1,
    positionMs: 1234,
    confirmations: ['session-a:1'],
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('jj-music-prototype-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test('TC-05 saved receipt means real bytes and a fresh store reads the same revision paused', () async {
    final receipt = await store().save(snapshot(7));
    expect(receipt.revision, 7);
    expect(await Directory('${root.path}/run-a').exists(), isTrue);
    final result = await store().load();
    expect(result.snapshot?.revision, 7);
    expect(result.snapshot?.positionMs, 1234);
    expect(result.snapshot?.entries[1].entryId, 'occurrence-b');
    expect(result.restoredTransport, DesiredTransport.paused);
  });
  test(
    'concurrent out-of-order writes cannot replace a higher saved revision',
    () async {
      final s = store();
      final newer = s.save(snapshot(5));
      final older = s.save(snapshot(4));
      await expectLater(older, throwsA(isA<StateError>()));
      await newer;
      expect((await store().load()).snapshot?.revision, 5);
    },
  );
  test('missing, corrupt, oversized, unknown version and unavailable fixture are safe', () async {
    expect((await store().load()).snapshot, isNull);
    final dir = await Directory('${root.path}/run-a').create(recursive: true);
    final file = File('${dir.path}/snapshot-a.json');
    for (final data in [
      '{broken',
      jsonEncode({...snapshot(2).toJson(), 'formatVersion': 99}),
      ' ' * (256 * 1024 + 1),
      jsonEncode({
        ...snapshot(2).toJson(),
        'entries': [
          {'entryId': 'a', 'trackKey': 'x', 'fixtureId': 'not-allowed'},
        ],
        'currentIndex': 0,
      }),
    ]) {
      await file.writeAsString(data);
      final result = await store().load();
      expect(result.snapshot, isNull);
      expect(result.issues, isNotEmpty);
    }
  });
  test('interrupted temporary write and corrupt newest slot retain a last valid snapshot', () async {
    final s = store();
    await s.save(snapshot(1));
    await s.save(snapshot(2));
    final dir = Directory('${root.path}/run-a');
    await File('${dir.path}/snapshot-a.json').writeAsString('{partial');
    await File('${dir.path}/snapshot-b.json.tmp').writeAsString('{unfinished');
    expect((await store().load()).snapshot?.revision, 1);
  });
  test(
    'forbidden runtime fields and oversized queues cannot be persisted',
    () async {
      await expectLater(
        store().save(
          RecoverySnapshot(
            runId: 'run-a',
            revision: 1,
            playbackSessionId: 'session',
            entries: List.generate(
              17,
              (i) => QueueEntry(
                entryId: 'e$i',
                trackKey: 'tone',
                fixtureId: 'tone-a',
              ),
            ),
            currentIndex: 0,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      final dir = await Directory('${root.path}/run-a').create(recursive: true);
      await File('${dir.path}/snapshot-a.json').writeAsString(
        jsonEncode({...snapshot(1).toJson(), 'token': 'synthetic-secret'}),
      );
      expect((await store().load()).snapshot, isNull);
    },
  );
}
