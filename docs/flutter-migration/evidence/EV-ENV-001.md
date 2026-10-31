# EV-ENV-001：开发环境安装与配置

日期2026-10-30（Asia/Shanghai）；执行/协调Codex，单agent。用户在PREP-01交接后明确要求“你这边直接帮我下载安装配置吧”，记录AUTH-ENV-20261030。本证据追加实际安装结果，不覆盖[EV-PREP-001](EV-PREP-001.md)历史检查。允许环境安装/配置/验证，不创建Flutter工程、不改旧Electron、不提交推送发布。

## 固定输入、下载与安装

- 开发根仍为 `E:\Workspace\project\JJ-Music-mobile`，没有Git仓库/分支/HEAD；没有`clients/flutter`。旧参考仓库main/`4f47d10cd4d8deb0118e35198105f11bee754246`，收尾核未提交项仍为旧迁移目录/ZIP/摘要3项，不改产品。
- GraphFlow先context（rootDir为mobile，返回PREP附录等摘要，预算1500/compressed903），再plan；无key返回桥接，由本agent提交intent/四步串行DAG并merge成功。采用GraphFlow、systematic-debugging及verification-before-completion规则；无子agent，不依赖旧聊天或私人记忆。
- 官方安装资料：[手工安装](https://docs.flutter.dev/install/manual)、[SDK archive](https://docs.flutter.dev/install/archive)、[中国网络说明](https://docs.flutter.cn/community/china/)、[Android CLI](https://developer.android.com/tools/agents/android-cli)。旧清单地址中多出的`/flutter`导致404；从官网archive延迟加载脚本找到实际根`https://storage.googleapis.com/flutter_infra_release/releases`，不是官方服务整体不可用。
- 已获取[官方Windows发布清单](https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json)，稳定版Flutter **3.47.9**，Dart **3.13.7**，x64，Flutter revision `c197ca5199e9ee5661e865596c9c07294dfab51c`，engine `89c39edfdfae2949f6806e4a315c0c08522238b7`。保留所选记录[flutter-release.json](setup-20261030/flutter-release.json)，未把整份无关发布清单留在仓库。
- Google原站单连接约25KB/s，切到官方文档列出的CFUG镜像后约11MB/s。ZIP位于`E:\SDKs\downloads\flutter_windows_3.47.9-stable.zip`，1939451626字节；下载完成SHA256=`d8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e`，与Google官方清单完全一致后才解压。SDK安装到新目录`E:\SDKs\flutter`，未覆盖旧SDK。tar解压退出0；聚合命令最后尝试读取已不再提供的`flutter/version`文件返回1，因此改用真实CLI版本，不把聚合退出码当解压失败或版本证据。
- 既有SDK cmdline-tools23的sdkmanager已转交Android CLI；原启动器在沙箱拒绝创建bin，正常权限下首次下载又停滞。查现有官方启动器固定的下载地址，使用系统curl分段取得`https://dl.google.com/android/cli/latest/windows_x86_64/android-cli.exe`：89823384字节，SHA256=`e461a361540882a759031dd94ad4814b0ba109183cdfdf18013b639539a9af7b`，Authenticode **Valid**，签名者 **Google LLC**，校验签名后才运行。
- Android CLI安装于`E:\Android\.android\bin\android-cli.exe`，版本 **1.1.16717390**；首次运行自行解包官方内置安装。原SDK的`bin/android.exe --no-metrics --version`也能正常复用该安装，退出0；不需要修改旧启动脚本或安装额外agent技能。CLI全程使用`--no-metrics`。

## 配置变更与已解决问题

仅当前用户，不改系统Path、不改已有HTTP代理/JDK/Android环境变量。变更前相关用户变量保存在`E:\SDKs\downloads\user-environment-before-flutter.json`（保留在本机工具目录，不复制原Path到文档）。原Pub缓存保留，没有清空/移动私人目录。

| 项目 | 实际配置 |
| --- | --- |
| 用户Path | 只追加`E:\SDKs\flutter\bin`，不替换既有条目 |
| FLUTTER_STORAGE_BASE_URL | `https://storage.flutter-io.cn` |
| PUB_HOSTED_URL | `https://pub.flutter-io.cn` |
| PUB_CACHE | `E:\SDKs\pub-cache` |
| NO_PROXY | 保留已有项并补`localhost,127.0.0.1,::1`，不更改HTTP_PROXY值或打印代理地址 |
| Flutter config | `--android-sdk E:\Android\sdk --jdk-dir E:\Android\jdk21` |
| Flutter工具分析 | `flutter --disable-analytics`成功 |
| 临时目录 | 初始化进程TEMP/TMP设`E:\SDKs\tmp`；**未修改用户或系统TEMP/TMP** |

首次Flutter工具pub upgrade曾报缓存`Rename failed ... errno=17`跨盘重命名错误，已中断重试。改用E盘独立PUB_CACHE和本次进程同盘TEMP后重新初始化成功；不把失败抹去，也不删除原缓存。首次doctor只有NO_PROXY缺失提醒，补本地免代理后重新验证。已广播Windows用户环境变更；当前Codex/终端可能仍持旧进程环境，后续应重开。用户不必手动再设置上述变量。

## 实际命令与验证

cwd为mobile根。SDK、Android/JDK及用户配置在允许范围外的写入均通过已获自动审查批准的正常权限命令完成；没有自动审查拒绝或要求用户手工批准的未决项。原始日志见下表，命令退出码按实际子命令记录，不以shell最后退出0代替成功判断。

| 命令/操作 | 结果/证据 |
| --- | --- |
| `flutter --version --machine` | 退出0，版本/提交/安装根与所选发布记录一致；[版本日志](setup-20261030/flutter-version.log) |
| `dart --version` | 退出0：Dart SDK3.13.7 stable / windows_x64 |
| `flutter config --android-sdk ... --jdk-dir ...` | 退出0，doctor实际使用现有SDK和JDK21，不另装JDK |
| `flutter precache --android --windows` | 退出0；[缓存日志](setup-20261030/precache.log)，未创建工程 |
| 首次`flutter doctor -v` | 退出0，但报告1类NO_PROXY提醒，不能仅凭退出码说全通过；[初次日志](setup-20261030/doctor-initial.log) |
| 补配置后`flutter doctor -v` | 退出0，逐项√，**No issues found!**；[最终日志](setup-20261030/doctor-final.log) |
| `flutter devices --machine` | 退出0；Android emulator-5554/API36/x86_64、Windows x64、Chrome/Edge；日志带工具镜像提示，故保存[devices.log](setup-20261030/devices.log)而不伪称纯JSON |
| `android-cli --no-metrics --sdk=E:\Android\sdk sdk list` | 退出0；实际已有API36/37、Build-tools36/37、platform-tools37.0.1、emulator37.2.9、cmdline-tools23及API36镜像；[清单](setup-20261030/android-sdk-list.log)。仅列出可升级版本，不整体升级 |
| `emulator -accel-check`（正常权限） | 退出0：`WHPX(10.0.26200) is installed and usable.`；PREP中退出6来自受限条件，不改Hyper-V/WHP功能 |
| Windows正常权限CIM/doctor | Windows11专业版25H2/build26200；doctor识别VS18 BuildTools18.9.2、Windows SDK10.0.26100.0；无需补装VS或重启系统 |
| 现有Pixel8_API36启动 | 以`-no-window -no-audio -no-snapshot-save -read-only`启动，未创建新AVD，不改保存快照；日志显示约22941ms完成冷启动；ADB状态device，sys.boot_completed=1，ABI=x86_64；[模拟器日志](setup-20261030/emulator.stdout.log) |

doctor识别最高已安装SDK37，不等于项目采用预览SDK；已核本次Flutter的`FlutterExtension.kt`：compile/target SDK36、minSDK24、默认NDK28.2.13676358。项目最低系统/正式标识仍未实施或批准，不能把模板默认值直接当产品兼容承诺。Android许可已由doctor报告全部接受，本次没有代用户点击新的许可同意。

## Android原生工具补齐

官方已安装CLI确认可用NDK28.2.13676358及CMake3.22.1。现有官方repository2-3.xml的Windows下载元数据：NDK包`android-ndk-r28c-windows.zip`，748118221字节/SHA1=`086bba43ff2f5eb0e387b15c8278bb4e0d89ba1d`；CMake包`cmake-3.22.1-windows.zip`，16116742字节/SHA1=`292778f32a7d5183e1c49c7897b870653f2d2c1b`。均从`https://dl.google.com/android/repository/`取得，不选最新版NDK替代Flutter已核默认值。

官方安装器单连接ETA数小时，已保留[首次NDK安装日志](setup-20261030/ndk-install.log)并中断，采用[固定元数据断点下载脚本](setup-20261030/download-native-tools.ps1)验证HTTP Content-Range、段长度和合并后官方校验值，放入SDK自身下载缓存，再交官方CLI执行安装。没有手造package.xml或绕过安装器的许可/校验。

实际收尾：两个包均按上述官方SHA1校验通过。官方安装器成功安装`ndk/28.2.13676358`和`cmake/3.22.1`，分别退出0，位置为`E:\Android\sdk\ndk\28.2.13676358`和`E:\Android\sdk\cmake\3.22.1`。[NDK成功安装日志](setup-20261030/ndk-install-final.log)、[CMake成功安装日志](setup-20261030/android-cmake-install-final.log)、[最终SDK登记清单](setup-20261030/android-sdk-list-final.log)均可复核。

安装NDK完成时官方工具会清理其他未使用缓存，导致提前放入的CMake缓存被清理；CMake一度重新联网下载，已中断并保留[该次日志](setup-20261030/android-cmake-install.log)，再于安装前只放入对应已校验包后成功，无重复安装或手改元数据。交付脚本修为只负责下载/校验，注明每个包应在各自安装前单独放入缓存，避免重复此问题。

实际运行NDK clang退出0：[版本日志](setup-20261030/ndk-clang-version.log)，clang19.0.1；Android CMake退出0：[版本日志](setup-20261030/android-cmake-version.log)，3.22.1（官方包自带build标签含dirty，不代表项目修改）。以上只证明工具可执行，不替代本项目编译/链接。

## 未验证与交接边界

以上是开发工具/设备准备证据，不是A01构建/启动应用或任何产品TC/风险门通过。没有Flutter工程、pubspec/产品lock、播放器依赖、真实源/私人曲库、真机/蓝牙/后台/听感或强杀恢复证据；没有Git初始化/提交推送/发布。未启用开发者模式或更改Windows功能：目前doctor不要求；实际项目若需要symlink权限，由A01按具体错误处理。

PREP-01原证据与历史EV-DOC均保留；最新状态/授权只在status，本机计划按本记录补充现状。最终原生工具/模拟器收尾和文档校验另追加在本记录下方。

## 最后复核与交付

- NDK/CMake安装后再次`flutter doctor -v`退出0，结果仍为**No issues found!**，见[安装后最终日志](setup-20261030/doctor-after-native.log)；`android sdk list`明确登记两个新包，未整体升级其他工具。
- 模拟器实际boot_completed=1及Flutter识别已验证；收尾经`adb -s emulator-5554 emu avd name`确认是本次Pixel8_API36后，`emu kill`退出0，关闭无窗口验证实例释放资源。关闭瞬间ADB可能短暂保留旧行，最终状态另以[收尾设备日志](setup-20261030/devices-after-cleanup.log)核对。无真机接入或手机授权操作；以后需要运行时可再启动现有AVD，不必新建。
- 用户只需重开Codex/终端使用户变量在新进程生效；没有需要手工安装、管理员确认或重启系统的未决项。本次未启用Developer Mode，工程阶段如实际要求symlink权限再处理。
- 受保护的10项（AGENTS、05/08合同、任务依赖索引/归属表、EV-DOC-001—005）均按原包MANIFEST核字节未变。EV-PREP-001保持前次交付内容，未用本次结果覆盖历史失败。README/status/handoff/本机计划/phase-1a/ADR-0003更新为新授权与真实环境，新增本证据和环境日志/固定下载脚本；不修改产品源码。
- 文档相对链接校验及GraphFlow增量索引在保存后执行；索引成功不代表向量回填全部完成。SDK ZIP/分段缓存/用户环境备份留本机E盘工具目录，未放入产品树；本次没有Git初始化、提交、推送或发布。

最终实测补充：本批7份变更Markdown共142个相对链接，失效0；10项原包保护文件变更0；`clients/flutter`与`.git`均不存在；旧参考仓库仍是原3项未跟踪文档/ZIP，tracked diff为空；最终doctor日志包含No issues found。以上校验shell退出0。模拟器关闭后再次ADB查询退出0且设备列表为空，没有遗留本次emulator/qemu进程；这与先前已验证在线启动并不冲突。

GraphFlow增量索引成功：本次快照indexedFiles=8、indexedSymbols=82、indexedReferences=0；vectorBackfill报告missing=23/refreshed=23/stale=0，数字是该次调用快照，不宣称全量向量就绪。保存本收尾说明后再定点索引本证据，保持图与文档一致。
