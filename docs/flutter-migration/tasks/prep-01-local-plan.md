# PREP-01：本机首批实施计划（2026-10-30）

消费R4手册；这是环境落地附录，不替代任务索引、05合同或文件归属表。实际授权/状态只看[status](../status.md)，本次证据见[EV-PREP-001](../evidence/EV-PREP-001.md)。本次不安装、不创建工程；以下命令均为**以后满足条件后执行**。

**同日环境安装补充**：上述“本次不安装”和下方缺项表是PREP-01交付时快照；用户随后明确授权下载安装配置，实际结果见[EV-ENV-001](../evidence/EV-ENV-001.md)。Flutter3.47.9/Dart3.13.7已安装到E:/SDKs/flutter，doctor全通过，模拟器已实际启动验证；用户Path/缓存/镜像/本地免代理及既有SDK/JDK已配置。后续不应重复安装或继续把Flutter/CLI视为缺失。A01/A02命令、allowlist与产品验收保持原义，仍无工程实施授权。

原生工具也已补齐：NDK28.2.13676358、Android CMake3.22.1正式安装于现有SDK独立版本目录；可执行版本及登记清单已核，安装后doctor再次全通过。验证用模拟器已关闭，未来运行时重新启动现有Pixel8_API36即可。下表“未发现NDK/CMake”仍只代表最初检查快照，不是当前缺项。

## 工作区与顺序

- 开发根固定为 `E:\Workspace\project\JJ-Music-mobile`；旧 `E:\Workspace\project\JJ-Music` 只读参考。新目录不是Git仓库，不能用旧仓库的main/SHA冒充新端基线，也不能运行 `git rev-parse` 来生成新端路径。
- 获得工程实施范围后，先在新根建立独立本地Git仓库（不自动添加远程、提交或推送），记录实际分支及未提交清单；尚无首提交时HEAD不存在是正常状态。不得复制旧`.git`或迁走旧代码。项目名由工程负责人采用诊断用 `jj_music_mobile`，不让新手决定内部命名；正式applicationId/签名留P3-05。
- PREP-01规划 → 补工具并复核 → A01双端诊断壳 → A02共享合同/文件快照 → 共享夹具冻结 → A03/A05真实后端映射 → A04/A06 → A07实际新进程恢复。唯一依赖仍以[索引](README.md)为准。
- A01/A02目前没有实施授权，Flutter缺失；不能ready。没有设备不阻止以后纯Dart测试，但当前A02仍依赖A01，不能擅自跳过双端前置或更改验收。

## 工具、ABI与候选依赖

| 项目 | 本批推荐与约束 | 锁定时点/缺口 |
| --- | --- | --- |
| Flutter/Dart | 官方Windows x64 stable压缩包，建议解压到 `E:\SDKs\flutter`；Dart随Flutter，不另装 | 官方手工安装示例当前为3.47.5，但示例不是安装事实；发布JSON查询404，未锁SDK版本/hash。安装前从官方archive确认实际stable版本/摘要，A01记Flutter提交和内置Dart版本 |
| Android | 复用 `E:\Android\sdk`、`E:\Android\jdk21`，现有API36/Build-tools36.0.0优先验证；不选预览API37作为必需前置 | JDK21与以后模板Gradle/AGP的兼容性由A01实际构建验证，不预设Java17或盲目换JDK。NDK/Android CMake目录未发现，按选定Flutter模板/插件要求固定版本后在原SDK补齐 |
| Windows | x64；现有VS18 BuildTools的MSVC、CMake、Ninja及Windows SDK10.0.26100.0 | Community未找到VC工具；先看Flutter doctor是否识别BuildTools，不因其不在PATH重装。需要补工作负载时修改现有VS安装 |
| Android ABI | 已有Pixel8_API36为x86_64模拟器；拟真机验证arm64-v8a | arm64真机尚未连接，不能声称已验。A01核实际产物ABI，A03不得用模拟器证明所有真机能力 |
| A01/A02最小依赖 | Flutter SDK、SDK内flutter_test；A02用dart:async/convert/io做有限文件实验；integration_test使用SDK版本 | 先不装播放器、DB、JS引擎、Riverpod或路由；初始诊断不需这些包，无Rust |
| A03/A04候选 | just_audio 0.10.6、audio_service 0.18.19、audio_session 0.2.4 | 2026-10-30上游页面快照，非批准或lock；A01/使用前核发布包pubspec约束/许可/源码/Gradle/原生依赖，A03/A04验证API及生命周期 |
| A05候选 | direct media_kit 1.2.6；其说明给出audio原生依赖media_kit_libs_audio 1.0.7 | 原生包未下载/摘要与mpv/FFmpeg许可未审，不因Dart包MIT放行DLL；A05前审原生产物来源/ABI/摘要/许可。WinRT备选不自动安装 |
| UI/DB | Riverpod/go_router仍提案；正式DB留P2 | 不为A02文件快照提前引DB，不扩正式页面；未做无必要的版本锁定 |

