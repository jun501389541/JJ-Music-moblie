# Runtime busy 验证计划

依据已确认的../r2-handoff-20261106/design.md与最新handoff，不新增产品行为。Codex当前checkout串行执行，旧改动保留，不提交推送。

- [ ] 新建test/runtime/runtime_handoff_busy_test.dart：mock channel提供可推进采样，使真实Dart runtime/coordinator/backend达到可成功handoff单轨；completer而非sleep保持mirror/release未完成。
- [ ] mirror完成/失败前拒绝且同对象/epoch/资源/操作数量不变；finally通知时立刻handoff成功，避免下轮timer竞态。
- [ ] destroy release阻塞期间handoff/save/重复destroy拒绝；完成后backendEpoch增加、暂停、资源空且不再runtime-busy。
- [ ] 无确认轨save验证失败后无busy泄漏，handoff返回unsupported而非runtime-busy。
- [ ] 定点测试、Quality（v2.4原24冻结+05/锁/格式/分析/全共同）；记录源码与普通产物摘要未变，不重跑平台。
- [ ] 独立测试审阅，准确记录宿主mock范围、剩余销毁失败/整体关闭交错，更新status/handoff及定向index。

无产品变化，因此新增验证不要求伪造产品红例；已有行为若不符合批准设计，保留失败并定位，不降低断言。GraphFlow context/plan submit/merge已完成。新增测试摘要独立保存，不改历史冻结清单。

- 定点4项通过；首次const语法失败保留，非产品故障。Quality初轮72/格式57/analyze/v2.4冻结通过；普通双端产物摘要未变。
- 独立审阅的Minor初始化失败mock清理建议已落实：先登记mock撤销，再await create，再登记runtime关闭/目录清理，逆序执行；targeted-cleanup4项通过。最终Quality重跑中。

- 全步骤完成：测试4项、最终Quality72/格式57/analyze/原冻结+锁通过；独立review无阻断，清理Minor修补已回跑；产品/普通双端产物摘要不变，status/handoff已串行更新。整体G-L仍review，无设备/构建/安装/提交推送。
