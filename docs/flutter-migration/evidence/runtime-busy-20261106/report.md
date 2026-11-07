# A07 runtime busy 确定性验证（2026-11-06）

AUTH-RUNTIME-BUSY-20261106；用户继续开发，接续已批准的单轨接管设计和最新handoff。owner Codex串行A02公共测试维护/文档协调。当前codex/seek-boundaries，基线ee0e3471955750315fe945f2b4f057a79b21f5de；原有全部产品/native/probe及文档未提交工作保留，不提交推送发布。

本批只新增clients/flutter/test/runtime/runtime_handoff_busy_test.dart及本证据，串行更新status/handoff；产品实现、原生、依赖、05和v2.4/24文件冻结不改。当前协议/快照仍1。GraphFlow context/plan及intent/decomposition submit/merge已完成。新验证文件摘要独立保存，不重写已冻结测试和历史证据。

## 实际覆盖

测试运行真实Dart LocalRuntime、PlaybackCoordinator和NativeLocalBackend及隔离FileSnapshotStore，但MethodChannel由宿主NativeHost模拟；没有解码/物理音频/原生线程或设备。自有tone-long fixture用于已有runtime创建路径，随机runId隔离写锁/快照；只清理该测试run目录，不删除共享临时根或其他资料。

mock poll提供递增位置与完整准备/playing信号，使共享协调器获得单轨确认；mirror和release在Completer进入回执后保持未完成，不依赖sleep或概率等待。超时仅防卡死，不作为成功标准。

| 场景 | 关键验收 |
| --- | --- |
| mirror未完成→成功 | gate进入后handoff返回runtime-busy，协调器identity/epoch、consumer和prepare/play/release操作列表不变；镜像finally通知时同一调用栈中handoff成功，新对象/epoch、同轨与确认、无重播/释放 |
| mirror未完成→PlatformException | 同上；错误被runtime记录，finally通知后仍能成功接管，不残留busy；不是实际系统镜像故障 |
| destroy等待release | handoff、重叠save/重复destroy拒绝；旧对象/coord epoch/backendEpoch/handle、consumer及操作列表不变；放行后backendEpoch增加、paused、轨道空、consumer0且release一次；handoff返回unsupported，证明destroy忙状态已清理但不伪造存活资源 |
| save无确认条目校验失败 | save抛错，savedRevision仍0/磁盘无快照/无backend操作；handoff为unsupported而非runtime-busy，保存校验失败没有忙标记泄漏 |

mirror的完成观察者先removeListener再在finally通知中调用handoff，避免notifyListeners递归以及下一次周期镜像抢入导致假阴性。测试失败清理先放行自有gate，再关闭runtime定时器/订阅/锁，校验并删除本run目录，最后撤销mock。

## 命令与结果

cwd clients/flutter（Quality命令从仓库根调用）：

| 命令 | 结果 | 证据 |
| --- | --- | --- |
| flutter test --no-pub test/runtime/runtime_handoff_busy_test.dart --reporter expanded | 初次exit1：测试误给非const的PlatformException加const，编译前失败，不是产品行为红例；修正后完整重跑 | targeted-initial.log |
| dart format test/runtime/runtime_handoff_busy_test.dart；同定点测试 | exit0，4项通过 | format.log、targeted-final.log |
| ./clients/flutter/tool/check.ps1 -Mode Quality -EvidenceDirectory本批quality | exit0，v2.4原24文件+05哈希、锁、57文件格式0变化、analyze和72共同测试（原68+本批4）通过 | quality-run.log、quality/ |

本批是对已实现行为补验证，没有修改产品，因此不制造虚假的产品失败/修复叙述。执行使用此前已验证的沙箱外Flutter工具权限，只访问现有SDK/项目缓存及自有临时夹具，不安装工具/改全局设置。

## 证据边界与下一步

新增的是宿主可控异常/在途验证；此前双端真实合作式接管结果保留，但本批没有重跑设备、构建、安装或启动程序。普通产物按前批ordinary-current.json核摘要，不把mock当双端原生fault通过。

本批没有验证真实销毁失败后资源一致性/重试、实际磁盘写入失败、close与save/destroy整体竞争、长后台/OS回收、跨engine异常死亡接管、外设/人耳听感。这些仍为明确未验，不能因busy矩阵补齐放行完整G-L。下一项可先审查销毁失败后的资源安全退路与可重现入口；发现生产缺陷时按A02合同及受影响平台流程处理，不静默改历史冻结。

独立审阅及最终范围/摘要检查完成后记录于同目录review.md、final-check.log、index.log；A07/G-L保持review。

## 最终整合结果

独立[测试审阅](review.md)未发现阻断问题。Minor的初始化失败mock遗留问题已由执行者修补：mock登记后立即注册撤销，再await create；create成功后注册runtime/目录清理，逆序执行。targeted-cleanup.log四项通过，最终quality-final-run.log及quality-final/退出0：72共同、57文件格式0变化、analyze、原24冻结+05/锁全部通过。最终测试文件摘要test-final-hash.json，初版摘要保留test-hash.json。

产品实现和双端普通产物摘要核对未变，本批不重跑已验平台路径。没有本次新增产品故障，不需要刷新冻结版本或重建普通包；A07/G-L整体仍review。全部旧修改保留，无commit/push/publish。
