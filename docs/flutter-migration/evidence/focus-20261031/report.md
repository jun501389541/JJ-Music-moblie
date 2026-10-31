# A04焦点安全子批：实际实现与验收

2026-10-31，开发根 E:/Workspace/project/JJ-Music-mobile；旧JJ-Music只读。对应A04焦点资源子项、A03/A05受影响回归、A02维护者整合v2.2和A08缺口更新。本批目标已完成；A03—A08整体仍review、完整G-L不放行P2。

## 实现与差异

| 文件（相对clients/flutter） | 实际变化 |
| --- | --- |
| android/app/src/main/kotlin/dev/jjmusic/diagnostics/jj_music_mobile/LocalHost.kt | pause/stop/最后物理release及启动失败统一归还焦点；先失效旧请求再调用OS；新请求/旧回调代次围栏；焦点loss即时物理暂停并转共享命令；gain不自动重播；原生排队旧焦点命令过滤 |
| lib/platform/local/native_local_backend.dart | 通过实际请求携带transportRevision，在Dart接收迟到poll回包时再次核验；prepare/play/pause/stop同步推进；普通系统媒体命令保留 |
| integration_test/android_audio_focus_test.dart | 3项真实原生集成测试：自然结束清理；真实OS焦点竞争/明确恢复/中断期间停止；旧listener故障注入 |
| test/platform/native_focus_command_test.dart | 可控延迟平台回包，证明旧焦点消息丢弃，新焦点及普通媒体控制保留 |
| lib/p1_focus_probe.dart、tool/run_android_focus_probe.ps1 | 独立release验证入口及带新随机令牌/PID/构建哈希的控制脚本；5项检查，结束停止本诊断进程 |
| integration_test/windows_local_playback_test.dart | 原始日志改为每次独立临时目录并输出当前runner日志，避免覆盖历史P1证据 |
| tool/check.ps1 | 改为核新冻结v2.2，仍不自动重写哈希 |

未新增依赖、未改变公共接口/协议1/快照格式1。旧19文件中仅native_local_backend.dart行为更新，加新测试形成20文件[v2.2冻结](../A02/20261031-focus-freeze.md)；旧v2.1不改。Windows桥忽略额外play参数，两端实际重新消费新冻结。原生没有新增队列/随机/音质/重试策略。正式UI、旧端、个人曲库/账号/真实音源、系统配置均未改。

真实差异见[source-diff.patch](source-diff.patch)、[本批文件摘要](source-manifest.json)；改前文件保留before/。Git feat/flutter-a01-a02仍无HEAD/暂存/远端，既有未提交工作保留，不把git diff空当无源码改动。

## 实际验证

| 层级/平台 | 命令或输入 | 实际结果与证据 |
| --- | --- | --- |
| 起点 | GraphFlow context、plan及intent/decomposition桥接submit/merge；AGENTS/README/status/handoff/索引/归属/05/条件分支及当前实现 | 成功，按实际mobile根；[计划/账本](plan.md) |
| 设备 | 用户重连后核ADB/model/API/屏幕 | 唯一指定35a63609，Xiaomi2211133C/fuxi，Android13/API33，Awake；后续自动息屏不妨碍非UI焦点测试，不绕锁屏 |
| RED/GREEN真机 | 新焦点测试、只加观察/竞争探针后先跑，再修复 | [RED](android-red.log)退出1、2失败；[初轮GREEN](android-green-initial.log)退出0、2通过。实际OS回调-2，原生暂停；focusHeld仅是宿主request引用存在，不等于OS独占焦点查询 |
| 迟到回包单元 | flutter test test/platform/native_focus_command_test.dart --reporter expanded | [RED](late-poll-red.log)退出1（实际3条，预期2）；[GREEN](late-poll-green.log)退出0。属于MethodChannel边界模拟，不是真机OS迟到序列 |
| Android v2.2 | flutter_with_proxy.ps1，test三个入口：android_audio_focus_test.dart、android_local_playback_test.dart、android_lifecycle_test.dart，--device-id35a63609 | [最终日志](android-v22-final.log)退出0、7项通过（3焦点/3本地/1生命周期）。debug原生运行，含content/file、失败回滚、暂停定位停止、Activity/后台/系统命令 |
| Android release探针 | build apk --release --target lib/p1_focus_probe.dart，再run_android_focus_probe.ps1 | [构建](release-probe-build.log)退出0；[运行](release-probe-run.log)退出0，5检查通过；[新鲜证明](release/release-focus-proof.json)releaseMode=true、PID30887、新令牌、零消费者/无焦点请求。探针APK哈希与普通包分开 |
| release命令纠错 | 尝试flutter test ... --release | [失败日志](android-release-tests.log)退出64，SDK不接受此参数；没有写通过。改用上述显式release入口实际运行完成本批焦点验证；没有声称整套7项以release运行 |
| Windows v2.2 | flutter test integration_test/windows_local_playback_test.dart --device-id windows --reporter expanded | [日志](windows-final.log)退出0、3原生测试通过：共享身份/控制/资源、确认前失败回滚、自然结束/坏文件；释放后文件rename成功。默认本机输出，无听感/物理键验收 |
| 公共质量及普通构建 | tool/check.ps1 -Mode All -EvidenceDirectory .../final-checks | [摘要](final-check-summary.log)退出0；锁/20文件及05哈希/格式通过，analyze无问题，[39共享测试](final-checks/tests.log)通过；[Android](final-checks/android-build.log)和[Windows](final-checks/windows-build.log)普通lib/main.dart release均构建通过 |
| 最终Android普通包 | install -r；am start -W；pidof | [安装Success](normal-install.log)，[启动Status ok/UNKNOWN](normal-start.log)，[PID32351](normal-pid.log)。命令启动/进程存在，不冒充普通UI人工验收。测试入口已替换 |

