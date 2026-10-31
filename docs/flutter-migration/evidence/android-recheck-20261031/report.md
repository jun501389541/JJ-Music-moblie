# Android 重连补验（2026-10-31）

用户授权连接此前选定手机后验证；仅补初始框架 A01 启动和诊断按钮，不新增 P1 功能，不改变 G-L 结论。

- 设备身份：ADB 35a63609，Xiaomi 2211133C/fuxi，Android 13/API33，arm64-v8a。测试前在线且 Awake，与此前明确选定设备一致。
- 当前共享冻结 p1-a02-v2.1 的19文件哈希复核通过，代码未改。
- 在 clients/flutter 执行 `./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/diagnostic_smoke_test.dart','--device-id','35a63609','--reporter','expanded')`，完整退出0，原生集成测试1项通过。实际界面三个按钮分别得到“入口检查通过”“共享合同检查通过”“快照写读检查通过”；最后一项使用真实隔离文件存储。见 [smoke.log](smoke.log)。没有播放真实音乐。
- 测试截图只生成在应用私有 code_cache；未导出，不能称本地截图证据。
- 等待测试进程完全退出后，执行 `./tool/check.ps1 -Mode AndroidRelease -EvidenceDirectory ../../docs/flutter-migration/evidence/android-recheck-20261031/build`，普通 lib/main.dart release 构建通过。见 [构建日志](build/android-build.log)。
- 普通包重新 `adb -s 35a63609 install -r` 成功；`am start -W` 返回 Status ok、LaunchState UNKNOWN，PID25570存在。见 [安装](install.log)、[启动](start.log)、[进程](process.log)。收尾 [电源状态](screen.log) 为 Dozing，因此普通包启动命令不另计亮屏按钮通过；亮屏交互证据来自此前完成的原生集成测试。
- 最终 APK：`clients/flutter/build/app/outputs/flutter-apk/app-release.apk`，48509302字节，SHA256 `dd724416c04ddade769d96f0610b21df12a8163ee10e9277fb4c0d87f9cb5eb1`。见 [产物清单](artifact.json)。仍为内部模板 debug 签名，不是发行包。

SDK XML v3/v4 警告未影响本次构建/测试，未升级系统工具。Windows不在本次重跑范围，沿用上一批独立证据。原设备断开证据保留为历史；本次关闭 Android A01 启动/三个按钮及最终普通包安装缺口。独立审阅、远端CI和完整P1验收缺口保持未完成；未提交、推送或发布。