上游来源及限制见[证据](../evidence/EV-PREP-001.md)。后端候选只供后续审计，不能直接复制`^`版本当可复现依赖；使用时保留精确锁文件与实际原生资产清单。A01负责公共配置串行整合，A02只消费配置。

## A01：最小诊断工程

前置：PREP-01、实施范围、Flutter/Android/Windows工具链与运行资源复核；不要求视觉稿，诊断界面不能变正式UI。

allowlist：`clients/flutter/**`初始scaffold、`pubspec.yaml`/`pubspec.lock`、Android/Windows runner及诊断入口、`test/app_bootstrap_test.dart`，本目录依赖决定与`evidence/A01/<batchId>.md`。这些路径**全部尚不存在**。不得改旧Electron的package/源码/构建配置。

| cwd | 未来动作/命令 | 前置/实际验收 |
| --- | --- | --- |
| 新根 | `git init -b main` | 仅在工程实施范围授权后建立本地版本管理；不commit/add remote |
| 任意普通PowerShell | `flutter --version`、`dart --version`、`flutter doctor -v`、`flutter devices` | 先完成安装/联网下载范围；会初始化缓存或下载组件，本次未执行 |
| 新根 | `flutter create --platforms=android,windows --project-name jj_music_mobile clients/flutter` | 先确认目标不存在、SDK版本固定；会生成文件并解析依赖，留完整日志 |
| `clients/flutter` | `flutter analyze`、`flutter test test/app_bootstrap_test.dart`、`flutter test` | 先创建有实际断言的测试文件，再运行；不得以不存在入口或0用例通过 |
| 同上 | `flutter build apk --release`、`flutter build windows --release` | 两端分别留退出码/产物hash/ABI/许可。Android release构建不等于模拟器可安装该release，模拟器启动用debug；真机release运行另验 |
| 同上 | `flutter run -d windows`；`flutter run -d <实际Android设备ID>` | ID只从当时`flutter devices`取，不能把AVD名称当连接ID；分别启动/操作/退出并截图/记录实例，缺端不能A01双端done |

正常=两端启动退出；异常=缺SDK/ABI/资产识别失败；取消=初始化中断/退出；并发=重复启动、旧端并存但不碰旧数据。未实际覆盖的场景单列，不以构建代运行。Flutter对VS18/JDK21的实际识别仍未知，失败先保留日志并区分工具兼容与产品问题。

## A02：合同、非阻塞控制与文件快照

前置：A01完成及本批实施范围。合同输入为05 C-01—06（输入SHA见证据），字段不在本页复制维护。A02维护共享合同/测试/fixture；A03/A05不得各复制一套断言。

