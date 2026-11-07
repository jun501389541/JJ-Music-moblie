# v2.9 双端正常关闭恢复与普通包（2026-11-07）

A07/A02 串行续批。源码未改，p1-a02-v2.9 的 32 文件及 05 在构建前后均通过哈希检查。旧普通 APK 及 Windows Release 全目录备份于忽略目录 graphflow-out/close-observe-platform-20261107/ordinary-before，已复核 18 个文件哈希。

- Android：在在线、解锁的测试手机 35a63609 上，于 clients/flutter 执行 tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/coordinator_restart_test.dart','-d','35a63609','--reporter','expanded')，退出 0，1 项通过；见 [日志](android.log)。
- Windows：于同目录执行 flutter test integration_test/coordinator_restart_test.dart -d windows --reporter expanded，退出 0，1 项通过；见 [日志](windows.log)。
- 两端用自有 tone-long 夹具及隔离目录；恢复到修订 1、位置 2345 ms、暂停，控制 epoch 更新且旧控制权拒绝，显式继续及停止断言通过，releasedSamples/finalSamples 均为空。
- 按 tool/check.ps1 的 AndroidRelease 和 WindowsRelease 模式构建 lib/main.dart，两端均成功且依赖锁未变。普通 APK 通过 adb install -r 替换测试包，MainActivity 冷启动 Status: ok、PID 9039；Windows 普通程序启动后存活 2 秒，随后仅终止本轮启动的进程。见 [APK 启动](android-ordinary.log)、[Windows 启动](windows-ordinary.log) 和 [摘要](ordinary-final.json)。
- 普通产物清单 18 个路径和哈希与上批完全一致。此结果仅说明普通入口构建与启动成功；v2.9 关闭路径的正常验证以两端集成测试为准，镜像挂起时的 destroy 异常以受控宿主证据为准。

未重复共享 97 项，未做真实系统故障注入、人工听感或完整 G–L 验收。未提交、推送。
