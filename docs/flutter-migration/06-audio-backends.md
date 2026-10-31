# 播放后端与依赖候选

分类P/D/H；本页保留候选研究。当前P1薄Media3/WinRT已落地并有局部实测，选择及限制以ADR-0003和20261031阶段报告为准，不代表生产全面接受。一个PlaybackBackend接口允许不同实现，不能为统一插件名丢失产品规则。

候选接受证据还须满足05 C-05的事件归一化交付：A03/A05分别固定真实API/版本与原始序列，说明项目播放确认、去重、结束/中断及限制；表的具体条件只有原型后才能填写。API同名playing/started不直接代表项目确认，也不以命令返回成功替代。映射规则权威只在05，具体平台证据按任务索引分文件保存；本章不预填未经运行的判定表达式。

## 候选与能力

| 项目 | Android just_audio组合 | Windows direct media_kit | just_audio_media_kit | just_audio_windows |
| --- | --- | --- | --- | --- |
| 核心 | Media3 ExoPlayer | libmpv/FFI | just_audio到media_kit桥接 | C++/WinRT MediaPlayer |
| 文件/URL/seek/速度 | 文档/源码有路径 | 同左 | 映射路径 | 同左 |
| headers | 原生/插件本机代理 | Media headers路径 | 文档有未实测边界 | 原生URI路径需代理验证 |
| content URI | 下层DataSource支持，长期授权/不可seek仍待真机 | 不属于Windows能力 | 不适用 | 不适用 |
| Range/刷新URL/端到端取消 | JJ合同待验 | 待验 | 待验 | 待验 |
| 后台/系统控制 | audio_service+audio_session，engine生命周期待验 | 另配SMTC和窗口策略 | 另配 | 播放插件不等于完整SMTC |
| EQ | AndroidEqualizer有接口 | 需评估滤镜/桥接 | 无统一保证 | 所核源码有空实现分支，不能以成功返回验收 |
| 频谱/交叉渐变 | 无本次证明完整接口；需采样/双轨实验 | 同左 | 多player需特别验证 | 待验 |
| 无缝 | 文档声明，需具体样本听测 | 固定构建待验 | prefetch默认关闭且标实验性 | 待验 |
| 输出设备 | Android路由另验 | 有枚举/选择路径 | 不保证完整暴露 | 待验 |
| 格式/功耗/独占 | 随设备/系统/配置测 | 随二进制构建测 | 同左 | 随Windows编解码器测 |

来源：[just_audio](https://pub.dev/packages/just_audio)、[audio_service](https://pub.dev/packages/audio_service)、[audio_session](https://pub.dev/packages/audio_session)、[media_kit](https://pub.dev/packages/media_kit)、[桥接](https://pub.dev/packages/just_audio_media_kit)、[WinRT插件](https://pub.dev/packages/just_audio_windows)。这些是候选能力资料，不是本项目通过证据；实施时核对具体发布包与源码是否一致。

推荐优先原型Android组合和Windows direct media_kit，备选WinRT。插件存在不保证事件顺序、取消、预载或内存安全；load/play Future的完成含义必须转换为C-02，不能await play误当即时确认。

## 生命周期及系统集成

audio_service当前上游服务为MediaBrowserServiceCompat/MediaSessionCompat；just_audio解码用Media3，并非组合已经变成Media3 MediaSessionService。服务/engine独立于Activity的实际存活必须A04核验。销毁engine不能宣称Dart继续；恢复用C-03。

参考：[服务源码](https://github.com/ryanheise/audio_service/blob/minor/audio_service/android/src/main/java/com/ryanheise/audioservice/AudioService.java)、[engine源码](https://github.com/ryanheise/audio_service/blob/minor/audio_service/android/src/main/java/com/ryanheise/audioservice/AudioServicePlugin.java)、[官方Media3服务](https://developer.android.com/media/media3/session/background-playback)。分支资料可漂移，A01将使用具体版本/提交记录。

Android焦点、duck、耳机拔出只能选一个权威处理者，避免audio_session和播放器自动策略重复；初始化后统一配置。系统音量与应用音量/过渡增益分开。

Windows `smtc_windows`有Rust依赖，排除。`audio_service_win`有C++/WinRT基础路径，但所核上游setQueue/setState、时间线、线程转发/封面迟到/解除监听不足以直接确认完整可靠；只进A06候选。失败后可批准薄C++/WinRT SMTC适配，不默认大量C++重写。[插件](https://github.com/HemantKArya/audio_service_win)、[微软窗口接口](https://learn.microsoft.com/en-us/windows/win32/api/systemmediatransportcontrolsinterop/nf-systemmediatransportcontrolsinterop-isystemmediatransportcontrolsinterop-getforwindow)。

## 网络与文件

插件本机代理不是JJ安全策略。在线只能使用经授权Broker/Transport；不能把raw URL交解码器绕过DNS/redirect策略。允许协议最小化，检查后端是否访问额外子资源。Android回环HTTP在release验证，失败可研究自定义DataSource，不能全局放宽。

元数据优先评估纯Dart [audio_metadata_reader](https://pub.dev/packages/audio_metadata_reader)，其File API不证明content URI/安全写入全支持。确证缺口后再评估 [TagLib](https://taglib.org/) C++及许可；不默认引入基于Rust的metadata方案。

## 供应链与决定门

包许可逐项登记；media_kit包装MIT不概括mpv/FFmpeg。核固定SDK/插件、ABI、原生DLL/so、构建配置、来源/摘要、许可证与源码提供方式；检查安装脚本是否拉取原生资产。不将pub版本和main分支当同产物。[mpv版权](https://github.com/mpv-player/mpv/blob/master/Copyright)、[FFmpeg许可](https://ffmpeg.org/legal.html)。

A01/A08只接受本地证据；B系列检查网络/JS/下载；生产仍需后台/蓝牙/休眠/输出/格式/功耗/听感。失败可换候选或缩小公开能力，并重跑受影响测试；不以返回成功、包评分或参考播放器使用作为验证。

