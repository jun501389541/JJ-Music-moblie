# 初始框架维护：实际复核与交付

日期2026-10-31。AUTH-BOOTSTRAP-20261031只授权环境/A01/A02基础复核、AGENTS、检查/CI及首次提交准备。已存在Flutter工程及P1代码，本批保留，不重新create、不继续后续功能。旧JJ-Music只读；没有工具安装、全局配置更改、身份标识更改、提交/推送/创建远端/发布。

## 起点与实际修改

- 独立目录已有.git，分支feat/flutter-a01-a02，无HEAD/暂存/远端，复用而不重复init。旧参考main/4f47d10cd4d8deb0118e35198105f11bee754246，原3项未跟踪迁移资料保留，产品tracked diff为空。
- 修改AGENTS：纠正GraphFlow实际root与旧Electron专用命令，链接现有手册的任务领取/归属/验证/证据/交接；不复制接口定义。
- 新增根README.md、.github/workflows/flutter-foundation.yml、tool/check.ps1、.gitattributes和bootstrap-checks普通流程；补.gitignore敏感/CI目录及android/.gitignore/build，实际发现的Gradle problems-report不再进入候选提交。
- Flutter工程、pubspec/lock及公共接口已存在。先校验原p1-a02-v2的19文件，再修2处Dart排版；原生烟测截图改写进程唯一临时路径，避免覆盖历史图片。无新增产品行为/接口字段。当前维护冻结p1-a02-v2.1仅格式变化，旧v1/v2和历史证据保留。
- 状态和任务流程中的“全部未授权/仅文档”旧表述按新增授权修正，现有A03—A08 review/G-L缺口仍保留，不扩大本批。

## 当前环境与缺项

| 能力 | 实际核对 | 影响 |
| --- | --- | --- |
| Flutter/Dart | 3.47.9 / 3.13.7，实际SDK HEAD c197ca5199e9ee5661e865596c9c07294dfab51c | 基础检查/双端构建可运行 |
| Git | 2.55.0.windows.5，已有独立未提交仓库 | 无需重新初始化或设置远端 |
| JDK/Android SDK | Microsoft OpenJDK21.0.12.1，E:/Android/jdk21；SDK E:/Android/sdk，doctor报告SDK37已装，工程仍compile/target36 | 已装工具复用；不据SDK最高版本改工程 |
| Windows工具 | Win11 25H2/build26200.9278；VS BuildTools2026 18.9.2、Windows SDK10.0.26100 | 当前x64编译/原生启动通过 |
| GraphFlow | context/桥接plan可用，结束定向index | 不索引SDK/缓存或私人目录 |
| 网络 | doctor的cocoapods.org TLS检查失败；GitHub API/Git本机直连握手失败；GitHub连接工具只读取得官方引用 | 不宣称doctor全绿；CocoaPods属于未做的iOS，不阻止本批双端构建；远端CI/冷缓存下载仍待实际GitHub运行 |
| Android设备 | 既有选定35a63609/Xiaomi2211133C，Android13/API33，初查Dozing，收尾已断开 | 早期安装/启动命令成功；最终重装device not found，亮屏可视交互未验 |

不需要用户现在安装额外工具或再次接受Android许可。具体环境日志见doctor.log、flutter-framework-commit.txt、devices.log；不修改代理/证书/全局Git配置绕过TLS错误。

## 验证结果

| 检查 | 本批结果与准确边界 |
| --- | --- |
| 本地入口Quality | pub get --enforce-lockfile、19公共文件及05权威哈希、33个Dart文件格式、analyze无问题、38测试通过；最终串行入口日志见final-checks/，早期结果保留quality/ |
| Windows compile | 普通lib/main.dart release通过，见final-checks/windows-build.log |
| Windows startup | 原生A01烟测1项通过，3个最小诊断操作/真实文件store读写，见windows-startup.log/png；新截图未覆盖旧A01图片 |
| Android compile | 普通lib/main.dart release通过，见final-checks/android-build.log；锁文件不变 |
| Android install/start | 早期install Success、am start -W Statusok、PID5672；UNKNOWN/Dozing不算界面通过。最终All包重装失败：device35a63609 not found，见android-install.log和devices-final.log；不能把旧启动命令当最终包已验 |
| 真机/后续功能 | 历史P1实测证据保留，不当作本批重跑；本批不执行本地播放/后台/音源/曲库等后续验收 |
| CI | YAML用现有Flutter工具链yaml解析器解析，双job/只读权限/固定官方Action SHA检查通过；无远端，未触发GitHub工作流，不宣称云端绿灯 |
| Git字节/忽略 | 19冻结文件Git filters/no-filters的blob hash相同；候选路径扫描无build/cache/key/DB/ZIP，常见秘密模式命中0（有限扫描，不是完整安全审计） |

