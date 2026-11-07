# A04/A07 显式engine销毁安全R3（2026-11-06）

AUTH-ENGINE-LOSS-20261106限定目标完成。Codex串行Android/A07/ConfigIntegrator维护；基线ee0e347，codex/seek-boundaries，保留已有snapshot-faults和A08全部未提交修改。旧仓库只读，不提交推送发布、不改正式UI/全局/依赖/P2。消费R4/05 C-03/E2及v2.3/21冻结，协议/快照仍1。

## 实际实现

LocalHost新增显式destroyEngineProbe：限已选诊断save模式、非空启动token；先回请求已接收，再post Activity.finish。MainActivity在super.onDestroy完成与engine分离后调用待执行销毁钩子；没有pending请求的普通Activity路径不执行销毁。native取消自有读门、暂停释放播放器、释放焦点、请求停止服务、清旧命令与pendingSafetyPause、清cached，实际FlutterEngine.destroy返回后才输出绑定旧engine/PID/token的原生回执。不实现原生队列或恢复策略。

已有p1_process_probe增加仅编译P1_ENGINE_LOSS=true时生效的save后请求，使用unawaited，不等被销毁Dart的Future；同时记录Android真实engine-create标识。新run_android_engine_probe.ps1先取得saved，再等原生destroyed回执，禁止用force-stop代替中间销毁；核同PID/不同engine后显式启动restore，复用真实文件读回、旧claim拒绝、默认暂停、显式继续/重复确认去重/Stop验证。回执超时或进程死亡直接失败。启动前和最后清理的force-stop不属于中间独立engine销毁。

## 实际验证

| 检查 | 结果及证据 |
| --- | --- |
| 手机身份 | 35a63609/2211133C/fuxi，用户连接后核在线Awake；仅此自有样本 |
| Android探针Release | build.log退出0，42.5MB；P1_RUN_ID=engine-20261106-a1 / P1_ENGINE_LOSS=true |
| 实际独立engine销毁 | run.log退出0，device/android-engine-proof.json；保存/恢复PID均13305；旧engine26135275→新241633931；真实destroy回执players0/focusHeld=false，token与旧实例匹配 |
| 恢复 | 同session/修订1/位置2345ms，完整runtime与disk一致，coordinatorEpoch更新；默认paused且无播放资源，旧claim停止请求拒绝stale-controller；显式继续后2779ms，再次暂停继续同handle不重确认；最终Stop0、空native采样/服务退出 |
| Android回归 | android-regression.log退出0，真实本地播放3项+Activity重建控制交错2项，共5项通过 |
| 共同检查 | quality-run.log退出0：锁定依赖、21冻结+05、格式53文件0变更/analyze无问题/58测试通过 |
| 普通Android入口 | ordinary-release/android-build.log与ordinary-build-run.log退出0，重新构建lib/main.dart，安装Success/普通冷启动Status ok；摘要见ordinary-hash.json。探针备份仅graphflow-out/engine-loss-20261106 |
| Windows | 本批未构建/启动/测试，未修改Windows原生；不能拿Android结果代替Windows恢复证据 |

SDK XML版本警告出现在构建日志，但构建最终成功；未因此安装工具或改全局配置。无生产失败被复现，不制造假RED；这是新增真实生命周期验证。实际saved回执含1个已暂停原生资源（另由执行者读取proof断言确认1），销毁后0；runner未把此保存前资源数写成通用断言，未来扩大场景须补强，不宣称覆盖任意初态。

## 独立复核与限制

新上下文只读reviewer engine_loss_review核四项改动及相关生命周期，未编辑/执行设备；无阻断缺陷。明确服务停止是异步：engine-destroyed只证明players/focus，不能称同一回执证明Service.onDestroy完成；最终stopHost服务为空是恢复结束时证据。

这是显式诊断请求、已保存且暂停持有一轨后的组合R3安全释放与恢复，不是系统异常销毁、正在出声时猝死、或保留原生资源无损R2。旧ControllerClaim拒绝不等于已实现通用Broker令牌/跨进程端点撤销；本地P1没有该生产Broker。engine地址hash为本次观察标识，配合真实destroy返回和新创建事件，不单凭不同hash推断死亡。没有自动拉起用户强停应用，新engine由外部明确启动。

A04/A07/G-L仍review。剩余R2存活权威接管、播放中非预期engine死亡、真实写中断/断电、长Doze/OS回收、物理输出失效/媒体键/听感未齐。下一最小批建议扩展显式engine销毁前正在播放的场景并记录持续原生采样；先核本入口的边界，不重复整个方案或自动P2。

## 启动与复现

手机已安装普通技术诊断入口：可播放自有A、定位3秒、暂停/继续、停止资源0。该普通UI不添加销毁按钮。APK为clients/flutter/build/app/outputs/flutter-apk/app-release.apk（内部诊断签名），Windows仍使用现有完整Release目录。安装/启动不代替本批真实测试结果。

开发者复现需新runId、已选解锁设备且先备份普通产物，cwd clients/flutter：

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('build','apk','--release','--target','lib/p1_process_probe.dart','--dart-define=P1_RUN_ID=<新的runId>','--dart-define=P1_ENGINE_LOSS=true')
./tool/run_android_engine_probe.ps1 -DeviceId 35a63609 -RunId <新的runId> -EvidenceDirectory <新证据绝对目录>
```

构建失败不运行旧APK。结束用check.ps1 -Mode AndroidRelease重建普通入口，再安装恢复；不能交付探针。本批GraphFlow context/plan required桥接已submit/merge，修改后定向index；PS按现有图扩展配置可能跳过，仍有语法和实际运行证据。完整代码差异见source.diff（新runner另直接核源文件）。
