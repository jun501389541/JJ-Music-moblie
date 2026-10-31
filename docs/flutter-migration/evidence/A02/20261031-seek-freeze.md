# p1-a02-v2.3 定位能力冻结

对应20261031-seek-freeze.json，继承并保留v2.2，21文件精确字节摘要及05权威摘要。新PreparedTrack.canSeek为必填bool?，true支持/false不支持/null未知；绑定单条资源，当前诊断原生适配在ready时读取真实能力，缺字段不默认支持。共享seek只在true时短提交；其他情况在全部副作用前拒绝，分别seek-unsupported/seek-capability-unknown。applied不表示原生定位已完成。

原生端仍二次检查能力。准备时能力的后续动态变化、恢复目标在不支持定位时的产品退路不在本批保证；能力不进持久快照。协议/快照格式仍1。共同fake/技术诊断显式支持，Android和Windows消费者及检查脚本串行更新。新增三态单测；实际验证看evidence/seek-capability-20261031/report.md，不把冻结本身当运行通过。
