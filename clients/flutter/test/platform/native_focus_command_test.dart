import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('late focus poll cannot pause a renewed transport; media controls survive', () async {
    final pendingPoll = Completer<Map<String, Object?>>();
    final pollEntered = Completer<void>();
    var prepared = false, delayPoll = false;
    int? playRevision;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeLocalBackend.channel, (call) async {
          if (call.method == 'prepare') prepared = true;
          if (call.method == 'play') {
            playRevision = (call.arguments as Map)['transportRevision'] as int?;
          }
          if (call.method == 'poll') {
            if (delayPoll) {
              if (!pollEntered.isCompleted) pollEntered.complete();
              return pendingPoll.future;
            }
            return {
              'samples': prepared
                  ? [
                      {
                        'id': 'native-1',
                        'ready': true,
                        'state': 3,
                        'position': 0,
                        'nativePlaying': false,
                      },
                    ]
                  : [],
              'commands': [],
            };
          }
          return null;
        });
    final backend = NativeLocalBackend({'owned': 'file:///owned.wav'});
    final received = <Map<String, dynamic>>[];
    final sub = backend.systemCommands.listen(received.add);
    try {
      final h = await backend.prepare(
        const PrepareRequest(
          requestId: 'a',
          entry: QueueEntry(entryId: 'a', trackKey: 'a', fixtureId: 'owned'),
          generation: 1,
          backendEpoch: 1,
        ),
      );
      await backend.play(h.trackHandleId);
      final oldRevision = playRevision;
      delayPoll = true;
      await pollEntered.future.timeout(const Duration(seconds: 2));
      // A real native poll already holds the old focus pause, but its reply
      // arrives after Dart has dispatched a fresh play on the SAME handle.
      await backend.play(h.trackHandleId);
      pendingPoll.complete({
        'samples': [],
        'commands': [
          {
            'command': 'pause',
            'focusEpoch': 1,
            'transportRevision': oldRevision,
          },
          {'command': 'pause'}, // Ordinary media key is not a focus callback.
          {
            'command': 'pause',
            'focusEpoch': 2,
            'transportRevision': playRevision,
          },
        ],
      });
      // Stop repeated sampling of the same fake reply after this poll finishes.
      delayPoll = false;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        received,
        hasLength(2),
        reason: 'Only the old focus pause is stale',
      );
      expect(received.first.containsKey('focusEpoch'), isFalse);
      expect(received.last['transportRevision'], playRevision);
    } finally {
      if (!pendingPoll.isCompleted) {
        pendingPoll.complete({'samples': [], 'commands': []});
      }
      await sub.cancel();
      await backend.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NativeLocalBackend.channel, null);
    }
  });
}
