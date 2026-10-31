# 执行记录

root E:/Workspace/project/JJ-Music-mobile；Flutter cwd clients/flutter。开工核AGENTS/README/status/handoff、任务索引A03/A05、归属及05/现有代码；GraphFlow context、plan required两项submit+merge complete=true。基线86053e5、工作区干净，20个v2.2冻结哈希匹配，见baseline.log。按用户继续开发登记本批范围，不自动重复提交推送。

```powershell
flutter test integration_test/windows_unknown_duration_test.dart -d windows
```

- test-compile-error.log：首次测试误用until(timeout:...)，实际现有helper为seconds参数，修正测试后才做行为红绿；不把编译失败视为功能反例。
- red.log：2项canSeek预期false实际null，EXIT1，说明原入口尚无该能力观测。
- green.log：加入未知模式及能力检查后，实际0/12000/拒绝seek/暂停恢复及自然EOS均已走到，但closed断言读到上轮原生快照而失败，EXIT1。消费者关闭回执与下一poll快照不同时到达，不能把旧快照当资源泄漏。
- final.log：增加等待原生gate.closed的下一快照；2/2通过、EXIT0，约14秒，未改变产品代码或降低物理资源要求。
- 原有windows_rebuffer_test、windows_loading_test、windows_local_playback_test、windows_media_test逐个独立运行，各自日志；避免既有多入口debug连接问题。

```powershell
./tool/check.ps1 -Mode Quality -EvidenceDirectory <本批目录>/quality
./tool/check.ps1 -Mode WindowsRelease -EvidenceDirectory <本批目录>/release
```

Quality核锁/20冻结/05权威哈希/只读格式/analyze/共享39；Release显式lib/main.dart恢复普通插件注册并检查锁不变。实际退出码与结果见report及各日志，不把计划命令算执行。普通程序启动8秒观测及产物哈希另存normal-artifacts.json。

source.patch为相对86053e5的三个原生文件差异，新增测试直接在工作区；hashes.json记录实际源码/测试。observations.json由final.log两行WIN_UNKNOWN提取，保留完整raw/关闭计数，不改写原证据。未新增媒体、解码包或SDK；无全局配置/旧Electron写入/真实源/个人曲库/正式UI。

Android已有设备35a63609仍在线且身份一致，但此批未改源码/构建/运行；固定WAV头声明长度，不将其当未知时长证明。Android最新实测仍service-loss-20261031；本批Windows不可定位是原生能力入口拒绝，不是共享seek命令能力协商/界面禁用验收。

SMTC故障追加命令：旧windows_media_test.log为error:true；windows-media-diagnose.log记录owned-properties/0x80070015；windows-media-final.log为probe缺Windows.h编译失败；windows-media-fixed.log修复后四命令通过但skipped0；启动普通Release保持未播放窗口，再跑windows-media-candidate.log，四命令skippedNotReady1并acceptedtrue/EXIT0。首次release/失败LNK1104，核对旧自启动两进程路径后CloseMainWindow；最终WindowsRelease用release-final/日志避免覆盖。只读服务状态为Running，未变更服务。
