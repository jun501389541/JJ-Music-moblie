# 独立只读复核

2026-11-01，执行计划技能要求一次新上下文审阅。reviewer /root/process_recovery_review只读三项代码及必要合同/原生语义、final proof，无修改或测试执行。

P2-1：仅比较disk JSON和首fixture不能证明实际runtime完整队列恢复。已修：由runtime所有持久字段重建RecoverySnapshot并逐字段比较disk，记录runtimeSnapshot，最终两端实跑通过，reviewer复核关闭。

P2-2（既有可靠性弱项）：Windows文件出现不代表完整JSON。已修：deadline内对解析失败和空值重试，不立即误杀健康进程；清理saved/loaded先置null。最终复核关闭。未单独注入半写竞态，不能把一次正常运行当该调度必现证明。

原生progress质疑经定点核对后撤销：NativeLocalBackend的position直接来自native sample、coordinator不外推时钟；consumer移除在await原生release完成后。另补Stop新空samples/Android服务释放，增强可观察性。

最终复核结论：两项P2已关闭；final proof双端各不同PID/epoch、相同保存修订/session、默认暂停零资源、旧claim拒绝、原生推进、再次暂停继续去重、停止空原生采样。Android精简只去重复lifecycle，保留samples。未发现限定验收残留假通过问题；仅自有fixture两进程恢复，非完整A07/G-L/生产存储。
