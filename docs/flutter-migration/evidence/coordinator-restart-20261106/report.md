# A07 R2边界与新协调器安全恢复（2026-11-06）

最终接续结果：用户解锁后Android完整重跑通过，见android-retry.log（退出0），本批限定双端目标完成。Android PID26238，旧epoch1793961383404042→新1793961384773375；完整快照修订1/位置2345、默认暂停、旧claim拒绝、释放及最终native samples为空。普通APK恢复安装并冷启动Status ok/COLD，见ordinary-final-install/ordinary-final-start.log。最终共同检查见quality-final-run.log/quality-final：58测试、54文件格式0变化、analyze、21冻结+05/锁全部通过。

接续修正：首次解锁后android-final.log在前台断言失败，尚未开始播放。首帧不保证window focus已到达，改为最多30次、每次100ms等待同一diagnosticForeground谓词，并pump等待焦点；解锁/亮屏/窗口焦点要求不变，不绕锁屏。android-retry.log证明修改后实际通过。保留初始Dozing中止和此次门检查失败，不混作产品恢复失败。修改只影响Android启动门，Windows既有通过结果不变，未重复该端路径。以下“待解锁/partial”文字是接续前历史，当前结果以本段为准；无损R2依旧未实现/未验证。

AUTH-COORD-RESTART-20261106。Codex串行诊断测试/文档维护；新增integration_test/coordinator_restart_test.dart，不修改产品/原生/共享冻结。分支codex/seek-boundaries，基线ee0e347，所有前批未提交修改保留，不提交推送发布/P2/正式UI/全局/旧库。GraphFlow context/plan桥接已submit/merge，修改后index。

## 代码事实及取舍

PlaybackCoordinator.acquireController修改同一对象的_owner/_epoch并失效旧准备，不创建新协调器。dispose取消订阅并逐轨释放；LocalRuntime.close继续backend.close和writer锁关闭。restoreSnapshot从持久逻辑状态恢复默认暂停，不恢复native handle。NativeLocalBackend的请求/handle映射是Dart内存；原生poll提供采样不是带完整会话/队列/确认权威的adopt接口。因此现有CAS换owner不是R2独立协调器重建，不能把旧对象复用/新对象读盘称无损接管。

本批不擅自新增恢复协议或重写冻结：按05 C-03及E2验证已有安全释放/暂停恢复退路，R2仍未实现/未验证。若后续实现无损R2，须先提出共享状态转移、独占接管/事件路由、旧订阅退休但不释放资源、pending/transition/confirmation核对的具体合同变更，按A02归属更新版本和两端消费者；不能只把私有字段复制到新对象或保留两位活跃协调器。本批不创建此类空壳架构。

## 新测试

真实LocalRuntime播放A并推进，暂停定位2345，await真实saved；再次播放推进后await旧runtime.close，直接native poll确认资源空，再同runId创建全新LocalRuntime。通过object identity和不同coordinatorEpoch证明新协调器，完整逐字段恢复disk状态/修订，默认paused/无tracks/consumer0。旧claim发Stop必须拒绝且700ms后cursor/位置不变；显式继续实际nativePlaying和进度增长后停止，资源0/最终采样空。closeFirst缓存Future且DiagnosticCleanup逆序清理，避免重复非幂等close。

700ms是状态/原生末端观察，不宣称连续硬件静音或采样间隙无瞬态资源；同进程安全close/recreate，不是异常崩溃、强杀或无损R2。native handle字符串可能复用，所以不以字符串不同冒充资源实例证明，而是先实测释放到0再从空态重新prepare。

## 分端结果

| 验证 | 实际结果 |
| --- | --- |
| Windows真实测试 | windows.log退出0，1项通过；PID40192，epoch1793958067345647→1793958068603113，修订1/位置2345、同session/完整队列、stale-controller、释放及最终samples均空 |
| Android | 开工35a63609/2211133C/fuxi在线Awake；测试启动后停在首个widget阶段，随后实际观察Dozing，执行者中止（exit1），android.log保留。未输出通过，不能代验为系统/产品失败或R2通过。已请求用户解锁，等待重跑 |
| 测试环境修正 | 增加Android测试窗口KEEP_SCREEN_ON，清理动作先登记，结束移除；不修改系统息屏配置。该分支已静态检查，尚未在解锁设备实际重跑；Windows逻辑未变 |
| 共同检查 | quality-run.log退出0；54文件格式0变化/analyze无问题、58共享测试通过，21冻结+05/锁通过 |
| 普通产物 | Windows原Release exe/app.so摘要未变，未重启普通程序；Android已停止中止测试进程，原普通APK还原安装Success，不对锁屏下启动作验收 |

独立只读reviewer coordinator_restart_review未发现阻断问题，核真实对象/完整快照/旧claim拒绝/清理逻辑；明确700ms观察边界。未修改或执行设备。Windows运行在追加Android亮屏清理分支之前，该变更不影响Windows控制流；之后Quality通过，没有重复Windows实际路径。

## 接续命令与缺口

先由用户唤醒并解锁已选手机，核实际foreground，不注入解锁/绕锁屏；cwd clients/flutter：

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/coordinator_restart_test.dart','-d','35a63609','--reporter','expanded')
```

将最终输出保存新日志，不覆盖中止记录。成功后停止测试程序/恢复普通APK；不把单元、编译或Windows通过代替手机结果。若未接续本批，先核代码和证据再按同一任务重跑，避免重复创建测试。当前限定批次partial，Android待解锁；A07/G-L仍review。R2架构缺口与设备缺口分开保留，不因为手机接入就宣称无损接管已实现。
