# A07 当前合同双进程恢复验证

日期2026-11-01（Asia/Shanghai）；授权AUTH-P1-PROCESS-20261101。限定目标完成，A07整体仍review/G-L未过。

## 改动与前置

在独立mobile目标工作区按R4、05 C-03、归属表和E2/E4继续A07。A02真实文件、A04/A06已有主路径证据；不将这些任务的review或本批子项通过写成完整前置验收。消费p1-a02-v2.3/21文件冻结，协议/快照1不变。仅改诊断入口lib/p1_process_probe.dart、两端tool/run_*_recovery_probe.ps1，以及本批证据/status/handoff；不改LocalRuntime、共享模型/原型存储、原生、依赖或正式UI。所有之前未提交测试/证据保留，分支codex/seek-boundaries，HEAD 4b5d4b8e0f357a492f0efafab92d4cf6d5db1e22，before.log/actual.diff可查；不提交推送发布。

原探针固定process-proof目录和20261031证据路径不适合本批：现必须用P1_RUN_ID编译隔离、控制器RunId核对，禁止复用已保存runId/覆盖已有proof。Windows临时根在graphflow-out/p1-process-<runId>；Android在诊断应用私有临时目录jj-owned-p1/recovery/<runId>，与普通owned-p1及Electron数据分离。完整路径见proof，测试只读写自有12秒tone-long，2队列条目。沿用原型256KiB/16条目/64确认上限，不引入DB。

控制器只在saved凭据后终止旧进程，Android用force-stop后显式am start，Windows仅Kill自己启动的Process对象。新进程同二进制读取同目录，逐字段核对磁盘与真实内存队列顺序/索引、模式、试听、session、revision、position、confirmations。新的coordinatorEpoch、PID不同；不复用native handle。旧claim只在额外probe-authority.json诊断sidecar记录并向新协调器直接重放stop，未加入共享持久合同，未建立RPC。拒绝stale-controller且700ms后游标/位置不变、默认暂停、零资源。显式resume才prepare并播放；原生sample直接供共享progress与确认，不靠Dart计时器猜播放。再次pause/resume同handle、确认不增；Stop待新poll空samples，Android服务/焦点释放。

## 实际结果

| 检查 | 最终证据与结果 |
| --- | --- |
| Android Release探针编译 | android-final-build.log，退出0，42.5MB诊断APK；非普通UI安装包 |
| 小米真机双进程 | android-final-run.log，退出0；35a63609/2211133C/fuxi/API33，开工Awake；android-final/android-process-proof.json |
| Android保存→恢复 | PID12576→12739，epoch1793493640495578→1793493642174154；修订1、同逻辑session、位置2345ms、完整运行快照一致；暂停零资源/旧claim拒绝；显式resume位置2780ms；再次恢复去重；stop0/新空samples/servicePresent=false/focusHeld=false |
| Windows Release探针编译 | windows-final-build.log，退出0；同一exe和app.so摘要见windows-final/windows-process-proof.json |
| Windows双进程 | windows-final-run.log，退出0；PID35900→44572，epoch1793493690593138→1793493692660475；修订1、同session、位置2345ms、完整运行快照一致；暂停零资源/旧claim拒绝；resume2723ms；再次恢复去重；stop0/新空samples |
| 最终共同检查 | quality-final-run.log退出0；quality-final内：锁定pub get、21冻结文件和05权威摘要、格式52文件0变更、analyze无问题、58/58共同测试全部通过 |
| 普通入口恢复 | 原APK和Windows完整目录逐文件摘要匹配备份，见normal-restored.json；并非重建普通Release。手机install Success、冷启动Status ok/COLD，见ordinary-*.log；Windows普通程序存活2秒、启动后关闭，仅普通启动检查，无额外播放验收 |
| 独立审阅 | review.md，指出的两项P2已修并复核，无限定验收残留问题；审阅者未执行测试，实际运行由执行者完成 |

每端是1个最终双进程场景，不把反复运行累计成额外场景。原始最终proof同时含磁盘和运行快照、原生resume/stop采样；Android另外stage-save/restore.log核token和PID来源。恢复后首次重新prepare新增第二个播放确认合理；后续同handle暂停继续不再增加，并非所有恢复均不得新增确认。

