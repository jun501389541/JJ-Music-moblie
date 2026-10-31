# 实际命令与退出码

cwd E:/Workspace/project/JJ-Music-mobile/clients/flutter。原始输出以`*> <log>`保存、紧接读`$LASTEXITCODE`；非零停止依赖后继，不把日志显示退出码当测试退出码。重跑换新证据目录，保留本批失败。

```powershell
# android-red.log：缺新能力，4失败；android-initial.log：2通过/2首播失败
# android-diagnose.log：新增白名单原生错误后复现FGS拒绝
# android-foreground.log：过早的setUpAll焦点检查失败
# android-visible.log：真实首帧后保持同样严格前置，最终4通过
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_rebuffer_test.dart','--device-id','35a63609','--reporter','expanded')
# android-regression.log：已有initial gate4、service registration1
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_loading_test.dart','integration_test/android_service_registration_test.dart','--device-id','35a63609','--reporter','expanded')
# Windows每入口独立进程，windows-gate.log 6项、windows-local.log 3项
flutter test integration_test/windows_loading_test.dart --device-id windows --reporter expanded
flutter test integration_test/windows_local_playback_test.dart --device-id windows --reporter expanded
# quality-summary.log及quality/，build-summary.log及build/
.\tool\check.ps1 -Mode Quality -EvidenceDirectory ../../docs/flutter-migration/evidence/rebuffer-20261031/quality
.\tool\check.ps1 -Mode AndroidRelease -EvidenceDirectory ../../docs/flutter-migration/evidence/rebuffer-20261031/build
adb -s 35a63609 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 35a63609 shell am start -W -n dev.jjmusic.diagnostics.jj_music_mobile/.MainActivity
adb -s 35a63609 shell pidof dev.jjmusic.diagnostics.jj_music_mobile
```

指定35a63609，先核型号/API。新测试要求用户解锁、Activity可见；仅本窗口KEEP_SCREEN_ON，tearDownAll清除。息屏时旧失败的后两项在首播前报ForegroundServiceStartNotAllowedException，并非缓冲断言失败；不修改系统限制绕过。setUpAll可能在Android启动窗口仍拥有焦点时过早检查，因此最终生成实际测试首帧后再核interactive/未锁定/本Activity焦点，条件未放宽。

普通Windows源码未改，不重建/关闭前批Release，仅核现有哈希与上一批一致；本批实际执行的Windows测试是Debug原生回归，不称Windows播放后再缓冲或本批普通release重新验证。
