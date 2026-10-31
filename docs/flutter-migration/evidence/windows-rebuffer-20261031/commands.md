# 本批命令及运行入口

根目录 E:/Workspace/project/JJ-Music-mobile；Flutter命令工作目录 clients/flutter。使用已有 E:/SDKs/flutter/bin/flutter.bat；无工具安装或全局配置修改。

1. 核对root AGENTS、README/status/handoff/任务索引/A05/05/ownership和最近证据；GraphFlow context、plan桥接submit+merge。status登记AUTH-P1-WINREBUFFER-20261031；before保存源码与状态交接，baseline核v2.2的20文件哈希。Git仍feat/flutter-a01-a02、无HEAD/暂存/远端，旧仓库HEAD 4f47d10cd4d8deb0118e35198105f11bee754246、tracked diff为空。
2. `flutter test integration_test/windows_rebuffer_test.dart -d windows` → red.log，EXIT=1，4项MissingPluginException(registerOwnedPcm)，验证新入口未实现。
3. 新增原生PCM门控后，同命令 → attempt-1.log，EXIT=0，4项通过。原生构建19.7秒，运行约8秒。observations.json提取4场景完整原始状态和关闭计数；保留原日志。
4. 原有入口各自独立执行 `flutter test integration_test/<入口>.dart -d windows`：windows_loading_test、windows_local_playback_test、windows_media_test、runtime_recovery_test。逐文件日志存同目录；最终结果看report。沿用既有规避多入口debug连接问题的方法，不改SDK。
5. `./tool/check.ps1 -Mode Quality -EvidenceDirectory <本目录>/quality`：锁依赖、20冻结文件及05合同哈希、只读格式检查、analyze、共享测试；各日志保留。
6. `./tool/check.ps1 -Mode WindowsRelease -EvidenceDirectory <本目录>/release`：显式lib/main.dart，恢复普通入口的插件注册，核锁文件不变。启动普通EXE并记录进程/窗口，产物哈希另存normal-artifacts.json。

可手动复跑新增4场景（会启动并自动关闭测试窗口）：在clients/flutter终端运行第2条命令。仅自有tone-long.wav，无网络或个人文件扫描。普通诊断界面没有再缓冲门控按钮；不能用普通按钮冒充该自动化测试。此次不重建/安装/运行Android，使用前批报告，不把其他端替代真机结果。

实际差异：local_playback.patch、owned_gate_stream.patch、新owned_pcm_source.h与windows_rebuffer_test.dart；新增文件/夹具哈希在input-hashes.json。git diff --no-index有差异退出1为正常输出合同，非测试失败。未暂存/提交/推送/发布。

启动观测补记：2秒观测后，后续工具调用已找不到PID46856，原因未确定，未当崩溃结论。再次独立启动并同一调用内观察8秒，PID47532/窗口600200且exited=false，见startup-followup.json。跨调用持续存活/人工听感仍未验。启动调用尾部可选事件查询无结果导致外壳EXIT1，不是构建或8秒运行失败；未据此声称系统无崩溃。
