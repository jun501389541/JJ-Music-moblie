# 销毁失败安全退路修复计划

已批准接管设计要求无可信资源状态不得无损接管；本批为该既有要求的缺陷复现及局部修复，不新增架构。当前checkout串行，无commit/push。

1. 新runtime_destroy_failure_test.dart，复现失败后接管仍可成功、失败release Future被永久缓存；保留红例。
2. runtime销毁失败后保持不可信锁存和暂停意图，阻断handoff及重新播放/切换/seek；仅完整销毁回执成功清锁存。后端失败release允许明确下一次调用重新尝试，不自动循环，不在错误时删除handle或生成receipt。
3. 更新05及A02新v2.5，保留v2.4历史；新测试独立纳入新清单，Quality及双端真实既有handoff回归，不把mock释放故障称原生故障实测。
4. 独立审阅、普通main构建恢复与摘要、状态交接和定向index。partial多资源失败、持续失败和整体close竞争如未证保留，不扩大保证。

- 完成：红例→最小修复green2→重复失败测试→Quality75；独立review无阻断后补2时序测试及gate失败清理，最终Quality77/格式58/analyze/26冻结+05/锁通过。
- 普通双端Release完成，Android安装COLD ok/PID7900/Awake；Windows启动PID4684后关闭。双端正常接管各1回归通过，mock故障不当真实原生故障。产品未因审阅改变，不重复平台路径。
- 本批freeze-initial/freeze-pre-review保留新版本演进；旧v2.4不改。未提交推送发布。持续close失败等边界写入report/handoff，整体G-L仍review。
