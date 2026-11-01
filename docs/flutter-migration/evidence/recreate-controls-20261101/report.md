# A04：Activity重建请求与媒体暂停的交错提交

2026-11-01，AUTH-P1-RECREATE-20261101限定目标完成。Codex串行Android/文档维护；分支codex/seek-boundaries保留此前全部未提交工作。只新增android_recreate_controls_test.dart及本批文档，不改生产代码/原生/依赖/UI、v2.3 21冻结或05。无提交推送发布/全局/旧Electron修改。

## 场景和实际结论

两种提交顺序pause-first/recreate-first，两个MethodChannel请求均先发出再await Future.wait。暂停通过本应用MediaSession.controller/transportControls及实际框架Callback进入共享层；要求新增无focusEpoch的plain pause/play记录，避免把焦点事件当媒体控制。不是手点通知/硬件键，也不证明Android特定onDestroy/onCreate区间内的物理同时执行；系统回调仍串行处理。

先自有A真实确认及位置增长，记录当前Activity/engine/host/session/handle和服务创建数。必须观察旧Activity销毁及新Activity创建，Activity id改变但engine/host/session/handle保持，资源1/确认1，未重新创建服务。暂停后shared desired=paused、nativePlaying=false、playWhenReady=false，至少等450ms且获得新原生快照，共享与原生位置各自绝对差<100ms；不能以向后跳位或旧快照通过。恢复前再核paused，只有显式MediaSession play回调后进度增长，仍同一handle/会话/确认1；Stop后消费者0/服务不存在，无共享failure。

这是同一存活engine的Activity重建证明，不是engine/进程被杀后连续播放，也不是无限期自动恢复安全证明。

## 验证与审阅修复

| 检查 | 实际结果 | 证据 |
| --- | --- | --- |
| 初始请求两顺序 | 2/2、EXIT0 | android.log |
| 加plain回调归因和恢复前状态 | 2/2、EXIT0 | android-final.log |
| reviewer修正后最终两顺序 | 2/2、约5秒、EXIT0 | android-reviewed.log |
| 共同测试 | 58/58 | quality-reviewed/tests.log |
| 格式/分析 | 52文件0变化/No issues | quality-reviewed/ |
| 冻结/05/锁 | 原21摘要及权威摘要、锁通过 | Quality检查 |
| Android普通入口恢复 | 原已验v2.3 APK哈希一致，重装后COLD启动ok/PID31159 | install.log、android-start.log、normal-artifacts.json |
| Windows | 本批未修改、编译、启动或运行测试 | 前批证据仍保留 |

一次只读recreate_controls_review指出P2：原单向共享位置delta<100会允许负向跳位，且没有原生位置/新采样断言。执行者改为同时捕获原生位置、等待新host快照、共享/原生绝对差及playWhenReady=false，重新真机和完整Quality全过。没有发现生产缺陷，修补的是测试判断力；reviewer未写文件/跑测试，修订由执行者验证、没有再次派审阅。

observations.json仅从最终android-reviewed.log提取before/paused/resumed/host/raw；test-hash.json记录最终新测试。初始/中间通过不能替代最终更严格暂停稳定性证据。复用已修DiagnosticCleanup，注册亮屏回退和runtime.close覆盖初始化后续失败；KEEP_SCREEN_ON仅本次测试窗口，重建后新窗口重新设置、finally按当前Activity清理，不改系统息屏。

## 命令和交接

cwd clients/flutter，使用现有proxy脚本，过程环境不改全局：

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_recreate_controls_test.dart','-d','35a63609','--reporter','expanded')
./tool/check.ps1 -Mode Quality -EvidenceDirectory <本批绝对目录>/quality-reviewed
```

开工GraphFlow context/plan两项required submit+merge，核A04手册与实际入口、AGENTS/README/handoff/Git、设备35a63609/2211133C/fuxi且Awake，变更后定向index见index.log。只用12秒自有WAV，无账号/私人曲库/真实源。本批Debug测试实际编译运行，普通Release不重建；普通APK哈希核对后恢复，Windows普通程序不动。

手机普通入口仍可检查A播放、定位3秒、暂停继续、停止资源0；新增重建场景是自动化入口，没有包装正式UI。新测试两序列累计作为2个不同场景，不把三轮重复计成6项。

A03—A08整体review/G-L仍未过。下一小批建议A07复核当前v2.3下全进程退出后的快照读回、默认暂停及旧控制器失效，先核独立进程证据入口和前置，不把本批engine存活当进程恢复。长后台/Doze、独立engine死亡接管、系统资源回收、输出丢失、物理媒体键及听感仍留缺口；不P2/正式UI/在线下载。