allowlist（相对未来`clients/flutter`）：`lib/domain/playback/**`、`lib/application/playback/**`、`test/playback/**`、`lib/data/prototype_recovery/file_snapshot_store.dart`、`integration_test/support/local_playback_contract.dart`、`fixtures/local_playback/**`，以及本目录合同冻结/`evidence/A02/<batchId>.md`。平台专属adapter和公共pubspec/lock不归A02修改，详见[归属表](contracts-ownership.md)。

1. **TC-56先立反例**：用一直pending的准备Future和可观察fake控制通道，分别派发Stop/Cancel/Pause/新Play；在旧Future结束前断言accepted/applied和有效通道控制派发。再完成旧Future，断言不能覆盖新状态；合法outgoing释放不能被误丢。事件序列作为证据，不只断言UI变化；不用真实网络或音源。
2. **TC-57公共反例**：重复确认/暂停恢复/缓冲恢复不重记历史；旧epoch/sequence、未知时长、失败/结束/中断分开；保留逐轨角色与释放凭据。fake仅证明共享合同，不证明平台API或声音。
3. **TC-05文件前置**：只C-03最小集合，字段以05为准；Windows测试显式传入系统临时目录下`jj-music-mobile-prep/<runId>/prototype-recovery`，Android诊断应用私有目录`prototype-recovery/<runId>`由后续平台适配提供。不可写Electron数据。原型建议上限16条fixture/256KiB，A02冻结实际值；不持久化URL/token/运行epoch/原生handle。自有fixture用合成短WAV和无个人内容队列，实施时生成后登记hash/许可；本次未生成。
4. 先写坏文件/未知版本/缺失/过大/旧修订/乱序慢写测试；真实文件临时副本发布后才报saved修订，慢写不阻Stop；验证中断退路与最后有效副本，不宣称断电安全。`test/playback/recovery_snapshot_store_test.dart`在创建后才能运行。
5. cwd未来`clients/flutter`：`flutter test test/playback`、`flutter test test/playback/recovery_snapshot_store_test.dart`、`flutter analyze`。只运行实际存在且有用例的入口；保存用例名、通过数、退出码、事件/文件修订证据。真实Android/Windows播放留A03/A05；A02不宣称跨进程恢复通过。
6. 冻结端口/公共断言/fixture文件清单与摘要，登记消费者；文件变更先暂停消费者并串行整合。假后端仅留测试，正式DB在P2-01实现同端口后关闭/移除生产文件原型，不双写。

## A03/A05映射与A07交接清单

- A03/A05各自交后端精确版本/发布源码链接/API、OS/ABI/设备/构建模式、原始事件顺序及错误。表逐项写：load/play Future完成含义、buffering与playing、首次确认/去重、pause/resume、seek、结束/中断、取消后迟到事件、release确认、epoch/handle关联、transition交接。每项注明能证明什么/不能证明什么；不可预填“某个playing布尔值即项目确认”。证据分别写本目录`evidence/p1-a/<runId>/android-event-mapping.md`和`windows-event-mapping.md`，与平台批次记录互链。
- A07消费A02实际saved修订及A04/A06证据：先取得文件保存完成回执，外部实验控制方记录旧PID/实例→终止诊断进程（不靠退出flush）→显式启动新进程→同一隔离目录实际读回→核修订/fixture/位置及默认暂停；另测缺失/损坏/中断写。不以热重载/同进程fake代强杀；Android用户强制停止不能自动复活。
- 08 O/TC-58锁序交错留P2/P5/P6实施前展开；不增加P1正式数据库或全局调度框架。

## 给新手的具体补齐步骤（本次仅说明，尚未执行）

