# JJ-Music Flutter：P1自有本地样本技术诊断

已有Android/Windows真实本地播放及共享恢复原型；不是正式播放器/UI。完整G-L仍未通过，实际结果和未验项见[阶段报告](../../docs/flutter-migration/evidence/p1-a/20261031/report.md)。

最新A04焦点资源安全子批见[证据与验收](../../docs/flutter-migration/evidence/focus-20261031/report.md)。Android中断后需明确继续，不自动恢复；普通lib/main.dart入口与专用release焦点探针分开构建。焦点测试仅自有媒体/本应用请求，不代表电话、蓝牙或所有其他App已验证。

Windows程序：`E:\Workspace\project\JJ-Music-mobile\clients\flutter\build\windows\x64\runner\Release\jj_music_mobile.exe`。必须保留整个Release文件夹，不能只复制EXE。

Android普通诊断包：`E:\Workspace\project\JJ-Music-mobile\clients\flutter\build\app\outputs\flutter-apk\app-release.apk`。本批已安装到用户选定小米2211133C（35a63609，Android13）。应用名jj_music_mobile，内部调试签名，不是正式发行。app-debug.apk是测试入口，不能作普通验收包。

[简单验收清单](../../docs/flutter-migration/evidence/p1-a/20261031/acceptance.md)：进入“自有样本播放诊断”，播放/暂停/定位3秒/继续/切换/停止；确认数仅合法新播放增加，UI重连及组件重建不重播；保存后重开默认暂停。短音调可听感验收，不导入个人曲库/音源。

重新安装（USB调试已允许，设备编号先核对）：

```powershell
& 'E:\Android\sdk\platform-tools\adb.exe' devices -l
& 'E:\Android\sdk\platform-tools\adb.exe' -s '35a63609' install -r 'E:\Workspace\project\JJ-Music-mobile\clients\flutter\build\app\outputs\flutter-apk\app-release.apk'
```

开发复验，在本目录运行：

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter test integration_test/windows_local_playback_test.dart --device-id windows --reporter expanded
flutter test integration_test/windows_media_test.dart --device-id windows --reporter expanded
flutter test integration_test/runtime_recovery_test.dart --device-id windows --reporter expanded
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_local_playback_test.dart','--device-id','35a63609','--reporter','expanded')
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_lifecycle_test.dart','--device-id','35a63609','--reporter','expanded')
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_audio_focus_test.dart','--device-id','35a63609','--reporter','expanded')
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/runtime_recovery_test.dart','--device-id','35a63609','--reporter','expanded')
```

设备必须实际在线；UI测试另需解锁亮屏，关屏测试要求原生screenInteractive=false，不能仅运行定时器。WindowsOS测试的独立probe由工程自编译，位于diagnostic_tools目录且不装入普通Release包。辅助构建脚本仅当前进程设置代理/工程内Gradle缓存，不改全局；使用显式FlutterArgs数组，不用会被PowerShell解析的短-d。

专用两进程强杀证明（测试入口，不是用户程序）：

```powershell
flutter build windows --release --target lib/p1_process_probe.dart
.\tool\run_windows_recovery_probe.ps1
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_process_probe.dart')
.\tool\run_android_recovery_probe.ps1 -DeviceId '35a63609'
# 验证后必须重建普通入口，避免把探针当用户程序
flutter build windows --release --target lib/main.dart
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/main.dart')
```

快照只在临时目录jj-owned-p1/recovery/<runId>，普通运行owned-p1、专用探针process-proof，Android为本应用code_cache。系统可清理缓存；不是正式用户数据库/备份。自有WAV来源和SHA见fixtures/local_playback；[当前共享冻结v2.2](../../docs/flutter-migration/evidence/A02/20261031-focus-freeze.md)。真实持续缓冲、独立engine/服务回收、输出失效等仍需本阶段补验，没有自动进入P2或正式UI。
