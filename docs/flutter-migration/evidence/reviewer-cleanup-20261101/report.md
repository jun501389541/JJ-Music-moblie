# Reviewer修复：初始化失败的诊断资源清理

2026-11-01，AUTH-REVIEW-CLEANUP-20261101限定修复完成。用户要求先落实reviewer意见，本次没有继续A04新功能。分支codex/seek-boundaries，先前全部未提交工作保留；不提交/推送/发布，不改生产代码、原生实现、UI/依赖/全局/旧Electron或v2.3原21冻结。

## 意见逐项处理

| 意见 | 实际处理 |
| --- | --- |
| capacity_review：late allow后可能读旧快照 | 前批已等两轮新poll后重新断言，保留并在本批两端回归 |
| seek_boundaries_review：最终释放一次不证明没有提前释放 | 前批已补交接前0/后1断言，继续保留，完整共同测试覆盖 |
| capacity_review：setup在try外，失败时清理覆盖弱 | 本批修复：初始化整体进入清理作用域，每个资源在后续可失败操作前登记 |
| 计数不能证明堆/OS句柄无泄漏 | 证据边界保留，不通过改文案或增加计数假装已经证明 |

新增test-only support/diagnostic_cleanup.dart：逆序逐项await清理，某项抛错后仍尝试其余；body原始异常及trace保留，cleanup及同步错误记录回调不覆盖原错误；没有body错误时抛第一项cleanup错误，后续错误单列诊断，默认只输出类型不输出源路径或敏感正文。

resource_capacity_test将setup也放入作用域：Windows临时目录创建后、写文件前登记删除；Android诊断亮屏回退在enable前登记；backend/coordinator创建后立即登记；native release在prepare前登记。依赖逆序是coordinator→backend→临时输入→亮屏回退；容量多个release独立登记，单项异常不会跳过其他登记动作。不是保证原生拒绝关闭/永不结束Future也能被强制回收，不扩展生产NativeLocalBackend.close内部错误恢复策略。

## 测试及证据

- red.log：故障测试先于辅助实现，因缺入口加载失败；这是新测试API的红色基线，不是生产播放器缺陷复现。
- unit.log：首次5项故障测试通过；unit-final.log：补复核指出的两个轻微覆盖缺口后7/7通过。覆盖实际临时目录删除、部分初始化逆序、多项release抛错仍继续、原body错误优先、等待异步清理、observer同步抛错不掩盖primary、多cleanup首错优先。
- windows.log/android.log：清理重构后的原容量和12轮场景各2项通过。
- windows-final.log/android-final.log：加入真实native prepare+blocked后主动抛setup错误场景，各3/3通过、EXIT0。作用域完成后原生samples空、gate.closed/readers0；Windows还实查临时输入已删除。只注入测试setup故障，不冒充原生I/O故障。
- quality/首次完整56项通过；新增原生fault场景后quality-final/因清理断言if缺块的lint失败，原日志保留；补块后quality-complete/最终58/58，格式51文件0变化、analyze No issues、原21冻结/05/锁通过。两端3项在最后纯语句块修正前运行，未为相同控制流重复设备测试。
- 普通APK与已验v2.3哈希一致，重装Success、COLD启动ok/PID28127，见install.log/android-start.log；两端普通Release均未重新构建，Windows普通窗口不动，normal-artifacts.json记摘要。运行时不含本批test-only helper。

7个故障单测加入共同检查，总数从51到58。新增测试不是冻结公共断言/接口，未更新旧哈希，source-hashes.json单列本批文件。capacity-cleanup.patch基于本批before快照（git中该容量测试仍未跟踪），不覆盖先前修改。一次编辑脚本默认编码读取失败且未写入，后续明确UTF-8成功；不计作产品失败或通过证据。

## 复核与交接

一次只读cleanup_fix_review复核没有Critical/Important。其建议补observer自身抛错和多cleanup首错优先组合，执行者已补7项单测并完整通过，没有再派审阅。复核未执行测试，不代签真实端结果；旧review记录不重写，按当时结论保留。

复跑cwd clients/flutter：`flutter test test/diagnostic_cleanup_test.dart`；两端分别`flutter test integration_test/resource_capacity_test.dart -d windows`与既有proxy脚本指定35a63609；完整Quality路径quality-complete。手机身份仍2211133C/fuxi，不扫描个人曲库，仅自有媒体。

本次剩余最新可修复清理弱项已落实；原生close故障、堆/OS句柄、长期压力并未据此证明。整体G-L未过，后续恢复文档中的A04 Activity重建与媒体控制并发任务前先核设备/前置；不自动扩展到正式UI/P2/网络。GraphFlow定向结果见index.log。
