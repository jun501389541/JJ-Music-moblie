# p1-a02-v2.4 合作式单轨替换冻结

继承v2.3，原20261031-seek-freeze.json/md及其21个历史摘要保持，不将其改写为当前代码。新清单20261106-handoff-freeze.json记录实际共享源码、05及新共同测试/runtime；协议/快照格式仍1。新增窄API结果在coordinator模块，不改变既有wire字段或PlaybackBackend接口。

同isolate、存活backend、旧协调器合作式转移；全部backend Future及回调收尾完成才可转移。拒绝不稳定态，成功增加协调器epoch而保留单轨资源/确认/序列。固定事件路由唯一权威，runtime同步包装发布。不是跨engine或异常死亡R2；完整G-L仍review。

维护者Codex串行A02/A07/ConfigIntegrator。LocalRuntime、Android/Windows诊断消费者共用此API；check.ps1改消费本新清单，不放宽哈希/锁/格式/分析/测试。具体命令、实测、失败和限制见../r2-handoff-20261106/report.md；冻结本身不表示运行通过。
