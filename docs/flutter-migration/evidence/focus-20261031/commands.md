# 本批实际命令与退出码定位

工作目录：E:/Workspace/project/JJ-Music-mobile/clients/flutter。使用已有本机SDK/代理helper，无全局改动。原始日志及退出码索引为command-results.json；红例只在改前代码运行，不应把当前代码跑绿当成历史红例。

```powershell
# android-red.log，修复后android-green-initial.log
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_audio_focus_test.dart','--device-id','35a63609','--reporter','expanded')
# late-poll-red.log / late-poll-green.log
flutter test test/platform/native_focus_command_test.dart --reporter expanded
# android-final.log为v2.1期间；android-v22-final.log是最终v2.2
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_audio_focus_test.dart','integration_test/android_local_playback_test.dart','integration_test/android_lifecycle_test.dart','--device-id','35a63609','--reporter','expanded')
# windows-final.log
flutter test integration_test/windows_local_playback_test.dart --device-id windows --reporter expanded
# release-probe-build.log / release-probe-run.log
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_focus_probe.dart')
.\tool\run_android_focus_probe.ps1 -DeviceId 35a63609 -EvidenceDirectory ../../docs/flutter-migration/evidence/focus-20261031/release
# final-check-summary.log，包含39共享测试/双端普通入口构建
.\tool\check.ps1 -Mode All -EvidenceDirectory ../../docs/flutter-migration/evidence/focus-20261031/final-checks
# normal-install.log / normal-start.log / normal-pid.log
adb -s 35a63609 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 35a63609 shell am start -W -n dev.jjmusic.diagnostics.jj_music_mobile/.MainActivity
adb -s 35a63609 shell pidof dev.jjmusic.diagnostics.jj_music_mobile
```

失败的release尝试为以上三个Android集成入口的test参数追加`--release`，退出64，当前SDK不支持。替代为显式release探针，不重复使用不存在的选项。各安装/测试结束等待runner完全退出，再构建/安装下一个同包入口；最终普通包lib/main.dart恢复。

重跑请改新的EvidenceDirectory，不覆盖本批不可变实际日志。Flutter标准输出经PowerShell`*> <log>`保存，紧接读取`$LASTEXITCODE`；完整命令链退出0以各步骤非零即停止保证，不将管道尾部显示当测试退出码。
