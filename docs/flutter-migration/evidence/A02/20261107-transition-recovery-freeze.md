# p1-a02-v2.7 切歌撤销/暂停恢复修复

继承v2.6的28文件并追加transition_recovery_test.dart，共30文件+05（含双端集成回归）。旧v2.6不改，协议/快照仍1。A02维护者Codex串行整合GR01/02：seek/移除未确认B收敛requested=A且仅播放意图时恢复A；resume按当前请求优先B或等待pending，不抢播旧A。具体红绿与平台边界见../gr-fixes-20261107/report.md。
