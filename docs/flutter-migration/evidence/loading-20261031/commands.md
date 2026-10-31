# 本批实际命令

Flutter工作目录：E:/Workspace/project/JJ-Music-mobile/clients/flutter。只用已选定手机35a63609。重跑要换新证据目录，不覆盖本批日志。

```powershell
# android-red.log（实现前，新能力缺失，退出1）和android-initial.log（实现后）
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_loading_test.dart','--device-id','35a63609','--reporter','expanded')
# android-final.log（增强时序证据 + 既有本地/焦点/生命周期）
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_loading_test.dart','integration_test/android_local_playback_test.dart','integration_test/android_audio_focus_test.dart','integration_test/android_lifecycle_test.dart','--device-id','35a63609','--reporter','expanded')
# windows-final.log
flutter test integration_test/windows_local_playback_test.dart --device-id windows --reporter expanded
# final-check-summary.log，详分final-checks/
.\tool\check.ps1 -Mode All -EvidenceDirectory ../../docs/flutter-migration/evidence/loading-20261031/final-checks
# 测试runner完全退出后，恢复普通lib/main.dart包
adb -s 35a63609 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 35a63609 shell am start -W -n dev.jjmusic.diagnostics.jj_music_mobile/.MainActivity
adb -s 35a63609 shell pidof dev.jjmusic.diagnostics.jj_music_mobile
```

标准输出/错误以`*> <log>`完整保存，每步紧接保存`$LASTEXITCODE`，非零停止后继，不能把Get-Content的退出码当测试退出码。最终读取全部runner完成后确认结果。各命令顺序执行，不并发生成同一Flutter注册文件。

一次受限shell的dart format包装未执行完成，已只终止核对过命令行的本任务包装PID22904；在可访问现有SDK的环境重跑退出0、无格式差异。未修改SDK/系统配置，不把这次包装失败当产品缺陷。最终质量检查仍独立重跑格式及analyze。
