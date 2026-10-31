# 当前交接：A04焦点资源安全子批（2026-10-31）

最新AUTH-P1-FOCUS-20261031已完成限定实现和验证，实际代码/退出码/差异/原始事件/产物/验收均见[报告](evidence/focus-20261031/report.md)、[计划与取舍](evidence/focus-20261031/plan.md)、[独立限定审阅及修复](evidence/focus-20261031/review.md)。旧JJ-Music只读；开发根mobile，feat/flutter-a01-a02仍无HEAD/暂存/远端，全部既有未提交工作保留。没有提交、推送、合并、发布或改全局/旧产品。

当前公共冻结为[p1-a02-v2.2](evidence/A02/20261031-focus-freeze.md)，20文件、协议/快照1。Codex串行兼Android平台、A02维护、ConfigIntegrator和文档协调；共享NativeLocalBackend新增transportRevision围栏，Android焦点请求捕获并携带修订，Dart消费迟到poll再校验。旧listener和原生待发命令另有focusEpoch保护；pause/stop/最后release/启动失败统一归还焦点。维持焦点中断后明确恢复，不自动resume；原生无新增队列策略。无新增依赖、05字段/公共端口/锁未变，旧v2.1冻结不重写。check.ps1/CI消费当前新冻结。

真机仍35a63609/Xiaomi2211133C/Android13API33。v2.2原生7项（focus3/local3/lifecycle1）通过；专用release焦点探针5检查通过，proof含kReleaseMode=true、新令牌/PID、构建哈希。旧listener是故障注入，OS transient竞争是本应用不同请求的实际AudioManager事件，迟到poll是受控边界模拟，不混淆。Flutter test不支持--release的尝试退出64已留证，改为lib/p1_focus_probe.dart实际release运行，未称全套7项release。最终已重新构建安装普通lib/main.dart，启动Status ok/UNKNOWN、PID32351存在；没有把命令成功当普通UI可视验收。

Windows原生本地3项、共享39项、格式/分析/20哈希及双端普通release构建通过。Windows测试日志不再覆盖历史P1目录，当前原始样本在本批windows-final.log及独立临时文件。普通Windowsrelease只构建，未另作本批普通UI人工验收。普通程序路径/安装与简单操作见报告和clients/flutter/README；当前APK与Windows完整目录哈希看normal-artifacts.json/windows-bundle.json，不能用旧批次包哈希比较。Android仍内部debug签名。

本次独立审阅发现的已出队旧focus消息竞态已先红例后修复、同用例转绿及双端回归；不冒称全仓安全审阅。A03—A08整体仍review、G-L不通过；未验跨应用/电话/导航/蓝牙、实际OS拒绝、跨轨真实loss、持续缓冲/未知时长/不可seek、独立engine/服务死亡、Windows输出失效/物理键与人工听感。下一批最小任务建议A03/A05 TC57：仅自有可延迟/未知长度本地输入及两端原始事件，先核可终止读取/真实API，不提前搭网络Broker，不自动P2/正式UI。此前云端CI未运行和基础维护审阅未完成不由本批限定审阅替代。

以下为此前维护及P1历史交接，保留其原时点事实；当前状态以本节和status为准。

---
# 当前交接：初始框架维护（2026-10-31）

最新AUTH-BOOTSTRAP-20261031只做环境/A01/A02基础复核、完善AGENTS、格式/检查/CI及首次提交准备。已有工程与后续P1原型全部保留；本批未新增后续产品功能、未改旧Electron、未安装工具/改全局、未提交推送创建远端发布。

[本批完整证据](evidence/bootstrap-20261031/report.md)、[普通检查及提交清单](bootstrap-checks.md)。根AGENTS已改为当前mobile根和Flutter流程，任务归属/接口仍引用原文档。任务索引/流程中的旧“全部未授权”改为引用最新status，历史授权不抹除。

当前公共冻结为[p1-a02-v2.1](evidence/A02/20261031-bootstrap-freeze.md)，仅排版维护，协议/快照格式/接口行为未改。新tool/check.ps1在CI和本地核哈希、锁文件、格式、分析和共享测试；Release必须允许Flutter刷新测试后生成的插件注册，且检查lock未变。旧v1/v2、P1证据与原包MANIFEST不改；MANIFEST不是当前源码清单。

本批Quality/38测试/分析通过；Windows及Android普通release均编译通过；Windows原生A01启动检查1项通过。指定手机35a63609此前断开；本次用户重连后确认同一Xiaomi2211133C、Android13/API33且亮屏，原生A01测试1项（含入口、共享合同、真实隔离快照三个按钮）通过。等待测试进程完全退出后，普通lib/main.dart release重建/安装成功，启动Status ok且PID25570存在；收尾手机自动Dozing，UNKNOWN启动状态仅记命令结果。详见[手机补验](evidence/android-recheck-20261031/report.md)。历史P1结果见下方原交接，不能当本批重跑。

新增GitHub CI只有准备/解析结果，尚无远端执行；独立review agent因额度限制失败，未返回有效审阅意见。本地差异由主执行者复核，不能称独立审阅通过。BOOTSTRAP-CHECK保留review。官方Actions和Flutter固定SHA；CI将来在临时runner获取SDK/JDK，不改本机。当前doctor有CocoaPods站点TLS告警、本机GitHub直连TLS失败，未放宽证书；现有工具足够双端本地构建。

