# 本批命令与证据

root E:/Workspace/project/JJ-Music-mobile，Flutter cwd clients/flutter。用户反馈上一批“验收正常”，按用户报告记入status，不扩大为独立听感/完整后台验收。

开工核AGENTS、README、status/handoff、任务索引A03/A04与E2/ownership、最新证据；GraphFlow context/plan，两个required work item submit+merge，complete=true。设备adb devices -l为此前选定35a63609/model2211133C/fuxi/API33，未选新设备。冻结v2.2 20文件哈希匹配。Git无HEAD/暂存/远端，保留所有未跟踪工作；before镜像保存原生和状态交接。

Flutter通过现有tool/flutter_with_proxy.ps1调用，代理仅进程级、已有repo Gradle目录，不变更全局：

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_service_loss_test.dart','-d','35a63609','--reporter','expanded')
```

- red.log：原native onDestroy仅release session，service-loss失败(nativePlaying true)，background-controls通过，EXIT1。
- green.log：首轮安全pause修复，2项通过，EXIT0。
- android-regressions.log：错误填写android_focus_test.dart导致该入口加载失败，其他service登记1/Activity1/rebuffer4通过，整体EXIT1。保留原日志；不能计作全套通过。实际焦点入口为android_audio_focus_test.dart。
- review-red.log：新增满队列和旧销毁/新登记交错，2通过2失败，EXIT1。具体见review.md。
- final-android.log：最终四场景+service登记+真实焦点+Activity+再缓冲，命令如下；总数与退出码以report为准。

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_service_loss_test.dart','integration_test/android_service_registration_test.dart','integration_test/android_audio_focus_test.dart','integration_test/android_lifecycle_test.dart','integration_test/android_rebuffer_test.dart','-d','35a63609','--reporter','expanded')
./tool/check.ps1 -Mode Quality -EvidenceDirectory <本批绝对目录>/quality
./tool/check.ps1 -Mode AndroidRelease -EvidenceDirectory <本批绝对目录>/release
```

本批自有固定12秒WAV，未扫描个人媒体或使用真实源。前台测试先生成真实首帧，再核interactive/未锁定/windowFocus；临时KEEP_SCREEN_ON在finally清理。后台测试仅已有前台服务的延续/OS媒体会话通道pause/play，不是新后台起播特权，也不是真实通知手点或耳机键。

普通Release显式lib/main.dart恢复插件注册；安装到已选手机、启动诊断Activity，命令和产物哈希另存。本批Windows源码未改，不重建或替用户关窗口，保留前批EXE；共同合同质量检查不冒充本次Windows运行验证。

差异在LocalHost.kt.patch、PlaybackService.kt.patch和新增测试。diff --no-index有差异退出1是正常合同，非产品测试失败；hashes.json保留源码/夹具摘要。未提交/推送/发布或改旧Electron/系统配置。
