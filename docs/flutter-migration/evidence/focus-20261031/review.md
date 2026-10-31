# 独立只读审阅及修复

2026-10-31。依据已安装requesting-code-review技能发起一次focus_review独立只读审阅；不修改工作区、不跑设备、不派生agent。Git无HEAD，审阅基线为before/副本与当前真实文件，不伪造commit范围。

审阅发现1项P2竞态：旧focus pause已离开native队列，但Dart尚未消费时，新播放意图可能先提交；仅native focusEpoch过滤不能保护已返回的旧回包。审阅时为静态可达判断，未设备复现。主执行者随后建立test/platform/native_focus_command_test.dart，以延迟MethodChannel poll回包复现：旧focus、新focus和普通媒体pause原先全部发布（3条，预期2条），late-poll-red.log退出1。

修复采用原生请求捕获的Dart transportRevision，在接收处再次核验；不使用poll起点修订，因为新请求的真实loss也可能在一个较早开始的poll中返回。prepare/play/pause/stop均同步更新修订；公共协议/快照不变，冻结改v2.2。late-poll-green.log退出0，新焦点及普通媒体控制保留，只有旧焦点丢弃。最终共享及双端回归结果见report.md。不重复派发审阅，以新增红绿测试及受影响回归作为修复验证。

审阅其余意见：限定范围未见其他重要问题；回调main looper、统一abandon、先失效再OS归还、失败清理、gain不自动play均有代码依据。Windows日志路径修正符合避免覆盖历史证据的目的。

## 未判断事项的处置

- 其他应用/电话/导航/蓝牙/厂商矩阵：保持未验；本批只有同一应用内不同request产生的真实OS焦点竞争，不能代替跨应用/外设。
- OS实际拒绝焦点：失败清理有实现，未在真机诱发，保持未验；既有failNextPlay发生在requestFocus前，不充当拒绝焦点证明。
- 跨轨真实loss及已出队消息：已出队竞态通过受控回包红绿验证，属于平台边界模拟；旧listener为明确故障注入。跨轨OS竞态仍未在真机诱发，不扩大声称。
- 全仓安全/队列策略/正式UI：本批不改这些能力，不以限定审阅为全仓审计。

以上限制若被当成已验，会错误扩大机型/系统/恢复能力声明，因此均继续留在A04/G-L缺口。没有另行新增验收门或降原门槛。
