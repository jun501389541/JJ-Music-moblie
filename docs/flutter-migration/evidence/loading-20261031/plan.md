# A03 / TC57 Android初始持续加载子批

2026-10-31，用户按文档继续开发授权；登记AUTH-P1-LOADING-20261031，Codex串行兼Android/A02维护、ConfigIntegrator和文档协调。实际根mobile，旧Electron只读。GraphFlow context成功；部分锚点是历史before副本，已定点读取当前源码而不把副本当当前实现。plan无LLM密钥时返回agent桥接，intent/decomposition已submit并merge complete。

消费R4、p1-a02-v2.2共20文件，协议/快照格式1。开工逐一匹配冻结摘要。只改Android LocalHost、新OwnedReadGate、Android专用集成测试及证据/状态/交接；如果发现共享回归，先登记归属及版本再整合。没有新增依赖、音源、网络/Broker/P2/正式UI或全局配置。

## 设计及验收

通过Media3实际DataSource.Factory包装现有自有content URI，仅显式`?gate=initial`启用，普通路径不门控。阻塞发生在ExoPlayer loader线程的真实read，不延迟Dart Future来伪造加载，不注入state2。数据仍为已冻结12秒PCM WAV；不访问私人媒体。允许/取消由控制线程发信号，不在主线程等待条件。门控最多15秒，释放前cancel唤醒，保留实际open/read/close计数；历史最多8项。

1. 先建4个真机失败场景：pause/stop/cancel/new-play；当前缺门控入口应失败，保存红例退出码。
2. 实现最小门控，要求实际reader=1、bytesRead=0、原生state2，持续至少650ms且无播放确认。
3. pause立即提交；允许读取后仍paused、无确认，只有明确resume并原生位置推进后确认一次；重复暂停/继续不重复确认。
4. stop/cancel/new-play在读取仍等待时提交；必须在2.5秒内观察旧读取已close、新曲按需确认。晚到allow不能复活旧请求；不把Dart消费者归零当close证据。
5. 回归Android现有本地/焦点/生命周期、Windows本地原生用例；Quality及双端普通release构建。必要普通入口重装，分开记录debug真机、普通release编译/启动、人工可视和听感。
6. 唯一独立只读审阅，普通文档写证据和交接，定向index。无HEAD时用before副本/哈希/可读差异审阅，遵守用户不提交及保留工作区要求。

官方API依据：[DefaultMediaSourceFactory.setDataSourceFactory](https://developer.android.com/reference/androidx/media3/exoplayer/source/DefaultMediaSourceFactory)、[DataSource](https://developer.android.com/reference/androidx/media3/datasource/DataSource)。已有Media3固定1.11.0，实际编译和原生运行决定本版可用能力。

## 限制

本批仅Android“初始加载”读取反例，不能等同已经开始播放后的再缓冲、未知时长/不可seek提供方、跨应用焦点或完整TC57。Windows本批仅已有真实本地回归，持续加载实验仍未验；不拿另一端或fake替代，不放行完整G-L。

最终命令、退出码、差异及结果见同目录report.md；失败保留，不删测试降门槛。
