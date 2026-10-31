# A05 / TC57 Windows初始持续加载：实际实施

2026-10-31，AUTH-P1-WINLOADING-20261031。独立mobile根，旧JJ-Music只读；Git feat/flutter-a01-a02、无HEAD/暂存/远端，已有工作保留。本批完成Windows初始真实流加载、正常/异常关闭，以及Android实际回归中暴露的前台服务资格修复。A03—A08整体仍review，完整G-L不放行。

## 文件与行为

| 文件（相对clients/flutter） | 实际变化 |
| --- | --- |
| windows/runner/owned_gate_stream.h | 新WinRT IRandomAccessStream/ReadAsync，仅显式有界自有WAV字节；首suspend前登记读数、强引用保活、后台等待、取消不可逆、独立clone游标、15秒预算；零读数且source/stream关闭完成后才释放字节 |
| windows/runner/local_playback.cpp | 显式registerOwnedGate/allowOwnedRead，真实CreateFromStream；原file路径不变；逐阶段关闭、错误返回及显式重试幂等、析构不抛出；仅关闭等待期间启用原生timer，在平台线程完成回执，不依赖Dart poll |
| integration_test/windows_loading_test.dart | 4初始加载控制、无Dart poll释放、关闭异常重试，共6场景；使用既有协调器/公共断言，保留真实nativeState与阶段计数 |
| android/.../LocalHost.kt、PlaybackService.kt | 已有前台服务启动超时崩溃的回归修复：计数待登记start，stop不提前拆除；每次onStartCommand都promote后ack，待登记清零再处理已请求stop |
| integration_test/android_service_registration_test.dart | 真正连续3次启动同一前台服务后立即stop，核3次ack、服务退出及7秒后进程仍能应答；不播放音频/静音保活 |
| 根.gitignore | 新生成的私有.graphflow/目录改为忽略，内容原样保留，不读取/删除/暂存私人对话 |

消费R4、共享v2.2共20文件、协议/快照1；共享冻结/05权威合同/依赖锁未改，无新依赖/codec/Rust。不是新架构或正式UI；原生没有新增队列/随机/音质或自动重试规则。关闭阶段幂等只响应同一release的显式重复调用。

源码差异和摘要见[source-diff.patch](source-diff.patch)、[source-manifest.json](source-manifest.json)。角色/allowlist扩展已串行登记status，before/保留真实改前副本。[计划](plan.md)、[完整命令](commands.md)、[退出码](command-results.json)。

## 实际验证

| 层/平台 | 结果和证据 |
| --- | --- |
| 新能力RED | windows-red.log退出1、4失败，缺registerOwnedGate；是新能力缺失，不称旧播放逻辑bug |
| 初轮Windows | windows-initial.log退出0、4项；windows-gate-final.log退出0、5项含无poll释放 |
| 独立审阅发现 | [review](review.md)指出关闭早置closed造成重试假成功；实际注入后[RED](close-error-red.log)退出1，sourceClosed=false但已返回成功，准确复现 |
| 关闭修复 | [close-error-green-suite.log](close-error-green-suite.log)退出0、6项；最终额外断言首次source失败仍会关闭后续stream，第二次才实际补source关闭，结果见close-error-final.log |
| Windows受影响回归 | windows-local-final.log 3项、windows-media-final.log 1项、windows-runtime-final.log 1项均退出0；分别独立Flutter命令，含OS SMTC及真实Widget/CAS/原生资源恢复。合计11个Windows独立场景，不重复累计同用例重跑 |
| Windows启动失败记录 | windows-final.log失败的多入口尝试：首5项通过，后3入口未建立调试连接；同源码单入口windows-local-isolated.log 3项通过。后续独立命令均通过，问题缩小到启动/调试连接层，不称已修Flutter SDK，不以构建代替未跑用例 |
| Android原始回归失败 | android-final.log未完成；[仅本应用退出原因](android-exit-info.log)及[PID7480崩溃](android-crash.log)证实ForegroundServiceDidNotStartInTimeException。设备仍在线、当时Dozing，非断言通过 |
| Android修复后 | 用户解锁原35a63609/Xiaomi2211133C/API33；服务协议先行android-service-red.log因缺新探针失败，非原崩溃的确定性重现。android-repaired.log退出0、9项：服务1/加载4/焦点3/Activity1。新探针3次ack后退出且等待7秒仍可查询 |
| 公共质量及普通构建 | verified-summary.log完整退出0；verified-checks/锁/20冻结及05哈希/格式通过、analyze无问题、39共享测试通过、Android/Windows普通lib/main.dart release构建通过。首轮final-checks的lint失败保留，修复只是新增测试if补花括号 |

