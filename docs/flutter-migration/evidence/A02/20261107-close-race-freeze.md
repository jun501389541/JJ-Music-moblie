# p1-a02-v2.8 在途操作关闭汇合

继承v2.7并新增runtime_close_race_test.dart，31文件+05摘要。旧v2.7保留，协议/快照仍1。Codex串行A02/A07/ConfigIntegrator维护；只发布save/destroy在途Future、close汇合与closed通知围栏，不改原生/依赖。不保证永不完成Future或所有竞争。

红绿、受控故障与真实正常回归分层见../close-race-20261107/report.md；冻结本身不代表通过。
