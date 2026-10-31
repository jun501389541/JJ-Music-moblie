# 实际命令及失败处理

cwd：E:/Workspace/project/JJ-Music-mobile/clients/flutter。输出经`*> <log>`保存，每步立即读取`$LASTEXITCODE`，非零停止后继；不把日志显示命令退出码当产品退出码。重跑应改新证据目录。

```powershell
# windows-red.log：新能力缺失，退出1；windows-initial.log：首轮4项
flutter test integration_test/windows_loading_test.dart --device-id windows --reporter expanded
# windows-gate-final.log：5项；close-error-green-suite.log：修复后完整6项
flutter test integration_test/windows_loading_test.dart --device-id windows --reporter expanded
# close-error-red.log：仅加异常注入/观察，关闭逻辑未修时复现
flutter test integration_test/windows_loading_test.dart --device-id windows --plain-name 'Windows close error cannot turn retry into false release success' --reporter expanded
# 每项独立Flutter进程，windows-local-final / windows-media-final / windows-runtime-final.log
flutter test integration_test/windows_local_playback_test.dart --device-id windows --reporter expanded
flutter test integration_test/windows_media_test.dart --device-id windows --reporter expanded
flutter test integration_test/runtime_recovery_test.dart --device-id windows --reporter expanded
# android-final.log保留首次崩溃失败；用户解锁后android-repaired.log
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_service_registration_test.dart','integration_test/android_loading_test.dart','integration_test/android_audio_focus_test.dart','integration_test/android_lifecycle_test.dart','--device-id','35a63609','--reporter','expanded')
# 原失败命令，不以其结果写通过
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_loading_test.dart','--device-id','35a63609','--reporter','expanded')
# 首轮final-check-summary.log/final-checks因新测试缺花括号lint退出1，原样保留
# 修复后verified-summary.log/verified-checks才是最终质量与普通构建
.\tool\check.ps1 -Mode All -EvidenceDirectory ../../docs/flutter-migration/evidence/windows-loading-20261031/verified-checks
# runner全部结束，恢复普通入口
adb -s 35a63609 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 35a63609 shell am start -W -n dev.jjmusic.diagnostics.jj_music_mobile/.MainActivity
adb -s 35a63609 shell pidof dev.jjmusic.diagnostics.jj_music_mobile
```

windows-final.log保留失败的多入口尝试（loading/local/media/runtime同一flutter test命令）：第一组5项通过，后三入口已构建但出现`Error waiting for a debug connection: The log reader stopped unexpectedly, or never started`，未执行相应用例，不写通过。相同源码单入口windows-local-isolated.log随后3项通过，问题缩小到多入口启动/调试连接层；没有声称已修Flutter SDK。后续分别独立命令验证其他入口，不改全局/工具源码、不删用例、不降低断言。

关闭异常注入属于确定性故障验证，不冒充实际SDK自发异常。第一次release应返回PlatformException，重复显式release必须真的关闭遗漏source/stream并等待读数归零，不能吞错换Success。

android-service-red.log对应只跑android_service_registration_test.dart，缺新探针而失败。Android首次PID7480崩溃后，仅查询本包exit-info和该PID的crash日志，未读取其他应用/私人媒体；用户随后明确回复解锁，修复前台服务握手后执行上述9项。没有修改锁屏或系统配置。
