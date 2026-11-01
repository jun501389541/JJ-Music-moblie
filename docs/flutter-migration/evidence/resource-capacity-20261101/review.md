# 限定只读审阅

按executing-plans/requesting-code-review一次capacity_review，仅核新resource_capacity_test.dart及相关poll/gate规则，未写文件、执行测试或派生实现代理。未发现Critical/Important。

关键排假：两个已blocked资源占满后第三输入拒绝，释放后同一第三输入成功；A关闭后B仍blocked且未cancel；同一backend用唯一id跨12轮，closed/readers0不能直接由旧gate快照替代；确认跨轮累计，最终普通播放只有一次确认。

Minor处理：原late allow后即时读取可能仍为旧lastHost；执行者增加两次后续快照更换等待（最多一个poll在放行前已在途），再断言cancelled/closed/readers0/bytesRead0并记录新快照，两端重新验证。此修订没有再次派审阅，最终结果看最终日志。

保留边界：history<=8/消费者/读取计数不能证明堆、OS句柄或平台内部缓冲无泄漏；setup失败前的清理覆盖较弱，不推广为所有失败路径清理已验。仅本次成功路径的容量和清理结论；非长期压力/资源耗尽验收。
