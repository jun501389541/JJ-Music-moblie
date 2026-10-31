import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('duplicate release waits for same physical close', () async {
    final gate = Completer<void>();
    var ready = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeLocalBackend.channel, (call) async {
          if (call.method == 'release') {
            await gate.future;
          }
          if (call.method == 'prepare') {
            ready = true;
          }
          if (call.method == 'poll') {
            return {
              'samples': ready
                  ? [
                      {
                        'id': 'native-1',
                        'platform': 'windows',
                        'ready': true,
                        'nativePlaying': false,
                        'playWhenReady': false,
                        'state': 1,
                        'position': 0,
                        'duration': 12000,
                      },
                    ]
                  : [],
              'commands': [],
            };
          }
          return null;
        });
    final b = NativeLocalBackend({'tone-a': 'file:///owned.wav'});
    final h = await b.prepare(
      const PrepareRequest(
        requestId: 'r',
        entry: QueueEntry(entryId: 'a', trackKey: 'a', fixtureId: 'tone-a'),
        generation: 1,
        backendEpoch: 1,
      ),
    );
    var first = false, second = false;
    final f1 = b
        .release(h.trackHandleId, h.consumerId, 1)
        .then((_) => first = true);
    final f2 = b
        .release(h.trackHandleId, h.consumerId, 1)
        .then((_) => second = true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(first, isFalse);
    expect(second, isFalse);
    gate.complete();
    await Future.wait([f1, f2]);
    expect(b.consumers, 0);
    await b.close();
  });
}