实际复现的常规修复：最初测试后AndroidRelease --no-pub触发GeneratedPluginRegistrant引用integration_test类但Release依赖不含该类。保留失败日志android-stale-registrant-failed，Release检查改为允许Flutter刷新生成注册，并校验构建前后锁文件不变；同入口重跑通过。没有手工改生成Java或吞掉编译错误。格式检查也曾正确拦下排版差异，已修复复验。

## 技能盘点与普通流程

只使用已安装、当前相关的GraphFlow、executing-plans、verification-before-completion、systematic-debugging和requesting-code-review；TDD适用于行为修复，本批无新产品行为，检查用实际失败复现/命令校验。不安装/批量更新技能，不使用网页/图片/文档排版等无关技能。GraphFlow为项目既定本地工具，其余来自已安装curated superpowers包；无新增来源信任决定。

关键流程已落普通文件AGENTS和bootstrap-checks，不依赖某agent私有技能/聊天。CI只用GitHub官方actions/checkout v7、setup-java v6的固定完整SHA及Flutter官方仓库固定提交；引用查询通过已连接GitHub只读工具验证，见actions-pins.json。资料：[Flutter CI](https://docs.flutter.dev/deployment/cd)、[checkout](https://github.com/actions/checkout)、[setup-java](https://github.com/actions/setup-java)。runner中的SDK/JDK获取是未来CI环境准备，不是本机系统安装。

## 首次GitHub提交判断

技术上可准备首次源码提交：工程/锁文件、基础规则、检查入口/CI、可审查证据和忽略规则已具备。本批无HEAD，不存在“已经提交”或“GitHub CI已过”。不能直接把它当播放器/发布候选。

公开前仍需确认仓库归属/名称/可见性/许可证；历史诊断含本机路径、用户名及测试设备编号，公开时需决定脱敏范围。当前常见密钥模式扫描0并不替代完整人工复核。建议按bootstrap-checks列出的范围审查，不盲目git add全部；.gitignore排除私有GraphFlow、缓存、APK/EXE及签名材料。

下一批最小任务：在选定手机解锁亮屏时单独补A01原生启动/按钮烟测，确认工具进程退出再还原普通包；或在用户后续实际推送授权后验证GitHub双job冷缓存执行。现有P1完整G-L仍未通过，不在本授权中继续补后续功能，不自动P2。

CI取官方固定Actions的标签SHA已通过GitHub连接工具只读确认；核对Flutter官方commit endpoint时连接工具发生Transport send error。本机实际SDK完整HEAD已核，云端SDK checkout/runner能力仍归未执行项，不把连接失败当作成功。


独立审阅按requesting-code-review发起，但agent返回usage-limit错误，未完成独立复核；主执行者已逐文件复核AGENTS/CI/脚本及实际检查结果。此项不记通过，记录见[review](review.md)，BOOTSTRAP-CHECK留review。实现与本地验证已完成，Android亮屏界面、云端CI和独立审阅仍未完成。


可审查源码/配置差异：[source-config.patch](source-config.patch)，[应用/哈希校验](patch-validation.log)。补丁中生成HTML报告的删除仅表示从源码候选快照排除，磁盘文件未删。文档实际修改摘要见[change-manifest](change-manifest.json)，精确命令与范围见[commands](commands.md)。


设备末态：此前同一选定手机成功安装/启动的工具观测保留在命令及启动日志中；最后一次重装时ADB返回device35a63609 not found。最终安装/亮屏验收未完成，不重选设备、不记通过。

