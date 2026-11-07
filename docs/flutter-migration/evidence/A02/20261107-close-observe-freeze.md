# p1-a02-v2.9 关闭接管即时错误观察

继承v2.8的31文件，新增runtime_close_observe_test.dart，共32文件+05。旧v2.8保留，协议/快照仍1。Codex串行A07/A02/ConfigIntegrator维护。只提前建立已接管save/destroy的错误观察；不提前关闭、不吞原异常，不添加超时或原生策略。

受控红绿及边界见../close-observe-20261107/report.md，不以宿主验证证明真实系统故障。
