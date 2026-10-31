# A05：Windows未知时长/不可定位的限定输入验证

2026-10-31，AUTH-P1-UNKNOWN-20261031限定目标完成。基线86053e5（此前已推送），本批保留未提交差异，不自动提交/推送。owner Codex串行Windows/ConfigIntegrator/文档协调；旧Electron只读。A03—A08整体review/G-L仍未通过。

## 代码与真实输入

复用既有冻结PCM16 mono/16000Hz/12秒WAV的载荷，在诊断MediaStreamSource中显式unknownDuration=true时不设置Duration；默认profile仍12000ms。source.CanSeek=false为该样本输入能力，poll直接读取实际PlaybackSession.CanSeek/NaturalDuration，定位前按实际CanSeek拒绝且不写Position。没有覆盖原生状态或把已知WAV文件伪装成Android未知输入，没有网络、新媒体、新库或正式UI。

原生三个文件共13行左右的基础差异、新windows_unknown_duration_test.dart；另因回归故障必要修复smtc_probe.cpp，实际补丁以source.patch为准。共享p1-a02-v2.2/20冻结哈希、05/协议快照1、锁文件未改。canSeek仅原生诊断观测，不是新增共享能力合同；直接native拒绝定位的证明不等于共享seek ack拒绝/正式界面禁用已实现。

依据：[MSS Duration官方定义](https://learn.microsoft.com/en-us/uwp/api/windows.media.core.mediastreamsource.duration?view=winrt-28000)明确默认0为未指定，[PlaybackSession.CanSeek](https://learn.microsoft.com/en-us/uwp/api/windows.media.playback.mediaplaybacksession.canseek?view=winrt-28000)为实际位置可否修改的能力。实际编译及运行分别验证，不单靠文档猜测。

## 证据及结果

| 检查 | 实际结果 | 日志 |
| --- | --- | --- |
| 测试编译装配 | helper参数误用已修复，失败保留，不作功能反例 | test-compile-error.log |
| 行为红色基线 | 2项canSeek字段未实现，EXIT1 | red.log |
| 初次实现 | 真实播放/0和12000/拒绝seek/EOS已发生；旧快照closed断言失败 | green.log |
| 最终新增场景 | 2/2，约14秒、EXIT0 | final.log |
| 原播放后再缓冲 | 4/4 | windows_rebuffer_test.log |
| 原持续加载/取消/关闭重试 | 6/6 | windows_loading_test.log |
| 原普通文件播放/定位/资源 | 3/3 | windows_local_playback_test.log |
| 系统媒体控制最终 | 1/1，pause/play/seek/next真实OS回路 | windows-media-fixed.log；额外候选对照另见windows-media-candidate.log |
| Windows不同用例合计 | 16项通过；重复SMTC不重复计数 | 上述最终日志 |
| 共享/格式/分析 | 39/39；43文件0变更；No issues | quality/ |
| 冻结/05/锁 | 20文件及权威哈希一致、依赖锁未变 | baseline与Quality/Release检查 |
| 普通WindowsRelease | 最终构建10秒通过；8秒窗口观测PID49240/句柄403576 | release-final/windows-build.log、normal-artifacts.json |
| Android本批 | 在线身份35a63609一致；未改代码、未构建/安装/运行 | 仍以前批service-loss-20261031为最新实测 |

observations.json保留完整raw。unknown输入首次确认时duration0/canSeek=false/实际位置381ms；已知对照12000/canSeek=false/位置379ms。两者nativePlaying=true且共享确认1；定位9000返回seek-unsupported，随后位置未跳到目标。暂停恢复不重记；unknown正常供样至12秒出现真实ended，之后释放；两项最终closed=true/readers0。初次closed断言读旧lastHost并非泄漏，最终等待新poll观测而没有降低资源要求。

## SMTC回归故障与修复边界

首轮SMTC失败error:true，添加白名单stage/HRESULT后确认为owned-properties/0x80070015(ERROR_NOT_READY)，发生在读取本应用候选属性、还未发送pause。实际音频/RPC等服务只读状态为Running，没有启动/修改服务。探针原全局catch遇到任一未就绪本应用候选就退出。

修复仅探针：保留本app source及目标PID title筛选，对属性ERROR_NOT_READY跳过候选、最多20轮发现扫描/100ms间隔，不重发已经发送的transport命令；其他错误仍报告受控stage/HRESULT，不输出其他应用媒体元数据。命令发送后即使timeline失败也不重试next。1.9秒只是显式间隔，Windows异步API自身没有严格超时，不能声称整个调用2秒上限。

windows-media-final.log保留补头文件前的编译错误；windows-media-fixed.log完成真实四命令，但skippedNotReady0，不单独证明跳过分支已实机触发。为此保留一个正常未播放Release窗口，再跑windows-media-candidate.log作真实候选对照，实际pause/play/seek/next四次均skippedNotReady=1且found/accepted=true、EXIT0，证实跳过路径确被触发。静态追加审阅未发现重要缺陷；阶段诊断Minor已补精确stage，详见review.md。

首个release/windows-build.log失败LNK1104：前批由agent启动的普通Release PID46856/47532仍存在、占用同一个EXE；核完整路径后正常CloseMainWindow两者，未终止其他应用。最终另目录release-final构建通过。未覆盖原失败。两个旧进程先前在受限调用里不可见，不能据此断言曾退出；此处以本批获准进程查询为准。

## 简单验收与下一步

双击 `clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe`，保留整个Release目录；普通程序已作8秒启动窗口观测，按钮/听感本批未人工验。普通UI可检查自有A播放、暂停/继续、定位3秒和停止资源0。未知时长/不可定位为专属自动化输入，不给正式UI增加故障按钮；在clients/flutter运行commands.md新测试，应2项通过。

Android现有APK未变，本批不要求重装。未知时长/不可定位该端尚缺受控输入，固定WAV头带明确长度不能当证明；下一批优先A03自有未知时长/不可定位输入，先核实际Media3/系统编码供样路径，再验证。共享能力协商/用户可见定位退路、自然超时/压力、长Doze/独立engine及系统杀服务/进程、外设听感仍未完成。仅推进P1，不进入P2/在线/下载/正式UI；无提交/推送/发布/全局修改。

