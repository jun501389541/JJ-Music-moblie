# p1-a02-v2.5 销毁失败安全退路

继承v2.4的24文件，追加销毁失败测试及其runtime busy测试helper（其中NativeHost被新测试导入）；新26文件精确摘要及05摘要见同名json。旧v2.4文件不重写，协议/快照仍1。修改runtime失败锁存/暂停/命令围栏及薄backend失败release显式重试；无原生/依赖变化。

Codex串行A02/A07/ConfigIntegrator维护，所有后续消费者切换新清单，check.ps1保持相同哈希/锁/格式/分析/测试规则。单轨故障证明、平台正常回归及剩余部分销毁边界见../destroy-failure-20261106/report.md，不把mock当真实原生故障注入。
