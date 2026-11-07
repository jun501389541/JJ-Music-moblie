# 持续释放失败的关闭收尾修复

开工2026-11-06，2026-11-07接续。AUTH-CLOSE-FAILURE-20261106；Codex串行A07/A02/ConfigIntegrator，codex/seek-boundaries，基线ee0e347。全部既有未提交工作保留，不提交推送发布，不改旧库/依赖/全局。

## 红例与修复

red.log退出1，五项均失败：持续release报错中断runtime notifier/流/Windows writer锁关闭；重复close产生不同Future并重复操作关闭文件；mirror skip tick覆盖真实在途Future，close提前完成；backend首轨释放失败使后续轨道和流清理跳过。清理的次生错误同日志保留，不改成通过。

CloseActions逐项捕获独立有序清理错误，保存全部错误并按原stack重抛首错。runtime/backend各memoize一次close Future，重复调用返回同一完成结果，不隐式重试。runtime尝试镜像、订阅、协调器、backend、writer及notifier；backend尝试每个handle、残留资源暂停、log和两个流。失败消费者仍保留，不以Dart收尾证明物理释放。closeFailures保留诊断错误；需要实际资源重试时必须显式清理/R3。

timer仅在真正启动镜像时替换_mirrorFuture，跳过tick不覆盖在途镜像；关闭后runtime命令返回runtime-closed、重连无副作用。helper不为永不完成的操作制造timeout；整体save/destroy竞争未扩修。

新[p1-a02-v2.6](../A02/20261106-close-failure-freeze.md)冻结28文件+05，旧v2.5不改，协议/快照仍1。初版本批清单freeze-initial.json保留；初次Quality的两个大括号lint及测试误用protected hasListeners已修为公开ChangeNotifier.debugAssertNotDisposed，不放宽规则。green.log初版五项通过；quality-final最终82共同、60文件格式0变化、analyze、28冻结+05/锁通过（quality-final-run.log及quality-final/）。

## 分层验证

- 宿主故障：新runtime_close_failure_test.dart五项，MethodChannel模拟持续release错误和log写目录错误，真实Dart运行时及Windows自有临时文件。逐项断言后续资源尝试、流done、notifier disposed、Windows目录可删除、同一close Future及真实mirror Future等待。不是手机锁或跨进程锁证明，也不是实际原生释放故障/物理听感。
- Android正常关闭回归：11-06 android-regression.log退出0，1项；PID13091，旧epoch1793969719745729→1793969721289481；真实播放关闭后原生空，新对象读回修订1/位置2345默认暂停，旧claim拒绝、显式继续/最终原生空。源码随后未改，本次不重复该端测试。
- Windows正常关闭回归：11-07 windows-regression.log退出0，1项；PID16900，epoch1794013511234966→1794013512492142；同一文件快照修订1/2345默认暂停，旧claim拒绝、显式继续及最终原生空。

平台命令均在clients/flutter执行既有integration_test/coordinator_restart_test.dart，Android经tool/flutter_with_proxy.ps1指定35a63609，Windows -d windows。Quality从根运行tool/check.ps1。普通产物此前已备份于graphflow-out/close-failure-20261106/ordinary-before，摘要ordinary-before.json。

独立审阅首次因代理额度限制失败，未返回有效意见；2026-11-07已重试，结果以review.md为准，未得到意见不能称独立审阅通过。普通构建、设备恢复及最终范围校验在收尾记录补充。

## 未验边界

永不完成的镜像/原生Future、暂停流订阅导致close等待、整体close/save/destroy并发、跨engine/异常死亡无损接管、真实系统release错误/物理暂停/听感仍未保证。失败close保留物理资源未知状态，释放writer只证明存储句柄收尾，不授权重用未知原生handle。A07/G-L保持review，不自动P2/正式UI。

## 2026-11-07最终收尾

独立[审阅](review.md)重试成功，无Critical/Important。两个非阻断测试缺口已补并通过：失败close复用且不额外release，prepare早失败时独立backend timer也关闭。freeze-pre-review.json保留补测前新清单，原v2.5不改；只有测试变化，无需重复平台路径或构建。最终quality-reviewed-run.log及quality-reviewed/：82共同、60文件格式0变化/analyze、28冻结+05/锁通过。

Android与Windows普通main Release均构建成功（android/windows-release-run.log、builds/），锁文件未变。设备中途断开，用户本次重连后核同一35a63609/2211133C/Awake；本批新普通APK核哈希恢复安装Success，COLD启动Status ok/PID23428（android-ordinary-install/start/pid.log）。这只是普通启动，未多做播放/听感验收。Windows新普通入口启动2秒后工具关闭，准确PID见windows-ordinary-start.log。双端最终摘要ordinary-final.json，新APK另存graphflow-out/close-failure-20261106/ordinary-final/app-release.apk。

限定关闭收尾修复完成，全部既有未提交修改/历史失败保留，无提交推送发布。仍不保证暂停外部订阅或永不完成的Future下有界收尾；下一批应先定点核对close与在途save/destroy竞争的安全边界及受控入口，不静默扩成完整生命周期保证。A07/G-L继续review。
