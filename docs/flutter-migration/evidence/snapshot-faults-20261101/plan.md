# A07新进程快照故障限定批次

2026-11-01（Asia/Shanghai），AUTH-P1-SNAPSHOTFAULT-20261101。owner Codex串行A07/ConfigIntegrator/文档。基线ee0e3471955750315fe945f2b4f057a79b21f5de，codex/seek-boundaries与origin一致且开工干净；本批不自动提交推送。AGENTS、README/status/handoff、A07任务/归属及05 C-03、E2/E4沿用当前版本；消费v2.3/21冻结，存储/wire版本1，不改共享存储/合同/native/UI/依赖/P2/旧库。

1. 先核当前真实FileSnapshotStore实现和单测：两个正式slot按修订择最新有效，忽略.tmp。已有单测不是新平台进程证据。实际前批A07双端正常强杀恢复和A04/A06主路径已具备，不把review当整阶段done。
2. 新lib/p1_snapshot_fault_probe.dart + tool/run_snapshot_fault_probe.ps1（路径相对clients/flutter）。每端同一显式编译P1_RUN_ID二进制，按6case各自runId目录运行seed→强杀→check两个不同PID。seed真实save rev1/2后才改其自有文件；missing无保存，允许为空。check新LocalRuntime加载，坏输入安全空态stopped，partial-temp选2/2345ms/index0，corrupt-newest选1/1234ms/index1且paused；逐字段比对实际runtime和disk/已知夹具，700ms原生0资源、文件内容逐字不变。
3. 三种故障（双槽损坏/未知版本/不允许fixture）必须有读诊断issues；missing/partial-temp无需伪报错误。拒绝不自动play，资源0/Android无service/focus，不用模拟证明真机。
4. 每端分开Release构建及6组实际进程测试；格式/analyze/共同58/21冻结与05/锁。一次只读独立review，常规故障修复后重验。
5. 普通APK和Windows整目录先备份到graphflow-out/snapshot-faults-20261101，结束逐文件核摘要还原/普通启动检查；更新报告/status/handoff/index。

Ruling：本批不改FileSnapshotStore以加fault hook。遗留tmp是在seed中显式写入并flush的受控故障夹具，随后真实强杀该进程；验证新进程选择策略，不宣称save Future在真实写入点被中断或断电原子性已证明。确认凭据是synthetic fixture，不宣称实际播放/听感/真实历史。范围止于当前A07子项，G-L仍未过。

设备35a63609=2211133C/fuxi在线，最初Dozing；用户明确回复已解锁。只使用已选手机，不绕锁屏/改系统设置。Windows无既有普通进程；备份见normal-backup.json。GraphFlow context与plan required submit/merge已完成；技能graphflow/executing-plans，验证前按verification-before-completion核输出，不安装技能或工具。