1. 从[Flutter官方安装页](https://docs.flutter.dev/install/manual)进入[SDK archive](https://docs.flutter.dev/install/archive)，选Windows x64 stable；解压后确认 `E:\SDKs\flutter\bin\flutter.bat` 存在（避免多一层flutter目录）。Dart已包含。普通用户写权限足够时不需管理员；不要装进Program Files，也不要覆盖未知旧SDK。
2. 开始菜单搜索“编辑账户的环境变量”→用户变量Path→编辑→新建 `E:\SDKs\flutter\bin` →确定。只加一条、保留旧条目，不改系统Path；关闭再打开终端和Codex。用户Path一般不需管理员。本次已存在用户JAVA_HOME/ANDROID_HOME/ANDROID_SDK_ROOT，不必重设。
3. 安装后的初始化会写Flutter缓存并可能联网：在以后允许该范围后运行 `flutter --version`、`dart --version`、`flutter doctor -v`。保存完整结果，由技术负责人处理常规错误。先不创建项目。若Flutter自动发现错误JDK/SDK，再考虑 `flutter config --android-sdk E:\Android\sdk`、`flutter config --jdk-dir E:\Android\jdk21`；这是用户级Flutter配置更改，当前未执行，不必先盲配。
4. 打开现有 `E:\Android\studio\bin\studio64.exe` →欢迎页More Actions →SDK Manager；确认SDK Location=`E:\Android\sdk`。核API36、Build-Tools、Platform-Tools、Command-line Tools、Emulator；NDK(side by side)/Android CMake按选定Flutter模板要求的版本补，不装任意最新版。现有sdkmanager查询失败，先在普通用户终端复核，不通过管理员运行来掩盖不明写入。SDK Manager安装会联网/写SDK，属于下一步范围；默认不需管理员，若目录权限拒绝先检查权限。许可文件存在不等于全接受；后续由你阅读 `flutter doctor --android-licenses` 提示再同意。
5. 需要Windows运行时：开始菜单Visual Studio Installer →现有Community或BuildTools“修改”→“使用C++的桌面开发”，核MSVC x64/x86、Windows SDK、C++ CMake。**先看doctor再决定是否补装**，已有BuildTools组件无需重复安装。修改VS通常会请求管理员。只有doctor报symlink支持问题时再启用Windows“设置→系统→高级/开发者选项→开发人员模式”（设置名称随系统版本变化，可能需管理员）。本次开发者模式/桌面图形条件未验证，不默认要求更改。
6. 推荐先用已有模拟器：打开Android Studio →More Actions →Virtual Device Manager（工程中Tools →Device Manager）→找到 `Pixel8_API36` →点▶。能看到Android桌面后运行 `E:\Android\sdk\platform-tools\adb.exe devices -l`；应有一行状态`device`。本次未启动。若加速仍报错，先普通终端运行 `E:\Android\sdk\emulator\emulator.exe -accel-check`；非0再检查“启用或关闭Windows功能”中的Windows Hypervisor Platform及固件虚拟化，实际修改需管理员/可能重启，不盲目切换已有Hyper-V。
7. 真机可后补：手机设置→关于手机→多次点版本号开启开发者选项→打开USB调试→用可传数据的线连接→手机上确认本机RSA调试授权→ADB检查为`device`。不要开启Bootloader解锁或root。若无设备先换线/端口，Windows驱动只从手机厂商/Google官方取，驱动安装可能需管理员。模拟器不能代真机后台/焦点/蓝牙/听感验收。

下一次只需按已保存环境缺口复核和获准批次推进；内部类名/常规实现由工程负责人决定。安装、系统配置、模拟器/真机运行与工程创建不因保存这份计划获得授权。

## 2026-10-31实施收尾补记
A01/A02授权后，原计划中的clients/flutter路径已实际建立。双端构建/原生烟测和30项共享测试通过，设备与产物准确结果见../evidence/A01/20261030-batch.md及A02/20261030-batch.md；模拟器已关闭，无真机/真实播放或强杀恢复结果。保留以上PREP历史条件，不把旧缺项当当前阻塞。

20261031按新增AUTH-A03-A08实施薄Media3/WinRT及自有样本/恢复实验，候选选择、项目依赖和实际设备已在ADR-0003及evidence/p1-a/20261031/report.md落地；原PREP候选矩阵仅历史计划，不覆盖本批实际证据。