Windows真实原生序列：等待期间Opening=1、ready=false、零字节、无确认；放行后MediaOpened/Paused=4仍无确认，只有显式play、Playing=3及实际Position推进才确认。来自SDK枚举和原生取样，不将同名布尔或Android状态当项目playing。[6场景观测提取](loading-observations.json)保留时序/关闭标记，原始日志仍完整保留。

本机同步共享提交pause/stop/cancel/new-play为0/1/0/0ms；观察到旧读数归零及关闭完成分别1283/102/102/406ms（pause包含后续允许、继续、停止，new-play也包含新轨确认等待）。无poll释放观察7ms。不是性能承诺、不是全设备测试。初始Opening不是已经播放后的Buffering恢复证明。

## Android修复的依据与边界

系统栈已证实前台服务登记超时；源码存在startForegroundService之后可能快速stop（包括后续动作失败的catch）而尚未完成服务登记的窗口。现在把系统注册计数与stop分离，并在每个启动回调先promote再ack。没有改变Dart播放意图或做系统权限绕过。新序列与既有加载/焦点/Activity实测通过；没有独立量化旧竞态触发频率，不将一次崩溃栈当所有OEM/Doze异常的唯一原因，也不称完整长期息屏/系统回收矩阵已通过。

独立审阅只覆盖Windows原始差异；Windows关闭修复由红绿用例和回归证明，未重复派审阅。后增Android修复由执行者核对与真机证据支撑，不伪称另有Android独立审阅。

## 程序与简单验收

普通入口仍lib/main.dart。Windows运行clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe，保留整个Release目录。Android普通APK位于clients/flutter/build/app/outputs/flutter-apk/app-release.apk，沿用内部debug签名，不是发行包；最终哈希见[normal-artifacts.json](normal-artifacts.json)。normal-install.log为Success，normal-start.log为Status ok/COLD、PID13442；[Windows普通启动](windows-normal-start.json)为PID13080、窗口句柄3345212、标题jj_music_mobile，已留窗口供用户检查。只证明启动，不冒充人工按钮或听感验收。

普通程序打开“自有样本播放诊断”：播放A位置前进且确认增加一次；暂停后停止推进，继续不重复确认，停止消费者归零。当前界面没有门控/异常注入按钮；这些为自动测试专用能力。门控实测是debug原生运行，不冒充普通release流门控或人工UI/听感验收。

## 仍未验证、下一批

播放后的再次缓冲、未知时长/不可seek、15秒自然超时、16并发/8历史极限、timer ID复用/销毁压力、SDK实际Close自发失败频率、解码器内部峰值内存、全进程回收/外设/人工听感等仍未验。异常注入仅证明受控路径，不代表实际SDK发生率；自有字节与异步读取的完成不等于所有平台内部资源的独立OS证明。

下一批建议A03/A05“已开始播放后再次缓冲”的暂停/取消反例，先设计可稳定诱发的自有输入并核真实API；Android主线继续补长期生命周期/关闭异常诊断等既有缺口。完整G-L、P2和正式UI不自动推进。不提交、推送、合并或发布。
