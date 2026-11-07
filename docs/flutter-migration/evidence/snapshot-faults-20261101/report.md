# A07 新进程异常快照退路

日期2026-11-01（Asia/Shanghai）；AUTH-P1-SNAPSHOTFAULT-20261101限定目标完成。完整A07及G-L仍review，未进入P2。

新增clients/flutter/lib/p1_snapshot_fault_probe.dart和tool/run_snapshot_fault_probe.ps1；对应计划/归属/边界见[plan.md](plan.md)，复核见[review.md](review.md)。仅测试入口/控制脚本，普通运行时、原生、FileSnapshotStore、冻结合同和夹具无改动。基线ee0e347，codex/seek-boundaries；本次继续开发不继承先前提交推送，未提交/推送/合并/发布。旧JJ-Music只读，未扫描个人资料、源、账号或密钥，不改全局/工具/正式UI。

## 分端实际验证

| 场景 | 新进程预期与实际 | Android真机 | Windows |
| --- | --- | --- | --- |
| missing | 无快照，安全空态stopped/revision0/position0 | 通过 | 通过 |
| corrupt | 两slot均损坏，有诊断issues，安全空态 | 通过 | 通过 |
| unknown-version | 两slot版本99，拒绝格式并保留输入，安全空态 | 通过 | 通过 |
| unavailable-fixture | 两slot含不允许fixture，拒绝运行引用，安全空态 | 通过 | 通过 |
| partial-temp | rev1/2已保存，额外不完整rev3.tmp忽略；加载rev2/index0/2345ms且paused | 通过 | 通过 |
| corrupt-newest | rev2的slot-a损坏且遗留.tmp；加载最后有效rev1/index1/1234ms且paused | 通过 | 通过 |

每端6组seed→强杀→check；每组两个不同PID，每端12个实际进程。seed用真实FileSnapshotStore保存并取得rev1/2完成回执（missing无保存），再只修改本scenario自有目录，输出原始输入字节；控制器终止seed后显式新进程创建真实LocalRuntime。check将实际运行快照逐字段与已知自有夹具及真实disk load结果比较，验证队列/索引/模式/preview/逻辑session/修订/位置/确认；坏输入无条目/确认/当前位置/资源。加载前后文件逐字不变，外部控制器又与seed的files逐字核对；无自动修复/覆盖未知格式。

仅构造synthetic确认凭据fixture-confirmation:1，不曾播放，不把夹具确认当真实媒体历史。自有条目owned-a/owned-b和tone-long身份，不打开个人媒体。每场景独立runId，两个正式slot与最多一个.tmp，沿用原型256KiB/16条目/64确认预算，本批输入为少量JSON；writer.lock不作为音频资源。普通owned-p1目录与旧Electron资料均不受影响。

700ms窗内约100ms周期原生轮询、25ms共享状态检查，至少3次新poll；检查所有观察结果与backend.raw，均无native samples/consumer/track/bridgeError，Android另无服务/焦点。最终Android每组6次新poll，partial-temp7次；Windows每组6次。不是采样间隙的实时追踪，不外推长期后台或硬件听感。

## 证据与退出码

- Android：此前选择手机35a63609/2211133C/fuxi/API33，开工Dozing后用户回复已解锁，运行前核Awake/keyguard showing=false。android-final-build.log退出0（42.5MB Release探针，P1_RUN_ID=faults-20261101-a2）；android-verified-run.log退出0，最终完整proof在android-verified/snapshot-faults-proof.json，另逐阶段start/native/proof日志。各场景seed/check PID为17473/17593、17726/17840、17989/18106、18234/18348、18482/18600、18730/18841，顺序同上表。
- Windows：windows-final-build.log退出0（Release探针，P1_RUN_ID=faults-20261101-w2），windows-final-run.log退出0；最终完整proof在windows-final/snapshot-faults-proof.json。各组PID42592/30752、38000/43192、44504/39808、40152/32752、43208/43676、13876/37700。原exe/app.so实际启动，二进制摘要见proof。此验证在控制器末尾仅追加exit0前执行；后续未变Windows分支/检查，未重复该端进程测试。
- 共同：quality-run.log退出0，quality内锁定pub解析/21冻结文件+05权威摘要/锁、格式53文件0变更、analyze无问题、58/58共享测试通过；没有新增无意义镜像单测。Quality在仅PS成功exit0尾语句前执行，Dart不变；之后PS语法再次检查及Android完整重跑通过。
- 独立审阅：一次新上下文review并复核所提修复，见review.md；无生产缺陷被复现/修复。修改后GraphFlow定向index见index.log；PS扩展若按现有配置跳过，以精确文件/实际执行/解析证据补充，不改全局图配置。

