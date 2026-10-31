# P1-A 20261031：实施、验收与G-L缺口

执行根E:\Workspace\project\JJ-Music-mobile；分支feat/flutter-a01-a02，无HEAD、无暂存/提交/远程；旧Electron只读。用户授权A03—A08、自有媒体和常规修复；唯一选定Android设备35a63609/Xiaomi2211133C/Android13(API33)/arm64。工作按小批串行，角色由Codex兼任并记录ledger；未进入在线/下载/DLNA/P2/正式UI。

## 实际完成的实现

- 薄Android Media3 1.11.0与Windows系统WinRT真实本地后端；同一Dart协调器/规范化端口/共享断言，原生无队列、随机、音质或重试业务。Windows不含mpv/FFmpeg/Rust，Android无外部存储或音源授权。
- 自行生成12秒PCM WAV及原有0.5秒样本；实际file/content URI、暂停、定位、停止、快速切换、坏文件/读取拒绝、自然结束和释放；项目播放确认依据原生状态与直接位置推进，并经共享身份围栏，不靠按钮或同名布尔。
- Android cached engine独立于Activity，前台媒体服务+平台MediaSession回调；Windows唯一手动SMTC镜像确认快照，OS控制返回共享入口。
- R1界面订阅/真实组件替换不load/play；在存活权威处CAS换owner，旧命令拒绝；原生播放器资源独立销毁后只变backendEpoch、默认暂停，再明确恢复。
- R3隔离双槽文件保存完成后，控制方强杀旧进程，用同一探针二进制/同目录启动新进程读回，确认PID和运行epoch不同、逻辑会话/修订/位置/确认凭据相同，默认暂停、零播放资源。恢复原型不是正式数据库，不依赖退出flush。

## 验证索引（实际退出0/通过日志）

| 平台/层 | 实际证据 | 限制 |
| --- | --- | --- |
| 共享 | shared-tests.log 38项；analyze.log无问题；各红绿日志 | L1不代替真实平台反例 |
| Android本地 | android-local-final.log 3项；android-event-mapping.md | 自有PCM WAV/私有提供方，非全部格式/所有content URI |
| Windows本地 | windows-local-final.log 3项；windows-event-mapping.md | 系统默认输出；无人做听感确认 |
| Android生命周期 | android-lifecycle-final.log：Activity/engine/host实例、后台推进、系统pause/play、确认去重 | 短时真机，不代表长时Doze/所有机型/电话蓝牙 |
| Android关屏 | android-screen-off.log：原生screenInteractive=false及>4秒推进，共享确认一次 | 原timer-only日志不是关屏证据；shell输入被拒绝，未绕过安全设置 |
| Windows系统媒体 | windows-media-final.log：独立OS探针pause/play/seek/next及timeline，非直接调用共享命令冒充OS | 物理媒体键/可见系统面板人工验收未做 |
| R1/R2前置/组件资源 | windows-runtime-final.log、android-runtime.log：真实Widget替换、存活权威CAS、旧owner拒绝、原生资源销毁/epoch隔离 | 不是Dart engine已死但原生资源独存时的无损R2 |
| 两进程R3 | windows-process-proof.json、android-process-proof.json及*-process-run.log | 专用测试入口lib/p1_process_probe.dart；同一端两次启动同一二进制。最终普通产物另见artifacts-final.json，不混为同一构建 |
| 普通诊断UI | windows-ui.log实际按钮/route replacement/保存/停止；Android UI日志保留 | Android再次自动息屏使额外按钮测试未完成；核心组件测试已在用户解锁后通过。未把未完成写通过；UI测试增加交互屏幕前置与仅测试期间KEEP_SCREEN_ON，不改全局息屏配置 |
| 最终普通构建 | windows-release-final.log、android-release-final.log、android-release-install.log | Android仍是内部调试签名；非发行 |

## 审阅与常规修复

独立只读审阅发现：硬切新轨在首次确认前失败/取消会把旧轨留在物理暂停、逻辑playing。先补2个红例，修复共享回滚及原生play失败归一化，再补两端真实故障注入：先暂停旧轨再令新轨失败，必须看到旧轨原生running且位置继续推进，不能拿陈旧sample通过。复审确认解决、未发现新增重要问题，审阅者未跑测试，主执行者日志是验证依据。合法空快照也先红例后修复为安全暂停空态。

其他修复：C++20/MSVC头文件、prepare取消Future监听竞态、重复release必须等待同一物理关闭、恢复resume重复请求签名、控制脚本pidof启动空值。SMTC测试曾在镜像尚处暂停时过早发暂停，OS已接受但无动作；改为等待真实镜像playing/timeline就绪后测试，未把accepted当应用已暂停。失败/旧日志保留，不覆盖历史A01/A02证据。

## G-L结论：暂不通过完整门

已证明以上双端主路径。下列仍缺必需/边界证据，任务保留review而不宣称整个A03—A08/播放器完成：

1. 真实持续加载/缓冲中暂停、取消与恢复的完整TC-57反例。自有短本地WAV加载很快，L1能卡住Future/反例，但不能代替两端真实后端持续缓冲。未知时长/不可seek提供方、真实旧回调迟到序列也未完整诱发；端口能力查询/生产格式矩阵尚未完备。
2. Android独立engine死亡但原生资源存活、独立服务回收/焦点中断等完整实例矩阵。当前只证实Activity保留engine、原生播放器资源独立销毁和全进程R3；不能据此声称无损R2接管已死Dart权威。
3. Windows实际输出设备拔出/失效、物理媒体键、系统界面视觉及两端人耳听感未验；不修改系统设备配置去假造成功。Android额外按钮烟测需保持解锁亮屏再跑。

后续仍限本阶段：补可靠自有延迟/未知长度本地输入能力、两端事件反例与实例故障矩阵，再复审G-L；不自动进入P2。不要求用户选择类名/常规实现。若需要改变原有能力/权限或真实数据范围，再提出具体边界。

## 原型处置

共享纯Dart状态/测试可复用但仍需生产审阅；薄桥、平台故障注入、osCommand/独立SMTC probe、p1_process_probe和临时文件store仅P1诊断。P2入口要决定保留/改造/关闭，不把原型直接视作正式运行时。文件store只在显式夹具配置下保留，不与正式库双写。所有未验维度保持限制；不新增全局门。

收尾补充：自然结束释放最后资源后停止Android本诊断前台服务，真实隔离用例先失败后通过，见android-natural-service-isolated-red.log、android-natural-service-green.log。凭据加新鲜度/PID/Android随机标识防陈旧数据；两进程证明已重新执行。实际新增源差异见[source-from-a01.patch](source-from-a01.patch)，[应用校验](patch-validation.log)确认从67文件A01基线应用后与94文件当前源码逐一哈希相同；旧证据保留。


最终普通APK：48,509,302字节，SHA256 dd724416c04ddade769d96f0610b21df12a8163ee10e9277fb4c0d87f9cb5eb1；签名核验通过并已安装指定手机。普通Windows文件夹17项（含5项自有夹具/说明资产），无额外codec DLL；完整哈希见[artifacts-final](artifacts-final.json)及[Windows目录清单](windows-bundle-final.json)。源文件94项冻结，补丁应用校验通过；GraphFlow定向74文件请求，26更新、45未变、3不支持扩展、0错误，见[索引回执](graphflow-index.json)。

