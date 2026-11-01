# A03/A05 自有读取自然超时与故障后恢复

2026-11-01，AUTH-P1-TIMEOUT-20261101限定目标完成。分支codex/seek-boundaries，保留前批9项补充测试及全部未提交修改；本批只新增integration_test/read_timeout_recovery_test.dart及证据/交接，没有生产代码或合同变化。消费v2.3/21冻结，旧Electron/全局/依赖/UI不动，不提交推送发布。A03—A08整体review/G-L仍未过。

## 实际场景

同一测试按平台装配不同已有输入：Windows MediaStreamSource的自有PCM门控；Android Media3自有content WAV的rebuffer门控。先共享确认A且位置>300ms，再真实state2/read blocked；不放行、不主动取消、不注入故障，等原有约15秒读取预算自然耗尽。随后要求原生error、共享backend-error及paused、消费者0/gate.closed/readers0，才播放普通自有B。B确认和位置增长后迟到allow旧A，短窗350ms检查A未复活、确认和错误数不增，再Stop清空资源。

这不是首次prepare的8秒Future超时测试，也不把fake error或主动取消当自然超时；没有更改超时阈值或原生重试策略。

| 验证 | 实际结果 | 证据 |
| --- | --- | --- |
| Windows原生超时→释放→B | 1/1、约17秒、EXIT0 | windows.log |
| Android真机超时→释放→B | 1/1、约20秒、EXIT0 | android.log |
| 共同测试 | 51/51 | quality-final/tests.log |
| 格式/分析 | 48文件0变化/No issues | quality-final/format.log、analyze.log |
| 冻结/05/锁 | v2.3 21摘要及权威哈希、锁未变 | Quality检查 |
| Android普通入口恢复 | 原已验APK哈希一致；重装Success、COLD启动ok/PID22482 | install.log、android-start.log、normal-artifacts.json |
| 普通Release构建/启动 | 两端均未重新构建；Windows普通程序未重启；Android仅恢复原包 | normal-artifacts.json |

实际计时从已观测buffering开始：Windows14985ms、gate累计等待15078ms、原生error样本1，最终sourceClosed/streamClosed/closed=true、readers0/cancelledtrue；Android15848ms，门控累计等待和实际样本详见observations.json。不是跨设备性能基准或严格15秒响应SLA。

Android最初受限环境ADB列表为空；主机环境复核用户连接的仍为35a63609/2211133C/fuxi。用户确认连接后按真实前台资格执行，无绕锁/改系统息屏，仅临时KEEP_SCREEN_ON并finally清理。没有扫描个人曲库或真实音源。

## 命令、审阅和限制

cwd clients/flutter：

```powershell
flutter test integration_test/read_timeout_recovery_test.dart -d windows
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/read_timeout_recovery_test.dart','-d','35a63609','--reporter','expanded')
./tool/check.ps1 -Mode Quality -EvidenceDirectory <本批目录>/quality-final
```

两端新场景首次通过，未复现需要修复的生产故障，因此不制造红色失败或改动原生代码。quality/保留首轮清理if缺花括号的lint失败；仅补块语法，最终quality-final全过。两端运行在该纯风格修正前，未因相同控制流重复设备测试。test-hash.json记录最终源文件；observations.json由两份原始日志提取，before.log/after.log记录工作区。

按executing-plans/requesting-code-review一次只读timeout_review，未写文件/运行测试，未发现Critical/Important。先确认/缓冲/自然等待再错误释放及B恢复的链路没有提前allow/cancel的假阳性。明确边界：原生只断言通用error，具体超时归因结合已有fixture源码和15秒等待；350ms仅短期不复活；两端输入路径不同，不能推广到普通URI/网络或全部后台故障。关闭指标不是独立OS句柄检测。

现有普通程序仍可验收播放A、定位3秒、暂停继续、停止资源0；新超时场景没有增加正式UI按钮。无需更换个人数据或Windows安装包。下一小批建议A03/A05重复加载/停止与双资源容量压力，再补长后台/独立engine、输出丢失和听感等剩余矩阵；源码预发布和安装包不因此更新。