中间记录保留：Windows初轮六组通过但仅末端采样，按review加强后新w2全部复验；Android初轮a1各项proof通过但整体退出1，android-final-run.log/原android-final目录保留，不能计整体通过。原因是成功清理后的预期pidof状态1污染结果；成功收尾exit0不吞throw，新a2全部复验退出0。最终每端只计6个不同场景，不把重复运行累计成更多验收。

## 普通程序还原及用户检查

普通APK与Windows整目录先备份graphflow-out/snapshot-faults-20261101，结束逐文件核SHA256还原，见normal-backup/normal-restored.json。普通APK摘要84732716da464fa10f3bee2fde475415ceef2e07da10b05d66617b60abcb946f；并非重新编译普通Release。手机install Success且普通MainActivity冷启动Status ok/COLD，见ordinary-install/ordinary-android-start.log。Windows普通完整目录已核对还原，本批未再启动普通UI；真实Windows启动是上述探针，不能混写。

用户无需手动制造快照损坏。手机当前普通诊断入口可检查播放A→定位3秒→暂停/继续→停止资源0。Windows普通程序位于E:/Workspace/project/JJ-Music-mobile/clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe，保留同目录DLL/data，双击运行。新增故障验证是隔离自动化入口，没有新增产品UI，不能把普通打开视为本批六场景验收。

如需开发者复现，cwd clients/flutter，先备份普通产物，每轮新runId（本批a1/a2/w1/w2不可复用）：

```powershell
$run = 'fault-' + [Guid]::NewGuid().ToString('N')
$out = 'E:/Workspace/project/JJ-Music-mobile/graphflow-out/' + $run
./tool/flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_snapshot_fault_probe.dart',"--dart-define=P1_RUN_ID=$run")
./tool/run_snapshot_fault_probe.ps1 -Platform Android -DeviceId 35a63609 -RunId $run -EvidenceDirectory "$out/android"
./tool/flutter_with_proxy.ps1 -FlutterArgs @('build','windows','--release','--target','lib/p1_snapshot_fault_probe.dart',"--dart-define=P1_RUN_ID=$run")
./tool/run_snapshot_fault_probe.ps1 -Platform Windows -RunId $run -EvidenceDirectory "$out/windows"
./tool/check.ps1 -Mode Quality -EvidenceDirectory "$out/quality"
```

构建失败不得启动旧产物；测试后要恢复普通APK/Windows完整目录。目录/设备必需显式选择，脚本默认不会下载工具、改权限或搜媒体。只对自己启动的Windows Process对象Kill；Android仅force-stop诊断包且查旧进程确实消失，不自动重启用户强停应用。

## 未验与下一批

partial-temp是显式写入并flush遗留字节后真实结束seed，证明新进程选择策略，不是FileSnapshotStore.save Future在写入点被强杀，不证明断电/文件系统原子性。真实写中断、多writer/磁盘满、独立engine死亡且backend存活的R2、长Doze、OS回收/完整焦点矩阵、真实私有媒体仍未验。空态明确stopped，存在有效快照才默认paused；不把六种情况统称无损恢复。

下一批建议A08定点更新G-L证据/缺口和可执行后续表，优先明确A04/A07独立组件死亡的可控入口与R2/R3边界；不因这些快照子项通过而放行P2或重写迁移方案。
