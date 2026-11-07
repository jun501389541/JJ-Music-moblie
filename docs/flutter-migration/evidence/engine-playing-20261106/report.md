# A04/A07 播放态显式engine销毁（2026-11-06）

AUTH-ENGINE-PLAYING-20261106限定目标完成。Codex串行A07诊断/文档维护。沿用[上批真实engine销毁入口](../engine-loss-20261106/report.md)，只修改p1_process_probe.dart诊断代码与run_android_engine_probe.ps1，未改native、正式运行时/界面/依赖、Windows或v2.3/21冻结。基线ee0e347/codex/seek-boundaries；全部旧未提交工作保留，本次无提交推送发布/全局/旧库/P2变化。

## 本批差异与验收

编译P1_ENGINE_PLAYING=true（同时必须P1_ENGINE_LOSS=true且Android）后，save先沿既有流程真实保存2345ms暂停快照。随后同handle显式继续，等待共享进度和原生nativePlaying，并记录两次同handle原生采样，位置必须递增超过200ms；仍仅一个消费者、共享desired=playing、确认凭据不增加、无协调器失败。记录lossWhilePlaying之后请求既有真实engine销毁，不等待将被销毁Dart的Future。

新RequirePlaying控制器开关拒绝缺少观测、非playing、多消费者、不同handle、不推进或首采样未超过保存位置100ms的回执；原暂停态模式不传该开关。恢复仍核同PID、新engine和coordinatorEpoch、完整磁盘/运行快照、旧claim拒绝、默认暂停、显式继续、再次暂停继续去重及最终Stop。既有源/命令/队列规则没有复制到原生。

| 检查 | 实际结果 |
| --- | --- |
| 设备 | 已选小米35a63609/2211133C/fuxi，实际核在线Awake |
| Release探针 | build.log退出0，42.5MB，P1_RUN_ID=playing-loss-20261106-a1；另两个optin编译参数均true |
| 播放态销毁恢复 | run.log退出0，device/android-engine-proof.json；PID18536保持，engine26135275→160958312 |
| 销毁前真实播放 | 两原生采样nativePlaying均true，同native-1，2465→2707ms；shared playing/consumer1/确认不增 |
| 销毁/恢复 | 真实destroy回执players0/focusHeld=false；新engine读回同session/revision1/2345ms默认paused且consumer0；旧claim拒绝stale-controller；显式继续2709ms，重复暂停继续不新增确认，Stop0/最终空native samples/服务退出 |
| 共同检查 | quality-run.log退出0；53文件格式无变更、analyze无问题、58共同测试通过，锁定依赖/21冻结+05权威摘要通过 |
| 普通入口 | 本批native/普通main未变，核哈希还原上批普通APK（normal-restored.json），安装Success，普通MainActivity冷启动Status ok/COLD；未重新构建普通Release |
| Windows | 未修改、未构建/运行，不用Android结果代验 |

未重复上批5项Android原生/Activity回归，因为本批只改专属探针与控制器、没有native逻辑变化；新的播放态路径实际验证替代无关重复。原生service停止异步，销毁回执不能证明瞬时Service.onDestroy已完成，最终服务为空来自恢复停止后的采样。

## 运行与边界

独立只读reviewer engine_playing_review聚焦新增Dart块与RequirePlaying断言，未发现需修复问题，未运行设备或编辑文件。确认恢复分支与普通入口不受影响；样本证明销毁前最近窗口，不是销毁瞬间的原子播放状态。实际设备与共同检查由执行者完成。

构建cwd clients/flutter：

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_process_probe.dart','--dart-define=P1_RUN_ID=<新runId>','--dart-define=P1_ENGINE_LOSS=true','--dart-define=P1_ENGINE_PLAYING=true')
./tool/run_android_engine_probe.ps1 -DeviceId 35a63609 -RunId <新runId> -RequirePlaying -EvidenceDirectory <新绝对证据目录>
```

构建失败不得跑旧APK，两个启动必须用同次构建；用过的runId不可复用，结束恢复普通入口。本批普通APK位于clients/flutter/build/app/outputs/flutter-apk/app-release.apk，用户可正常打开诊断界面播放A/定位3秒/暂停继续/停止资源0；没有新增正式UI销毁按钮。

本次是“正在播放时收到明确诊断销毁请求”，仍是可控清理路径，不是OS猝死/异常崩溃或不清理就无损R2。恢复位置为最近已落盘2345ms，并非2707ms实时内存位置；两采样证明请求前运行，不保证每个采样间隙的物理声音。自有12秒样本，无真实源/个人曲库/账号；人耳听感未代签。旧claim拒绝仍仅逻辑控制权，不外推生产Broker端点撤销。

G-L及A04/A07整体仍review。剩余独立权威R2接管、真实异常组件回收、长Doze/OS服务回收、真实写中断/断电、外设/媒体键/听感未齐。下一小批建议先结合A08矩阵核实R2能否在当前宿主成立及其安全退路，不能把同一显式engine销毁再改名成异常死亡通过。GraphFlow计划已桥接submit/merge，修改后定向index见index.log。
