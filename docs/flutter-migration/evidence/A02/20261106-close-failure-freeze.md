# p1-a02-v2.6 独立关闭收尾冻结

继承v2.5的26文件并新增close_actions.dart及runtime_close_failure_test.dart，共28文件+05摘要。旧v2.5清单保留；协议/快照格式仍1。

Codex串行A02/A07/ConfigIntegrator维护。runtime/backend各复用一次close Future，失败不阻断后续独立清理，保留首错stack及其余错误；残留handle仍保有消费者，不伪称物理释放。runtime镜像Future不被skip tick覆盖，关闭后命令/重连无副作用。helper只收集拒绝，不为永不完成的Future制造timeout。检查脚本消费新清单，验证规则不变。

实际红绿/宿主故障及双端正常回归分别见../close-failure-20261106/report.md，不把冻结或mock当平台物理资源证据。