独立Git仍feat/flutter-a01-a02、无HEAD/暂存/远端。忽略规则已补android/build及CI/秘密材料；Git属性保持冻结字节。技术上可准备首次源码提交，公开前需确认可见性/许可及历史日志路径/设备编号脱敏；不自动执行。Android亮屏A01补验已完成；本批剩余独立审阅和将来云端CI执行证据，不继续后续阶段。

以下为此前P1交接的历史事实与未验边界，保留供后续明确授权时使用。

---

# 当前交接（2026-10-31）

开发根E:\Workspace\project\JJ-Music-mobile，旧JJ-Music只读参考；不用旧聊天。先读README/status、P1-A手册和归属/条件分支，再GraphFlow context实际mobile根。当前本地feat/flutter-a01-a02，无HEAD、无暂存/提交、无远程；旧端main/4f47d10cd4d8deb0118e35198105f11bee754246及既有未跟踪迁移文档/ZIP保留，旧产品未改。

AUTH-A03-A08授权已执行：A03—A07诊断原型和主路径已集成，A08缺口报告已交；任务保守留review，完整G-L暂不通过。没有自动进入P2/在线/下载/DLNA/正式UI/真实源，未提交推送发布。Codex串行兼ConfigIntegrator、A02共享维护和双端平台维护。用户已确认本机开发者模式开启；本批工具未改全局系统配置。Flutter3.47.9/Dart3.13.7、既有Android/JDK/VS工具沿用并经实际构建证明可用。

最新权威：[阶段报告](evidence/p1-a/20261031/report.md)、[简单验收](evidence/p1-a/20261031/acceptance.md)、[执行账本](evidence/p1-a/20261031/ledger.md)。当前共享冻结[p1-a02-v2](evidence/A02/20261031-freeze.md)，协议/快照格式仍1；v1不重写，历史哈希自然不再匹配当前扩展。新增恢复定位/fresh-authority restore/可信backendReleased及切歌确认前失败回滚，受影响共同测试和真实平台路径已复验。

Android设备由用户明确选定：35a63609，Xiaomi2211133C/fuxi，Android13/API33/arm64-v8a。只安装本诊断包和自有媒体，不扫描私人曲库/账号。Media3 1.11.0薄适配直接采原生state/isPlaying/suppression/currentPosition；平台前台服务/MediaSession只执行能力、回调同一共享入口。file/content URI、自然结束/坏文件/读取拒绝/快速停止/失败恢复旧轨通过；Activity实际重建保持engine/会话/handle；短时后台、原生确认关屏、系统pause/play、组件替换/CAS/原生资源销毁通过。手机会自动息屏，额外普通按钮烟测未完成；核心组件测试在用户解锁后已通过。以后UI测试先核原生交互屏幕，不能把关屏等待帧写成通过或绕过锁屏；仅UI测试窗口可KEEP_SCREEN_ON，不改用户全局设置。

Windows是系统WinRT薄桥，无mpv/FFmpeg/Rust资产，C++20。直接原生状态/位置推进与共享身份围栏形成项目确认；3项真实本地测试通过，文件释放后可rename。单窗口手动SMTC禁每轨自动决策；独立OS探针真实pause/play/seek/next及timeline通过。组件route replacement、排他权威旧owner拒绝、原生资源独立销毁通过，实际普通诊断按钮也通过。

两端均用同一端同一release专用探针：取得flush保存修订后外部强杀，第二进程读取同一隔离目录，PID/运行epoch改变，逻辑会话/修订/2345ms位置/确认记录一致，默认paused、零native资源。两端具体PID/修订及本次随机凭据以最新process-proof JSON为准。专用探针入口lib/p1_process_probe.dart，不是用户程序；最终已重建普通lib/main.dart。原型cache/code_cache可能被系统清理，不是生产DB/断电恢复或用户备份。

普通程序路径及安装见[客户端说明](../../clients/flutter/README.md)。Windows保留整个Release文件夹；Android最终app-release.apk为内部调试签名，已装到选定手机；app-debug.apk是测试入口。当前build目录已替换A01历史产物，准确哈希看本批artifacts-final/windows-bundle-final，不拿旧A01哈希验新包。

共享38项、analyze无问题；独立审阅发现的切歌确认前失败/取消和合法空快照问题均先红例后修复，复审确认解决；真实两端还验证失败后旧轨原生running并继续推进，避免陈旧样本。完整命令/失败/成功日志、两个独立平台事件映射、源差异/清单都在本批证据。

剩余本阶段工作：真实持续加载/缓冲暂停取消/恢复、未知时长/不可seek与旧回调序列；独立engine死亡但原生仍活/服务回收/完整焦点矩阵；Windows输出失效/物理媒体键与人工听感；Android额外按钮亮屏验收。不能把这些写成N/A或用另一端/L1/fake代替。已证明的存活权威CAS不等于无损接管已死Dart engine；缺权威按R3默认暂停。下一批仍先补P1缺口、重审G-L，不自动P2/正式视觉。




