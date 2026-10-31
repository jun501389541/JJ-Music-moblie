import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jj_music_mobile/platform/local/native_local_backend.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android stop waits for all requested foreground registrations', (
    tester,
  ) async {
    // Real start requests and stop in ONE platform callback, before the service
    // can receive onCreate/onStartCommand. No audio or personal media involved.
    await NativeLocalBackend.channel.invokeMethod<void>(
      'serviceRegistrationProbe',
    );
    Map<String, dynamic> host = {};
    for (var i = 0; i < 80; i++) {
      host = Map<String, dynamic>.from(
        await NativeLocalBackend.channel.invokeMapMethod<String, dynamic>(
              'poll',
            ) ??
            {},
      );
      if (host['pendingServiceStarts'] == 0 &&
          host['servicePresent'] == false) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(host['pendingServiceStarts'], 0);
    expect(host['servicePresent'], isFalse);
    expect(
      (host['lifecycle'] as List)
          .where((e) => e['event'] == 'service-start-ack')
          .length,
      3,
    );
    // Also wait beyond the normal system promotion deadline to catch delayed
    // process termination, rather than exiting immediately after native return.
    await Future<void>.delayed(const Duration(seconds: 7));
    host = Map<String, dynamic>.from(
      await NativeLocalBackend.channel.invokeMapMethod<String, dynamic>(
            'poll',
          ) ??
          {},
    );
    expect(host['pendingServiceStarts'], 0);
    expect(host['servicePresent'], isFalse);
    // ignore: avoid_print
    print('ANDROID_SERVICE_REGISTRATION=${jsonEncode(host)}');
  });
}
