# ADR-0003：播放与系统组件候选

状态：**提案**；依赖版本和原生二进制未批准/锁定。

2026-10-30 PREP-01补充：[本机计划](../tasks/prep-01-local-plan.md)记录上游候选快照和审计时点。Android组合及Windows direct media_kit推荐保持；未下载/锁定/批准包或DLL。A01先建无播放器依赖诊断壳，使用前核SDK/Gradle约束、ABI、发布源码/原生资产摘要与许可；A03/A05实测事件映射后再作选型结论。

同日AUTH-ENV后续：实际环境SDK固定为Flutter3.47.9/Dart3.13.7，提交与官方ZIP摘要见[EV-ENV-001](../evidence/EV-ENV-001.md)。这只固定开发工具，不批准播放器候选或原生媒体DLL；pubspec/产品lock尚不存在。A01默认compile/target SDK36、NDK28.2.13676358来自该Flutter实际源码，不能把doctor检测到最高已装SDK37当项目目标或最低系统承诺。

推荐先验证 Android just_audio + audio_service + audio_session，Windows direct media_kit。备选 Windows just_audio_windows/WinRT；Android 仅在证实缺口后采用薄 Media3 适配。系统媒体控制独立适配，不强迫两端使用同一插件。

选择理由与能力矩阵见 [后端](../06-audio-backends.md)。just_audio_media_kit 的桥接限制、audio_service 的 engine 生命周期、SMTC 线程与释放均需验证。排除已知需要 Rust 的 smtc_windows 路线。

不复制 Harmonoid 受限代码，不把 media_kit 包 MIT 当全部 DLL 许可。固定 SDK、包、ABI、二进制来源/摘要、构建选项和许可后才能锁依赖。

退出：主要能力/维护/许可不满足则换备选并重跑受影响合同；不为保住选型改变产品规则。G-L 是本地风险结论，G-B/G-D 与生产检查另行执行。

## 2026-10-31 P1本地原型选择（非生产全面接受）

候选审计已固定Pub元数据留evidence/p1-a/20261031。just_audio0.10.6公开Dart playing为意图，不能直接取得完整原生抑制/运行查询；Windows插件0.2.3保留自动CommandManager/MediaPlaybackList且无周期权威查询。按E1选择薄Media3 1.11.0及系统WinRT备选，直接取原生样本，不为保插件改变语义；候选Pub包已从最终运行lock移除。WinRT不引第三方codec DLL/Rust；C++20自编译，Media3按Apache2官方Maven依赖，实际AAR/POM哈希留档。两端核心运输/资源、系统控制和恢复已实测，完整TC57/故障矩阵缺口仍使G-L不通过。映射、限制及原型处置见阶段报告，不把本决定扩大为生产全格式/长期后台批准。
