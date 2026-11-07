# GR-01/GR-02 修复记录（2026-11-07）

用户“按review文档修改”，针对[全局审阅](../global-review-20261107/report.md)。Codex串行A02/播放维护/ConfigIntegrator；codex/seek-boundaries，基线ee0e347；所有旧未提交工作保留。本批不执行提交推送，历史条件授权需最终复核。

GR01：seek/移除未确认B后requested回A，只有playing意图且A有效时恢复A，paused不抢播。GR02：resume优先当前request/generation的prepared/incoming B，pending则等待；异步prepare失败清当前请求、requested回A，保留paused/playing意图，仅playing恢复A。

7项初始回归全部失败（red.log），修复后89共同通过。独立审阅发现pending B准备失败退路遗漏，新增两项红例均失败（red-prepare-failure.log）后修复，完整91共同通过（tests-final.log）。审阅局部复核确认Important已解决，没有新阻断；探针VM启动失败未运行到代码，不作独立执行证据。新增真实集成入口被审阅核对无明显假阳性。

新v2.7/30文件+05，协议/快照仍1；旧v2.6保留，初始本批29文件清单freeze-initial.json保留。最终Quality见quality-final-run.log和quality-final/：锁/30冻结+05/格式/analyze/91共同通过。新增集成测试仅补四处大括号，不改平台实跑控制流，未重复同一真机路径。

平台专项integration_test/transition_recovery_test.dart：Android经既有proxy脚本指定35a63609，Windows -d windows，各4/4通过（android.log/windows.log）。前三场景在B incoming且nativePlaying、A仍current的首个progress同步介入；未观察到介入则超时失败。seek/remove最终A恢复真实playing/位置推进/requested=A/确认1；incoming与prepared两种恢复最终B active/requested=B/确认2；consumer收敛1，stop后0及原生空。Android PID26611，A seek3306/remove615，B恢复590/559ms；Windows PID36640，A seek3279/remove584，B恢复684/674ms。

平台只证明此次原生状态/进度，不证明人工听感或所有旧回调时序。持续paused物理静止、resume后才ready及prepare失败只在共同测试覆盖，未宣称这些也已真机实测。G-L仍review。

普通产物备份graphflow-out/gr-fixes-20261107/ordinary-before；本批生产变更需新main Release，两端构建与恢复记录收尾补于下文。未改原生/依赖/全局或旧仓库，未提交推送发布。

## 最终普通产物
双端普通main Release构建成功（android/windows-release-run.log及builds/），Android恢复安装Success/COLD启动ok/PID27568。Windows普通入口启动2秒后关闭，PID见windows-ordinary-start.log。普通最终摘要ordinary-final.json，新APK在graphflow-out/gr-fixes-20261107/ordinary-final。无新增听感验证。未提交推送，完整G-L仍review。
