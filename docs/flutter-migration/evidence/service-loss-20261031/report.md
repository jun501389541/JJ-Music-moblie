# A04：服务销毁安全退路及已有服务后台控制

2026-10-31，AUTH-P1-SERVICELOSS-20261031限定目标完成。owner Codex串行Android/ConfigIntegrator/文档协调；消费A02 R4/p1-a02-v2.2、20冻结文件、协议/快照1，不改共享合同。旧Electron只读，独立mobile分支feat/flutter-a01-a02仍无HEAD/暂存/远端，保留全部未跟踪工作。未提交/推送/发布、修改全局或安装工具。

用户本轮反馈上一批“验收正常”，记作该批简单验收的用户报告。未另行确认的听感、外设、后台矩阵不能据此代签。

## 改动和红绿证据

设备为已选定35a63609、小米2211133C/fuxi、API33；身份/在线记录见device.log。当前Flutter3.47.9/Dart3.13.7及Git/合同记录见environment.json。自有冻结12秒PCM WAV，无私人媒体或真实源。

仅改LocalHost.kt、PlaybackService.kt及新增android_service_loss_test.dart；before、两份patch与hashes.json可复核。诊断destroyServiceProbe真实调用context.stopService而不调用共享Stop，触发实际Service.onDestroy；不冒充低内存、系统杀进程或独立engine死亡。

red.log先复现：服务已销毁但nativePlaying仍true。初始修复green.log顺序两项通过后，限定审阅指出旧销毁/新登记交错及队列满两个Important。review-red.log将二者实际复现：旧销毁多出安全pause、队列满时shared desired仍playing。执行者在同一修复批处理并完成全部复验，见review.md。

最终行为：

- 非预期服务销毁立即物理pause、abandonFocus，以现有focusEpoch/transportRevision fence生成安全pause，由共享层提交desired；不在原生写队列/恢复/重试规则，不自动重启服务/播放。
- currentService关联具体Service实例，expectedStop在实际stopService/stopSelf前绑定该实例。旧的预期销毁不消费更新登记，不把普通Stop误改成Paused。restartServiceProbe证明同一平台回调内旧stop/new start登记交错；不是所有跨进程竞态证明。
- 安全pause独立单槽，不受32条普通commands容量限制；poll取出并沿用fence，新的focus/transport可令旧安全事件过期。没有放宽公共合同或静默更新冻结摘要。
- 服务损失后显式前台继续：同一host/engine所属会话、同handle、确认仍1，新服务登记成功、进度继续；没有伪造“资源重建后连续播放”。普通停止最终0消费者、无服务、pending登记0。

依据：[Android后台起前台服务限制](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)、[Service生命周期API](https://developer.android.com/reference/android/app/Service)。已有服务延续的后台控制与无服务后台首次启动是不同条件；本批不申请豁免、不改电池优化或绕系统限制。

## 实际验证结果

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| Android服务损失、队列满损失、旧stop/new start交错、已有服务后台控制 | 4/4，EXIT0 | final-android.log、observations.json |
| 前台服务三次登记立即停止 | 1/1 | 同上 |
| 音频焦点释放、真实失焦/恢复、旧回调隔离 | 3/3 | 同上 |
| Activity重建/后台/系统控制原有回归 | 1/1 | 同上 |
| Android真实播放后再缓冲 | 4/4 | 同上 |
| Android合计 | 13/13，01:50、EXIT0 | final-android.log |
| 共享测试 | 39/39 | quality/tests.log |
| 格式/静态分析 | 42文件0变更/No issues | quality/format.log、analyze.log |
| 共享冻结/05/依赖 | 20哈希及05权威哈希一致；锁保持 | baseline.log、Quality/Release检查 |
| 普通AndroidRelease | 构建16.2秒；安装Success，COLD启动ok/PID2870 | release/android-build.log、install.log、normal-start.log |
| Windows | 未改生产源码、未重建/启动/运行本批测试；EXE哈希与上一批相同 | normal-artifacts.json、前批windows-rebuffer-20261031 |

历史失败保留：android-regressions.log有一条不存在的android_focus_test.dart导致整体EXIT1，其余6项通过；最终使用实际android_audio_focus_test.dart复验13项全部通过。red/green/review-red不能替代最终集成结果，也未删除或降验收。

所有四个新增场景均先真实ready/nativePlaying/位置>350确认A；损失两项观察nativePlaying=false/focusHeld=false/共享暂停及位置稳定；恢复与后台控制最终同handle、确认1；停止后四项samples空/servicePresent=false/pendingServiceStarts0。后台控制走本应用MediaSession.controller的真实callback，不是人工通知按钮/蓝牙耳机/硬件媒体键。

## 用户可验收

手机已恢复普通诊断入口。打开“自有样本播放诊断”，播放A，位置应增长；返回桌面几秒后再进入，检查同一会话、暂停/继续有效；停止后资源数最终0。无需扫描曲库。服务销毁和队列满是专属自动化入口，普通UI不增加故障按钮。要复跑使用commands.md的测试命令。

APK：`clients/flutter/build/app/outputs/flutter-apk/app-release.apk`，当前内部诊断签名，不是发布包；大小/哈希见normal-artifacts.json。Windows继续使用上一批普通Release整个目录，不拿本批共同测试冒充Windows真机结果。

## 仍未完成及下一小批

A03—A08整体仍review、G-L未通过。无既有服务的后台首次起播/豁免资格、长期锁屏/Doze、独立engine死亡、系统杀服务/进程、外设/物理媒体键/听感仍未验；不能用stopService/onDestroy替代这些条件。既有Android gated close异常计数限制仍保留。Android/Windows未知时长、不可定位及自然超时/资源压力仍待补。

下一批建议A03/TC57的未知时长与不可定位自有输入，先核平台输入能力和共享合同要求，补双端实际证据；Android其他生命周期按资源条件继续，不提前P2/正式UI/在线/下载。GraphFlow定向index结果见index.log。
