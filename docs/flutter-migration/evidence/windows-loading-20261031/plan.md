# A05 / TC57 Windows初始持续加载小批

2026-10-31，AUTH-P1-WINLOADING-20261031，用户继续执行授权。Codex串行兼Windows平台维护、A02维护、ConfigIntegrator及文档协调。实际根mobile；GraphFlow context/plan成功，intent/decomposition桥接已submit+merge complete。部分锚点指历史Android副本，已定点读当前Windows实现和最新交接，不沿用完成声明。

前置：独立Flutter已存在；共享R4/v2.2、20文件哈希核对一致，协议/快照1；Windows工具链由首轮真实编译复证。Git feat/flutter-a01-a02，无HEAD/暂存/远端，改前副本保留before/；新出现的未跟踪.graphflow/保留，不扫描/清理其私有内容。旧Electron仅只读。

## 范围、实现和验收

只改local_playback.cpp、新owned_gate_stream.h、Windows专属integration_test/windows_loading_test.dart及本批文档。无新依赖/codec/接口/冻结变化。普通file URI保持原路径；额外诊断方法接受显式传入的有界PCM WAV字节（测试只取既有冻结样本），创建一次性owned-gate引用。上限2MiB/输入、注册与观测各最多8项、同时未完成read最多16。

通过真实MediaSource.CreateFromStream和自实现IRandomAccessStream.ReadAsync，第一字节在后台等待允许或取消。先计入未完成read再切线程，保留对象强引用；复制和游标受锁保护；15秒预算。不把等待放平台线程，不延迟Dart Future伪造原生状态，不使用网络/私人媒体/静音保活。

release先cancel，再Close播放器/Source/stream；只有未完成read归零才回Success释放回执。平台WM_TIMER只在必要关闭等待期间启用，完成就移除，注册表防已排队timer在销毁后解引用旧宿主。不能依赖Dart继续poll，因为backend.close会取消Dart timer。

1. 先建4个失败用例，记录尚无registerOwnedGate的RED；不是既有播放逻辑缺陷。
2. 实现门控，验证read阻塞650ms、零字节、ready=false且无确认，记录真实WinRT原生枚举。
3. pause后allow仍paused/零确认，明确resume后只确认一次；stop/cancel/new-play提交不等读取完成，实际旧read归零/内存释放后回执。旧allow不能复活。
4. 加无Dart poll的直接原生释放用例；回归Windows本地/系统媒体/组件恢复，Android既有加载若指定设备在线则真机复跑。Quality与双端普通release构建，再恢复普通Android包。
5. 唯一独立只读审阅，按实际结果保存差异、时序、退出码、状态和handoff，定向index。未测的再缓冲/未知时长/外设不放行G-L。

官方依据：[CreateFromStream](https://learn.microsoft.com/en-us/uwp/api/windows.media.core.mediasource.createfromstream)、[IRandomAccessStream](https://learn.microsoft.com/en-us/uwp/api/windows.storage.streams.irandomaccessstream)、[C++/WinRT并发](https://learn.microsoft.com/en-us/windows/apps/develop/cpp-winrt/concurrency)。后续一次网页查询Transport closed，实际字段进一步核本机Windows SDK10.0.26100.0的impl/Windows.Media.Playback.0.h：Opening=1、Buffering=2、Playing=3、Paused=4；不把AndroidSTATE_BUFFERING代入。实际初轮观察Opening，不声称已经证明播放后buffering恢复。

Git无HEAD且用户禁止提交，保留同工作区，用before/哈希和可读补丁审阅，不建立依赖提交的工作树/提交记录。最终结果见report.md，失败保留，未执行不标通过。

## 实施中实际调整

- 独立审阅发现关闭异常重试假成功：先注入复现sourceClosed=false红例，再逐阶段清理/显式重试修复；完整6项及额外首失败阶段断言复验。没有再派同一差异审阅。
- Windows同一flutter test多入口时后续调试连接未建立，改成每入口独立进程并分别验证；保留原失败，不修改Flutter工具或降低用例。
- Android回归发生真实前台服务登记超时崩溃，已按用户范围内常规前置修复登记allowlist：LocalHost/PlaybackService及服务注册专属测试。每次start先promote后ack，待登记未清零时不提前stop；用户解锁后实际9项通过。没有称原竞态确定性触发率或完整Doze矩阵通过。该补充为执行者自检+真机验证，Windows独立审阅不覆盖此后加的Android差异。
- 根.gitignore补忽略新生成的.graphflow/，原目录内容保留，不读取私人对话。无Git暂存/历史删除。
- 最终analyze发现新增测试单行if缺花括号，按常规lint修复，使用新verified-checks目录复验，原失败日志保留。