## 失败与修复记录

- analyze-initial.log：诊断代码误写不存在的cursor，按实际合同改eventCursor；无生产缺陷。quality首轮及最终均通过，最终以quality-final为准。
- Android a1首轮通过，但审阅发现仅比较磁盘及首fixture不能证明实际完整队列恢复；补runtimeSnapshot与disk一致检查及Stop新原生采样。a1历史输出保留，不充作最终验收。
- Android a2底层检查结束后大JSON被Android单条logcat长度截断，android-reviewed-run.log退出1/ConvertFrom-Json Unexpected end。不得计通过。a3仅移除resumeHost/stopHost重复lifecycle时间线，保留完整samples/host资源字段并记录阶段原始日志，重新编译和实际执行通过。不是删断言降低条件。
- Windows原脚本可能在proof刚创建尚未完整时解析半截JSON。按审阅补同deadline内有界重试并初始化清理变量，所有失败路径只清理本次Process；本批最终实跑通过，不宣称在真实调度中单独注入重现了半写竞态。
- git diff --check三项本批代码通过；全工作区status的既有历史追加行存在CRLF/空白提示，本批保留不顺手重写其他批证据。

## 复现命令

cwd E:/Workspace/project/JJ-Music-mobile/clients/flutter。前置现有Flutter/Dart、两端工具链和已选择手机；先按plan备份普通产物。本例用新的独立runId，不能照抄复用已验a3/w2；两次启动必须使用同次构建。普通目录含整套Windows DLL/data，不能单拷exe运行。

```powershell
$run = 'recovery-' + [Guid]::NewGuid().ToString('N')
$evidence = 'E:/Workspace/project/JJ-Music-mobile/graphflow-out/recovery-' + $run
./tool/flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_process_probe.dart',"--dart-define=P1_RUN_ID=$run")
./tool/run_android_recovery_probe.ps1 -DeviceId 35a63609 -RunId $run -EvidenceDirectory $evidence
# Windows在普通程序已关闭时独立构建和运行
./tool/flutter_with_proxy.ps1 -FlutterArgs @('build','windows','--release','--target','lib/p1_process_probe.dart',"--dart-define=P1_RUN_ID=$run")
./tool/run_windows_recovery_probe.ps1 -RunId $run -EvidenceDirectory $evidence
./tool/check.ps1 -Mode Quality -EvidenceDirectory "$evidence/quality"
```

所有构建/测试均用已有可信依赖与锁；代理脚本只改子进程环境，不改全局。构建失败不得执行旧产物；实际本批按每条退出0才继续。测试后需恢复之前备份的普通APK/Windows整目录；当前已完成恢复。

GraphFlow context/plan的required桥接已submit/merge，变更后按文件定向index，见index.log。Dart/Markdown已更新或返回unchanged；两项PowerShell返回extension not in includeExtensions，表示现有图配置不解析该类型，并非脚本无修改或已图谱覆盖。本批不改全局/图配置，以actual.diff、PS解析检查和双端实际运行补充；后续查脚本仍需定点读文件。

## 用户检查与未验范围

手机当前普通诊断入口可直接打开：播放A→定位3秒→暂停→继续→停止，期望进度按意图变化、Stop资源0。Windows双击clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe，保持其DLL/data目录完整。两端仍是诊断程序，新增强杀检查由独立自动化探针执行，没有新增正式UI按钮。

本批只证明已保存后强杀、新进程显式R3恢复；700ms无自动播放不是长期后台保证。未验证断电/正在写入时进程死亡、双slot损坏/未知版本/丢失fixture的真实新进程退路；已有共享单测不替代这些场景。未覆盖独立协调器死亡且后端存活的R2无损接管、系统资源回收、长Doze/机型矩阵、硬件媒体键或人工听感，不将Androidforce-stop解释为系统自动重启能力。完整A03—A08/G-L仍review。

下一最小批：A07隔离目录内损坏/缺失/未知格式快照的新进程安全退路，以及保存中断后选择最后有效修订；仅自有诊断副本，优先复用真实FileSnapshotStore能力和现有单测，不改合同、不提前P2。
