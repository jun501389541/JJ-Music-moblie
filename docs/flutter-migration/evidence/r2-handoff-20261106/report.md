# 合作式单轨协调器接管实施记录

2026-11-06；AUTH-R2-IMPLEMENT-20261106，用户确认[设计](design.md)。Codex串行A02/A07/ConfigIntegrator；现有codex/seek-boundaries，基线ee0e3471955750315fe945f2b4f057a79b21f5de。前批native/probe及全部未提交工作保留，不提交推送发布，不修改旧JJ-Music、依赖或全局配置。

最终接续完成：用户解锁后Android真机1项通过，双端合作式同isolate单轨接管的限定目标完成。Android普通APK已核哈希恢复安装并COLD启动成功；A07/G-L仍review。下文“待解锁/未安装”等内容保留为接续前历史，以末尾最终接续记录为准。

## 实际实现

PlaybackCoordinator增加明确结果的handoffSingleTrack，固定_EventRoute持有唯一事件订阅；同步交出唯一已确认活动轨，构造不同对象的新权威。保留backend/session/资源request与PreparedTrack/canSeek/sequence/confirmation、队列及业务状态；新owner/epoch，UI重新订阅。旧对象退休且清空资源所有权，旧claim/dispose/revoke不能释放新轨。

全部backend Future调用前计数，prepare、直接release及_dispatch在业务回调收尾后whenComplete减计数；拒绝在途、等待容量、双轨/撤销/未确认/释放中等情况。当前scope只适用同isolate合作式退休，不验证旧协调器异常死亡或跨engine。低层入口只供runtime包装和协调器测试，应用经LocalRuntime同步发布引用；保存/销毁/镜像中及closed拒绝，保持writer/backend/系统命令唯一。

05新增窄合同，A02新[冻结v2.4](../A02/20261106-handoff-freeze.md)及24文件清单；原v2.3的21文件历史清单不改，协议/快照格式仍1。检查脚本消费新清单，不降低门。新增共同测试和双端集成入口均在新冻结覆盖。

## 命令与证据

cwd clients/flutter，PowerShell，使用现有Flutter3.47.9/Dart3.13.7；完整输出本目录对应日志。普通产物在graphflow-out/r2-handoff-20261106/ordinary备份，初始摘要ordinary-before.json。

| 命令/层级 | 实际结果 | 日志 |
| --- | --- | --- |
| flutter test --no-pub test/playback/coordinator_handoff_test.dart --reporter expanded（实现前） | exit1，缺少handoffSingleTrack入口，预期红例 | red-core-escalated.log |
| 同文件实现后 | 首次6过1失败：暂停状态playing早退不增cursor，是测试期望错误；改为区分暂停状态并新增progress cursor断言 | green-core.log |
| 修正测试后同命令 | exit0，7项通过 | green-core-final.log |
| flutter analyze --no-pub（runtime实施前） | exit1，4处缺runtime入口，预期静态红例 | red-runtime.log |
| flutter test --no-pub --reporter expanded | exit0，65项通过（原58+新7） | shared-initial.log |
| flutter analyze --no-pub | 首次2个大括号lint已修复，失败保留 | analyze-initial.log |
| 根目录tool/check.ps1 -Mode Quality -EvidenceDirectory本批quality-initial | exit0，锁/24文件+05哈希/56文件格式0变化/analyze/65共同测试通过 | quality-initial-run.log及quality-initial/ |
| flutter test integration_test/coordinator_handoff_test.dart -d windows --reporter expanded | exit0，真实1项通过 | windows-initial.log |

沙箱内Flutter入口未输出、直接工具快照报VM参数错误，均在测试前，不能称产品失败；中止未执行命令后，通过工具自动审批在沙箱外运行测试。red-direct.log等保留，不放宽证书/不安装工具。后续本批命令也需要相同现有SDK/子进程访问条件。

