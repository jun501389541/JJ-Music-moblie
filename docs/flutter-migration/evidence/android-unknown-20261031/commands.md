# 本批执行记录

root E:/Workspace/project/JJ-Music-mobile，Flutter cwd clients/flutter。开工核AGENTS、开发README/status/handoff、任务索引A03、归属及既有冻结合同，GraphFlow context/plan required submit+merge complete=true。基线HEAD86053e5，上一批Windows原生/测试/文档未提交差异完整保留；本批before保存Android LocalHost及状态/交接。v2.2的20摘要匹配。手机adb devices -l身份仍35a63609/2211133C/fuxi；已选定设备，未新增设备或改全局。

原生Media3使用已在工程锁定的1.11.0；Flutter3.47.9/Dart3.13.7。无新库/编码器/工具安装。API核官方Customization/DataSource资料并以实际本机编译验证；上游特定tag源码和部分参考页抓取cache miss保留为资料限制，不编造内容或拿另一版本代码当本机事实。

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_unknown_duration_test.dart','-d','35a63609','--reporter','expanded')
```

red.log：unknownPcmFixtureUri缺入口，known对照canSeek字段缺失，0通过2失败/EXIT1；先于实现。attempt-1.log：实现真实顺序PCM/观测/能力guard后，unknown自然结束及knownWAV对照2/2通过。之后补pending读取时Stop，以及门控历史有界，与回归一同执行：

```powershell
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/android_unknown_duration_test.dart','integration_test/android_local_playback_test.dart','integration_test/android_service_loss_test.dart','integration_test/android_rebuffer_test.dart','-d','35a63609','--reporter','expanded')
./tool/check.ps1 -Mode Quality -EvidenceDirectory <本批目录>/quality
./tool/check.ps1 -Mode AndroidRelease -EvidenceDirectory <本批目录>/release
```

final-android.log最终14/14/EXIT0；新3、普通本地3、service-loss4、rebuffer4。原生调用、fixture输入及raw状态保留在日志和observations.json。普通WAV能定位3秒；未知PCM nativeDuration=TIME_UNSET、canSeekfalse、duration0且进度增长，拒绝seek匹配android-local/UnsupportedOperationException；不是用同名bool直接确认播放。

未知输入仅解包现有自有tone-long.wav头后的PCM16mono16k，DataSource向消费者暴露C.LENGTH_UNSET、只接受初始position0；专用Extractor不读取/推算WAV长度，仅样本framing与不可定位seekmap。2秒门控防初始EOS已推导时长；它不修改player.duration/state。停止先取消既有readgate后release。没有管道写线程/网络/曲库扫描。EOF后Media3可能推导时长，不能宣称永远未知。

Quality实际检查锁/20冻结与05/格式/analyze/共享39，Release显式lib/main.dart恢复普通入口；结果看report及日志。安装、冷启动、产物摘要另存。本批Windows原生不改/不构建/不运行；原EXE来自前批，不能以Android替代本次Windows证据。

source.patch对照本批before/LocalHost，新增OwnedPcmStream.kt和测试直接在树中，hashes.json存摘要。停止<500ms仅同步接受意图，消费及PCM/gate关闭另等观测；不称OS句柄独立检测或释放延迟<500ms。无提交/推送/发布、旧仓库写入/全局配置或正式UI。

质量补记：首轮quality/因两处if缺花括号lint退出1，未运行到单元/Release。纯语句块修复后quality-final/全部通过，随后release/成功。14项真机为修复前相同控制流，未重复全套设备测试。普通APK安装Success/COLD启动ok/PID14824，见normal-start.log。
