# A04 焦点安全子批计划与执行账本

2026-10-31，AUTH-P1-FOCUS-20261031。目标是修复当前Android宿主焦点资源释放并增加可重复中断验证，不签发完整G-L。GraphFlow context成功；plan返回无服务商密钥的agent桥接，已依次提交intent/decomposition并merge complete。串行实施，非占位计划。

## 范围与合同

Codex兼Android平台维护、A02公共测试维护、ConfigIntegrator及文档协调。初始文件允许范围已在status登记：LocalHost.kt、Android焦点集成测试、Windows本地测试日志路径、README/status/handoff及本证据。初始消费R4/p1-a02-v2.1、共享19文件只读；独立审阅发现迟到回包竞态后，按归属扩展allowlist，由A02维护者串行修改其中1个适配文件、补1个测试并冻结v2.2共20文件，详见review.md。公共接口、协议/快照1、锁文件、05权威合同和旧Electron未改。另有显式release探针及运行脚本用于真实release验证，不进入普通装配。

现有手动焦点策略维持：loss立即物理暂停，再经唯一共享命令入口提交paused；gain不自动play。系统允许的音频焦点管理属于薄适配，队列/随机/重试等不放原生。官方依据：[Android音频焦点](https://developer.android.com/media/optimize/audio-focus)、[AudioFocusRequest](https://developer.android.com/reference/android/media/AudioFocusRequest)。ExoPlayer自动焦点是另一种管理方式；本批不同时开启两套管理，不改变现有手动方案。最终生产方案仍需P2入口审阅。

## 小步与验收

1. 核独立Git根、规则/合同/现有实现及设备；保存before文件副本。预期旧源码不变、冻结匹配。缺设备只限制真机，不伪通过。
2. 先增加观察/真实系统焦点竞争探针及两个失败测试。预期复现最后release和暂停未清焦点请求，保留红例。
3. 最小修复：pause/stop/最后release/启动失败归还焦点；新请求有新代次；迟到callback及尚在原生队列的旧焦点命令失效。预期同一失败测试转绿。
4. 补stop期间竞争释放不重播、明确恢复不重复确认、旧listener故障注入；跑Android本地/Activity回归，Quality及Windows本地回归。Android尝试release原生运行，双端普通release独立重建。各结果分别记录，失败先定位修复。
5. 一次独立只读审阅、核真实差异及产物，更新status/handoff并定向index；不扩大后续任务。

## 账本

- 基线：feat/flutter-a01-a02，无HEAD、暂存或远端，根为mobile。旧端HEAD4f47d10cd4d8deb0118e35198105f11bee754246，tracked diff为空。
- 设备初查不在线，用户随后连接；重新核为35a63609/Xiaomi2211133C/API33、Awake。不改手机系统设置。
- RED：android-red.log完整退出1，2项失败；自然结束后focusHeld仍true；实际OS transient loss已收到-2且物理暂停/共享paused，但焦点请求仍未清。focusHeld仅表示宿主仍持有request引用，不是OS独占焦点查询。
- GREEN初轮：android-green-initial.log退出0、2项通过。原生回调真实收到-2；本批保持明确恢复，不自动resume。
- 扩展debug回归：android-final.log退出0、7项通过（focus3/local3/lifecycle1）。旧callback用例是明确故障注入，不冒充真实迟到OS事件。共享Quality通过：19冻结哈希、锁、格式、analyze无问题、38测试。
- 最终v2.2：迟到回包红例退出1→绿例退出0；Android原生7项、release探针5检查、Windows原生3项、20冻结哈希/格式/analyze/39共享测试与双端普通release构建通过；Android普通包已重新安装。具体退出码和产物见report.md。
- Ruling：Git无HEAD且用户禁止提交/破坏性Git操作，直接保留工作区并用before副本、哈希和补丁审阅，不创建依赖提交历史的worktree或skill提交脚本。验证账本存在普通文档，不依赖私有技能脚本；不声称已有提交。
- Ruling：计划中的JVM单测无必要新增；实际设备已恢复，直接用真实Android原生集成红绿测试验证同一修复，不引入额外JUnit依赖。真实焦点与合成迟到回调的证据等级分开。

最终验证、审阅和产物以同目录report.md为准；未执行项不自动完成。
