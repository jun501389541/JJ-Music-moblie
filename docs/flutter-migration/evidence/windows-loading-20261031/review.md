# 唯一独立只读审阅与实际修复

2026-10-31，按executing-plans/requesting-code-review技能发起windows_loading_review一次只读审阅，范围新流适配/原生接入/专属测试。无HEAD，基线是before/local_playback.cpp和当前文件。审阅者未跑构建/设备、未改文件或派生agent。

## P2发现及修复

静态发现：Track::Close先置closed=true；撤回调、player/source/stream任一Close抛异常会跳过后续步骤。第一次release返回Error但留track，下一次看到closed直接返回，可能仅凭readers=0就误发Success。旧player关闭已有同型隐患，本批新增source/stream使证据范围扩大。审阅时未实测，不称已复现。

主执行者先加明确的一次source关闭异常注入（非真实SDK偶发故障）和sourceClosed/streamClosed观测。在旧关闭行为下运行close-error-red.log退出1：第二release回复成功，但sourceClosed实际false，准确复现发现。

修复：closeRequested与实际closed分离，逐阶段attempt保证后续清理仍执行，成功阶段分别记录，显式重试只做尚未成功的阶段；异常仍向调用者返回。只有player/source/stream实际完成且未完成read归零才成功；FinishClose另核source/stream完成标记。析构清理noexcept并捕获错误，不从析构传播。native正在关闭的track不再访问其PlaybackSession。没有在原生新增自动重试/队列规则，只实现显式重复release的阶段幂等。

最终绿色结果与回归见report.md。不再次派发同一差异审阅，使用同红例转绿及受影响测试作为修复证据。

## 审阅正常路径与限制

未发现其他正常路径阻断问题：强引用保持coroutine、首suspend前读计数、gate/游标锁序、clone游标独立、cancel不可逆、读数归零后释放自有字节、registry防正常teardown的queued timer指针；边界2MiB/输入、8注册/观测项、16未完成read。

Declined to judge：SDK实际Close失败频率；timer系统ID复用压力与进程关闭回执；平台解码器峰值内存/内部资源；完整G-L及未由审阅者运行的Android/SMTC/本地路径。处置：异常注入只证明本控制路径，不冒充实际SDK故障频率；其余保持未测，回归结果由执行者日志另证。没有以本次审阅当全仓安全审计。
