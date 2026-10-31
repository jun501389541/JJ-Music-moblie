import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/app/runtime/local_runtime.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';
import 'package:jj_music_mobile/domain/playback/contracts.dart';

import 'windows_local_playback_test.dart' show until;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android Activity recreation preserves engine authority and resource',
    (tester) async {
      final r = await LocalRuntime.create(runId: 'lifecycle-$pid');
      try {
        r.command('a');
        await until(() => r.snapshot.currentEntryId == ownedA.entryId);
        final host = r.backend.lastHost['host'];
        final session = r.snapshot.playbackSessionId;
        final handle = r.snapshot.tracks.single.trackHandleId;
        await NativeLocalBackend.channel.invokeMethod<void>('recreateActivity');
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(r.backend.lastHost['host'], host);
        expect(r.snapshot.playbackSessionId, session);
        expect(r.snapshot.tracks.single.trackHandleId, handle);
        expect(r.snapshot.confirmations.length, 1);
        expect(r.snapshot.positionMs, greaterThan(1000));
        final beforeBackground = r.snapshot.positionMs;
        await NativeLocalBackend.channel.invokeMethod<void>(
          'backgroundActivity',
        );
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(r.snapshot.positionMs, greaterThan(beforeBackground + 800));
        expect(r.snapshot.confirmations.length, 1);
        await NativeLocalBackend.channel.invokeMethod<void>('showActivity');
        await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
          'command': 'pause',
        });
        await until(() => r.snapshot.desired == DesiredTransport.paused);
        expect(r.snapshot.confirmations.length, 1);
        await NativeLocalBackend.channel.invokeMethod<void>('osCommand', {
          'command': 'play',
        });
        await until(() => r.snapshot.desired == DesiredTransport.playing);
        final life = (r.backend.lastHost['lifecycle'] as List).cast<Map>();
        expect(
          life.where((e) => e['event'] == 'activity-create').length,
          greaterThanOrEqualTo(2),
        );
        expect(life.where((e) => e['event'] == 'activity-destroy'), isNotEmpty);
        r.reconnect();
        r.reconnect();
        expect(r.snapshot.tracks.single.trackHandleId, handle);
        expect(r.snapshot.confirmations.length, 1);
        r.command('stop');
        await until(() => r.backend.consumers == 0);
      } finally {
        // ignore: avoid_print
        print('ANDROID_LIFECYCLE_JSON=${jsonEncode(r.backend.lastHost)}');
        // ignore: avoid_print
        print('ANDROID_LIFECYCLE_RAW=${jsonEncode(r.backend.raw)}');
        await r.close();
      }
    },
  );
}
