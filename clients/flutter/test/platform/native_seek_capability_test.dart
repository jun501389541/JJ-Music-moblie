import 'package:flutter_test/flutter_test.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final capability in [true, false, null]) {
    test(
      'native ready maps $capability without defaulting missing to true',
      () async {
        var prepared = false;
        final calls = <String>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(NativeLocalBackend.channel, (
          call,
        ) async {
          calls.add(call.method);
          if (call.method == 'prepare') prepared = true;
          if (call.method == 'poll') {
            return {
              'samples': [
                if (prepared)
                  {
                    'id': 'native-1',
                    'ready': true,
                    'state': 3,
                    'nativePlaying': false,
                    'position': 0,
                    'canSeek': ?capability,
                  },
              ],
              'commands': [],
            };
          }
          return null;
        });
        final backend = NativeLocalBackend({'owned': 'file:///owned.wav'});
        try {
          final resource = await backend.prepare(
            const PrepareRequest(
              requestId: 'a',
              entry: QueueEntry(
                entryId: 'a',
                trackKey: 'a',
                fixtureId: 'owned',
              ),
              generation: 1,
              backendEpoch: 1,
            ),
          );
          expect(resource.canSeek, capability);
          expect(calls, isNot(contains('seek')));
          expect(calls, isNot(contains('play')));
        } finally {
          await backend.close();
          messenger.setMockMethodCallHandler(NativeLocalBackend.channel, null);
        }
      },
    );
  }
}