Windows PID9948，oldEpoch1793963138985270→1793963138985271，backendEpoch1，单轨native-1，保存2345、接管2794ms，确认local-9948-1793963138985:1，最终samples空。验证同backend引用、新协调器对象、旧claim拒绝及旧dispose/revoke无副作用，接管后继续推进；系统GSMTC pause/play通过。既有Windows osCommand不支持stop，本批显式runtime stop，不声称系统stop已验。Windows poll没有host字段，日志host=null，不将null当物理实例证据。

Android开工35a63609在线、型号2211133C，实际Dozing；已请求用户唤醒解锁，尚未执行该端集成测试。不绕过锁屏，不用Windows/共同结果替代Android通过。

## 限制与待收尾

合作式新对象与存活backend的限定路径，不是异常死亡/跨engine无损R2、生产存储或无缝人耳听感。真实测试端点采样结合共同测试和源码证明无prepare/play转移，不代表连续硬件音频观测；未新增原生方法计数器。G-L仍review。独立代码审阅、Android测试和普通产物收尾以本目录后续记录为准，未执行不填通过。

## 最终共同检查、审阅与普通程序

独立[实现审阅](implementation-review.md)无Critical/Important。执行者核对后补route onError及新owner持活轨dispose/反序清理3测试，review-tests.log退出0，共10项。仅共同测试变化，产品字节未改，Windows实测不重复。更新本批新v2.4测试摘要前清单保留freeze-pre-review.json；原v2.3历史文件未修改。最终quality-final-run.log及quality-final/退出0，68共同测试、56文件格式0变化/analyze无问题、新24文件+05/锁全部通过。

普通main的WindowsRelease及AndroidRelease分别成功，见windows-release-run.log、android-release-run.log及ordinary-build/。本批共享生产源码变化，普通包重新编译为新版本，而非把新实现搭配旧普通二进制；原普通备份仍保留。Windows新普通入口隐藏启动2秒PID23372存活后由工具关闭（windows-ordinary-start.log），没有额外普通播放或人耳验收。Android本批未安装、未启动、未执行新测试；构建不代表手机通过。新普通APK另存graphflow-out/r2-handoff-20261106/ordinary-current/app-release.apk，普通整目录及APK精确摘要ordinary-current.json；旧摘要ordinary-before.json。

Android接续必须先由用户解锁，核实际foreground，再按handoff新测试命令执行并独立留证，结束核哈希恢复本批新普通APK及冷启动。不能绕锁屏或把本报告标成双端接管已通过。destroy/mirror busy和整体关闭交错未完整确定性覆盖，保留review；本批不补无关长期生命周期实验。

## Android最终接续（用户解锁后）

开工只读确认35a63609/2211133C、Awake，MainActivity前台且mDreamingLockscreen=false；24冻结源码及已备份普通APK摘要核对一致（android-preflight.log）。没有改测试或产品代码，不重复无变化的Windows/共同套件；继续消费quality-final的68项及既有独立审阅结果，不称本次重新运行它们。

cwd clients/flutter执行`./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/coordinator_handoff_test.dart','-d','35a63609','--reporter','expanded')`，android-final.log退出0，真实1项通过。Android PID372，coordinatorEpoch1793965093366385→1793965093366386，backendEpoch1、handle native-1、host-372-614036921；旧保存2345ms，接管2709ms，确认local-372-1793965093366:1沿用；接管后实际继续推进，系统pause/play/stop路由到新权威，旧claim拒绝、旧dispose/revoke不影响新资源，最后samples空。

测试进程完全退出后，停止测试包；核SHA256 6e71a188b6518c0af4489aa3ddef20acf2323983f0b53ff4c019ece433191f2f的本批普通main APK，adb install -r成功（android-ordinary-install.log），am start -W -S Status ok/LaunchState COLD，PID980、Awake（android-ordinary-start/pid/screen.log）。未重建普通Release，也没有额外普通播放/听感验收，Windows普通文件不改不重启。

双端限定接管目标现已完成；此结论不能外推异常死亡/跨engine无损R2、destroy/mirror完整交错或整体close/save生命周期竞争、长后台/OS回收/真实写中断/外设听感。G-L维持review。下一批可定点补runtime busy确定性覆盖，先核真实测试入口，不自动P2/正式UI或静默扩展架构。全部已有未提交工作保留，无提交推送发布。
