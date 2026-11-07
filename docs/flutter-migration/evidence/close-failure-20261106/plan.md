# 持续释放失败的独立关闭收尾

当前checkout串行，保留所有旧工作，不commit/push。修复既有失败关闭缺陷，不扩生命周期架构。

1. 5项宿主红例：持续release错误后notifier/流关闭、Windows writer锁释放、共享close Future、mirror Future不被skip tick覆盖、两个资源和log错误时仍收尾并保留首错。
2. memoize runtime/backend关闭Future；有序尝试所有独立步骤，保留首错stack并保存其余错误诊断，失败consumer仍保留；runtime保证lock/notifier收尾，backend保证后续handles/log/streams。修timer只记录真正开始的mirror Future。
3. 新v2.6冻结保留v2.5；Quality、独立审阅和双端正常handoff/close回归，普通产物备份重建恢复。
4. 记录mock与真实正常路径差别，不以宿主证明真实物理释放/无穷pending或整体save/destroy竞争；准确交接及index。

2026-11-07收尾：红5→green5，测试lint/公开debug API修正；review额度失败后重试无阻断，两个非阻断测试缺口已补。最终Quality82/格式60/analyze/28冻结+05/锁通过。双端真实正常close恢复各1通过，普通双端新构建、Android恢复COLD ok/PID23428，WindowsPID15784启动后关闭。失败资源未知/无穷pending/暂停订阅及整体save/destroy竞争限制保留，G-L仍review，无提交推送。