准确命令工作目录均为clients/flutter；本地项目代理/Gradle缓存沿用现有helper，仅子进程配置。工具Git2.55.0、ADB37.0.1、JDK21.0.12.1，Flutter3.47.9/Dart3.13.7；见[工具记录](tool-versions.log)，工具链由实际双端构建复证。SDK XML v3/v4非致命警告仍保留，未安装/升级工具。

可复制完整命令见[commands](commands.md)。[文档检查](document-check.json)核9份相关文档无缺失链接、20冻结哈希一致；[GraphFlow定向回执](graphflow-index.json)保存18次请求、无工具错误，部分文件由自动索引先更新故返回unchanged。本批改了原生代码，重验必须完整构建安装，不能只hot reload。

独立审阅发现迟到回包竞态并已红绿修复，完整意见/未判断事项见[review](review.md)。没有把限定审阅当全仓审计或重复审阅盖章。[命令退出码](command-results.json)与原始日志一同保留。

## 普通成果怎样启动与验收

- 手机已装普通jj_music_mobile。解锁后打开，点击“打开自有样本播放诊断”。播放A后确认数增加一次、位置前进；暂停后位置停住；“定位3秒”后点继续，同次确认数不增加；停止后消费者应归零。样本仅12秒，结束停止属预期。
- Windows运行 clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe；保留整个Release目录，执行相同诊断操作。本批实际启动的是Windows原生测试应用；普通release本批只构建，未另做可视人工按钮检查。
- 当前Android普通APK为48,509,302字节，SHA256 `127ae29143ddec8f79474de62be745c2d34d71945cb927048e2dcd92d03f2130`。Windows普通EXE及整个bundle摘要见[产物](normal-artifacts.json)、[目录](windows-bundle.json)。Android沿用内部debug签名，不是发行。

开发者重跑release焦点检查（会替换本诊断包，不影响私人媒体）：

```powershell
.\tool\flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_focus_probe.dart')
.\tool\run_android_focus_probe.ps1 -DeviceId 35a63609 -EvidenceDirectory ../../graphflow-out/focus-run
# 必须恢复普通入口，不把专用探针交给用户验收
.\tool\check.ps1 -Mode AndroidRelease
adb -s 35a63609 install -r build/app/outputs/flutter-apk/app-release.apk
```

## 未验证与下一批

本批真实系统焦点竞争来自本应用内独立AudioFocusRequest，证明本机OS transient-loss路径；不能代替另一应用/电话/导航/蓝牙/厂商完整矩阵。旧listener是明确故障注入；已出队消息是受控平台边界模拟；焦点拒绝和跨轨真实OS竞态未诱发。没有声称人工听感、Windows物理媒体键/输出拔除、release全量7项或普通UI可视验收通过。

下一批最小建议：回到A03/A05、TC57，自有可延迟/未知长度本地输入诱发真实持续加载，验证暂停/取消/新意图不等旧Future，双端分别收原始事件；不提前实现网络Broker。独立engine/服务死亡、不可seek/未知时长、Windows输出失效等G-L缺口继续保留。云端CI与此前基础维护独立审阅状态不由本次限定修复审阅替代。

本批实现取舍：Git无HEAD且禁止提交，使用工作区before/差异/哈希而非依赖提交的worktree流程；设备恢复后以真实Android红绿替代新增JVM依赖。若误把这些证据当历史提交或全设备测试会扩大结论，故明确留边界。未提交、推送、合并或发布。
