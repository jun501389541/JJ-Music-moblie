# A05 / TC57：Windows真实播放后再缓冲

2026-10-31，AUTH-P1-WINREBUFFER-20261031限定目标完成，owner Codex串行整合到独立mobile工作区。A03—A08整体仍review，G-L不因本批局部通过而放行。无提交/推送/发布、全局配置、旧Electron修改。Git为feat/flutter-a01-a02、无HEAD/暂存/远端；全部既有未跟踪工作保留。

## 实际改动与输入

新增Windows诊断专用owned_pcm_source.h和windows_rebuffer_test.dart；local_playback.cpp增加registerOwnedPcm，复用原生gate注册、取消和延迟释放回执；owned_gate_stream.h仅增PCM标志/游标。普通file URI及原initial IRandomAccessStream门控不变。没有改共享业务、队列/重试规则、UI、依赖或媒体。共享冻结p1-a02-v2.2的20摘要、05权威合同、协议/快照1均保留。

仅显式传入现有冻结tone-long.wav：384044字节，PCM16/mono/16000Hz/12秒；校验固定头及长度。WinRT MediaStreamSource的SampleRequested真实供样，100ms一块，供给2秒PCM后延后请求，用GetDeferral并定期ReportSampleProgress；BufferTime250ms。CanSeek=false仅属于该诊断输入，不代表普通文件能力或已验证不可定位矩阵。仍使用现有同一个MediaPlayer和状态采样路径，没有注入Buffering或把意图布尔值当播放证据。

原ReadAsync预读难以保证可控的播放后饥饿，未盲改InputStreamOptions.None短读合同；使用系统支持的样本请求机制，未引入新解码库或切换生产后端。依据：[MediaStreamSource](https://learn.microsoft.com/en-us/uwp/api/windows.media.core.mediastreamsource)、[SampleRequested及异步供样](https://learn.microsoft.com/en-us/uwp/api/windows.media.core.mediastreamsource.samplerequested)、[BufferTime](https://learn.microsoft.com/en-us/uwp/api/windows.media.core.mediastreamsource.buffertime)、[InputStreamOptions](https://learn.microsoft.com/en-us/uwp/api/windows.storage.streams.inputstreamoptions)。签名经本机SDK编译及实际运行核验。

释放先Cancel、撤销事件、关闭player/source；没有IRandomAccessStream的PCM路径明确完成stream关闭阶段。工作计数在首次协程挂起前建立，包含deferral.Complete，归零后既有平台WM_TIMER才回复release；最大等待15秒，取消唤醒。普通路径的分阶段Close/失败重试保证保留。sourceClosed/streamClosed为实际Close调用成功的观测，不是独立OS句柄检测。

## 实际验证

| 检查 | 本批结果 | 证据 |
| --- | --- | --- |
| 先失败 | 4项MissingPluginException，EXIT1 | red.log |
| Windows播放后再缓冲4场景 | 4/4，EXIT0 | attempt-1.log、observations.json |
| 原initial加载/释放/关闭异常重试 | 6/6，EXIT0 | windows_loading_test.log |
| 原普通本地播放/竞争/资源 | 3/3，EXIT0 | windows_local_playback_test.log |
| 系统媒体控制真实OS回路 | 1/1，EXIT0 | windows_media_test.log |
| UI重连/组件/进程恢复既有入口 | 1/1，EXIT0 | runtime_recovery_test.log |
| 共享测试 | 39/39 | quality/tests.log |
| 格式/静态分析 | 41文件0变化/No issues | quality/format.log、analyze.log |
| 冻结/05/锁依赖 | 20摘要和权威哈希一致、锁未变 | baseline.log、Quality检查、Release检查 |
| 普通Windows Release | 构建16.4秒成功；2秒观测PID46856/窗口6293364；独立8秒复核PID47532/窗口600200 | release/windows-build.log、normal-artifacts.json |
| Android本批 | 未改生产源码；未编译/启动/真机运行 | 前批rebuffer-20261031仍是Android最新依据 |

四项均先真实nativeState3、位置增长至300ms以上及共享确认一次，再出现nativeState2/position750—760/nativePlaying=false，gate.bytesRead64000/readers1，证明是播放后饥饿而非首次Opening。恢复后仍native-1及原确认；暂停放行后不播放、位置稳定直到显式resume；Stop与新B意图提交0ms，不等待长供样Future。新B确认后通过共享transition关闭A；迟放行不复活旧A/不重记确认。最终四项均readers0、closed/sourceClosed/streamClosed/cancelled=true。数据由日志提取保留完整raw，不能把单个同名布尔值视为确认。

独立只读审阅未发现Critical/Important，见review.md；执行者完成真实测试、整合及构建。基线before、两份patch、新文件哈希可复核；diff初次路径层级不匹配已纠正，见diff-note.txt，不覆盖基线。GraphFlow结果另记index.log。

## 简单验收与边界

Windows直接双击 `clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe`，保留整个Release目录。普通入口已启动；按钮/听感本批未人工验。

1. 点击“打开自有样本播放诊断”→“播放样本A”，应见当前A、位置增长、确认数1。
2. “暂停”后位置停止，“继续”后继续增长；“定位3秒”接近3000ms。
3. 快速“切换样本B”再“停止”，资源数最终0；UI重新连接/重建组件应保留同一会话状态。
4. 新增再缓冲四场景用commands.md中的专属集成命令复跑，应显示4项通过；普通UI没有此门控按钮。

Android现有APK位置及哈希见normal-artifacts.json，本批未安装，不要求用户重装来替代Windows验证。此前手机35a63609的前台再缓冲证据见前批报告，后台合法起播资格/长Doze仍未通过。未知时长/普通不可seek、15秒自然超时/压力、独立engine及service死亡、输出丢失/物理媒体键/听感和其他G-L缺项仍开放。下一小批建议先核A03/A04后台起播资格与生命周期矩阵，只有用户选定手机在线且合法前台/后台条件满足时实测，不绕锁屏或放宽验收；不自动进入P2/正式UI/网络。


启动边界补记：2秒后跨工具调用未找到首次PID，原因未确定；独立8秒复核exited=false。该证据支持实际启动窗口，不证明跨调用持续存活、无人关闭或人工验收；用户可直接双击EXE自行检查。
