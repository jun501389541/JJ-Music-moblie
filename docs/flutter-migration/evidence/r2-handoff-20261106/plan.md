# 单轨协调器接管 Implementation Plan

> 执行方法：executing-plans，当前checkout串行；用户已确认设计与实施，仓库要求保留未提交工作、不自动commit/push，覆盖技能默认提交/工作树建议。

**Goal:** 同isolate合作式新协调器接管唯一已确认单轨，不重播或重复确认。
**Architecture:** 稳定事件路由槽，全部backend Future在途围栏，runtime同步包装发布。拒绝不稳定态，不扩大到跨engine。
**Tech Stack:** 现有Flutter/Dart、Media3/WinRT，无新依赖。
**Spec:** [design.md](design.md)，用户2026-11-06确认。

## Global Constraints

旧v2.3/21冻结保留；新v2.4单独产生。协议/快照格式仍1。普通包备份恢复；手机仅35a63609且须实际解锁。无旧库/私人音源/全局配置/P2/提交发布。

## Review Focus

- released早于release Future：仍busy，回调收尾才允许接管。
- 旧dispose/revoke/transition/claim：不得影响新权威。
- 同步异常和异步失败：计数无泄漏，明确错误。
- runtime保存/镜像/销毁/关闭交错：拒绝不稳定态，不发布旧引用。
- 重复事件/竞争接管：只有一个owner，确认去重。

## Task 1: shared coordinator

- [ ] 新建test/playback/coordinator_handoff_test.dart，测试新对象/epoch、资源与确认保留、旧owner/释放拒绝、pending/双轨/控制在途/早到released拒绝、重复序列/重复handoff。运行flutter test该文件观察缺入口失败。
- [ ] 在coordinator增加CoordinatorHandoffResult、固定route和handoffSingleTrack(expectedClaim,newOwner)，以当前claim+route唯一权威校验；稳定条件拒绝busy/unsupported。全部Future调用前计数，回调结束finally减少。退休旧对象及所有无claim入口。再次运行新文件及全共同测试。

## Task 2: runtime wrapper

- [ ] 先在新增integration_test/coordinator_handoff_test.dart调用runtime.handoffSingleTrack，观察入口缺失。
- [ ] LocalRuntime的coordinator改只读getter/可替换私有引用；包装拒绝关闭、镜像、保存、销毁中。同步发布后通知，保持backend/store/writer唯一。save/destroy忙状态finally清理。
- [ ] 集成测试保存旧2345快照、播放推进、handoff、新对象同资源继续；旧控制无效、系统pause/stop及最终close资源空；不把两端采样当连续听感。

## Task 3: contract and platform validation

- [ ] 更新05窄合同，A02维护者登记v2.4冻结（继承旧文件列表并追加本批测试/runtime），check.ps1消费新清单。先格式/分析/共同测试，再保存新冻结。
- [ ] Quality通过；备份普通产物，分别跑Windows及已解锁Android新集成测试，保存独立日志。恢复普通包并验证可启动；设备不可用明确partial，不伪造通过。

## Task 4: review and handoff

- [ ] fresh reviewer只读审阅本批差异与设计；必要修复先红后绿，保存结果。
- [ ] 串行更新证据/状态/交接、准确摘要及定向index；不宣称完整R2或G-L通过。

## Ledger

- Ruling: 在当前dirty checkout执行，保留native/probe等前批工作，不迁移到缺少这些工作的干净worktree；不自动commit。
- GraphFlow plan intent/decomposition已submit/merge，顺序core→runtime→native→review。

- Task1: red-core-escalated缺handoff入口退出1；green-core-final7项通过。首次暂停playing的cursor断言错误，按原_onEvent暂停早退语义修正并增加progress验证，非产品缺陷。
- Task2: red-runtime静态缺入口4项；实现后Quality pub锁/新24文件哈希/格式/分析/共同65通过。
- Ruling: Windows既有GSMTC probe不支持stop，本批测试系统pause/play后用共享runtime stop；Android系统stop另验，不扩native协议。
- Ruling: 沙箱Flutter批入口无输出、直接工具快照失败；中止两条未执行的命令，后续已授权测试通过自动审批在沙箱外执行，失败日志保留。

- Final review: no Critical/Important; route onError、新owner持轨dispose及反序清理3项非阻断测试已补，10项通过。测试文件摘要更新至v2.4最终清单，先前清单保留freeze-pre-review.json；产品/接口字节未因审阅变化，Windows真实测试无需重复。destroy/mirror busy确定性矩阵未全验，明确保留。
- 普通main双端Release均构建成功。

- Task1 complete: 10项handoff共同验证、全共同68；生产源码按设计完成，旧v2.3不改。
- Task2 complete for implemented wrapper; runtime真实Windows路径通过。destroy/mirror完整矩阵未覆盖，见review/report限制。
- Task3 partial: 新v2.4/24冻结与双端main Release通过；Windows1项真实通过，Android待解锁未运行，无手机安装。
- Task4 complete for available scope: 独立审阅、最终Quality68、源码/产物/链接检查和定向index已保存；G-L保持review。
- GraphFlow: check.ps1为非includeExtensions，脚本内容已直接读取/执行验证，不称已解析入图。

- Task3 Android接续完成：用户解锁后android-final exit0/1项；普通APK核哈希恢复安装Success，COLD启动ok/PID980/Awake。源码未变，不重复Windows/共同套件。双端限定目标完成，整体A07/G-L仍review。
