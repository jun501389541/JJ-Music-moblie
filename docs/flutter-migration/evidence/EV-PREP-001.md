# EV-PREP-001：PREP-01环境核对与首批实施准备

日期2026-10-30（Asia/Shanghai）；执行/协调：Codex单agent。授权AUTH-PREP-01-20261030，允许解压/环境检查/计划、状态、ADR、交接文档；不安装、不创建Flutter工程、不改旧Electron、不提交推送发布。证据等级L0文档及本机工具元信息，不是产品TC或风险门通过。

## 输入、工作区和保留证据

- cwd/后续开发根 `E:\Workspace\project\JJ-Music-mobile`。开始只有原ZIP和`graphflow-out/`；后者保留未读私人对话。`git rev-parse --show-toplevel`退出128：`fatal: not a git repository (or any of the parent directories): .git`。因此新端分支/SHA/已跟踪修改均不存在，而不是main/干净。没有擅自初始化Git。
- ZIP=`JJ-Music-Flutter-Migration-R4-20261030.zip`，285764字节，SHA256=`ccba37ceb3e39bbded5b2b3f6f3fcad3c3219bc31ccf33ef59b884af7dc4a3bc`，与旧目录的ZIP摘要文件一致。ZIP条目检查无绝对路径/上级穿越；去掉单层包装目录后在新根逐文件提取，已有同名文件会报错，不覆盖。原ZIP保留。
- 解压后修改前对`MANIFEST.sha256`逐项`Get-FileHash -Algorithm SHA256`：57项全部匹配，包含55份Markdown、AGENTS与打包说明；清单本身不计。旧EV-DOC-001—005保持原字节。修改后该MANIFEST仍代表**原包**，不能作为当前工作区全量校验清单。
- 旧参考仓库只读：`git -C E:\Workspace\project\JJ-Music branch --show-current`=main；`rev-parse HEAD`=`4f47d10cd4d8deb0118e35198105f11bee754246`；log=`docs: record verified v0.7.1 release [skip ci]`；上述查询退出0。`status --short`为`?? docs/JJ-Music-Flutter-Migration-R4-20261030.zip`、`?? docs/JJ-Music-Flutter-Migration-R4-20261030.zip.sha256`、`?? docs/flutter-migration/`；`git diff --stat`空。没有pull/fetch/reset/stash/移动/覆盖，也未核远程新状态。
- 读取README→beginner/status/handoff/review/workflow→tasks索引/PREP-01/A01/A02/归属/条件分支/批次证据→05 C-01—06及ADR-0002/0003/0006、06后端。父层E:/Workspace/project及以上检查未发现额外AGENTS；docs下未发现嵌套AGENTS。根AGENTS是原包快照，含旧rootDir及Electron测试命令；本次用户明确实际项目root与旧端仅参考，按当前用户规则使用mobile root，未改AGENTS，也不运行旧测试。
- 消费05合同SHA256=`4ceb24ee1a16c8b1c37dc6deef431ee14679857613ebcb828bc3c5c0283dae17`；归属表=`f18eeeb32549be7611ade7a25b2503fdd70d26b8ba56fdb9345423e6a2aa3d61`；任务依赖索引=`e6e62c4c0cf0392df9a475d5f538f0a9189034020cd849f5086b42f8faf06082`。本次不改这些权威规则或声称实现合同冻结。

## 实际环境命令与结果

PowerShell，除下表专门列出外，不以聚合shell最后退出0代每项成功。`InitializeDefaultDrives`出现警告，但后续明确结果可取得。不存在命令仅用Get-Command探测，未运行会下载组件的Flutter初始化。

| 查询/操作 | 实际输出/退出或限制 | 结论 |
| --- | --- | --- |
| `Get-Command flutter,dart,git,java,javac,adb,emulator,sdkmanager,cl,cmake,ninja -ErrorAction SilentlyContinue` | Flutter/Dart未找到；Git=`C:\Program Files\Git\cmd\git.exe`；Java/Javac=`E:\Android\jdk21\bin`，adb/emulator/sdkmanager在现有Android SDK；cl/cmake/ninja未在PATH | Flutter命令不可用，不等于扫描全盘证明从未安装；常见E:/flutter、E:/dev/flutter、E:/SDKs/flutter、C:/src/flutter也未发现 |
| `git --version`、`java -version` | Git 2.55.0.windows.5；Microsoft OpenJDK 21.0.12.1 LTS /64位；退出0 | 已安装，不证明Gradle兼容 |
| `Get-ChildItem Env:`及用户环境变量元信息 | JAVA_HOME=`E:\Android\jdk21`；ANDROID_HOME/ANDROID_SDK_ROOT=`E:\Android\sdk`；ANDROID_AVD_HOME=`E:\Android\avd`、ANDROID_USER_HOME/EMULATOR_HOME=`E:\Android\.android`；用户注册表前三项一致 | 复用已有配置，不新增或打印其他环境秘密 |
| SDK各`source.properties`/目录 | platform-tools37.0.1，emulator37.2.9，cmdline-tools23.0；platform android-36(API36/revision2)、android-37.0；build-tools36.0.0/37.0.0；有licenses目录；未见ndk/cmake目录 | 基础文件具备，完整性/全部许可/NDK/Android CMake与实际构建未验证 |
| `E:\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat --list_installed` | 退出1：提示sdkmanager已弃用并转交Android CLI；随后`Error: Failed to create bin dir` / `拒绝访问。 (os error 5)` | 本想只读列清单，现有包装器却尝试创建bin；未重试安装/升级或提权，改读元信息。该拒绝可能来自当前沙箱，不能诊断为主机SDK损坏；未成功安装任何组件 |
| `E:\Android\sdk\platform-tools\adb.exe devices -l` | 退出0，仅`List of devices attached`，无设备行 | 当前ADB看不到手机/运行模拟器；不推断用户没有手机 |
| `E:\Android\sdk\emulator\emulator.exe -list-avds` | 退出0：`Pixel8_API36` | 有AVD配置，不等于在线设备 |
| AVD config/source.properties | x86_64、API36 Google APIs revision7；4核/4096MB/host GPU/数据分区10G；对应系统镜像目录存在 | 尚未启动，资源与图形加速可运行性未验 |
| `E:\Android\sdk\emulator\emulator.exe -accel-check` | 退出6：`Hyper-V detected and Windows Hypervisor Platform is available. Please ensure both the "Hyper-V" and "Windows Hypervisor Platform" features enabled in "Turn Windows features on or off".` | 检测到Hyper-V/WHP信息，但非0，不能写加速通过；普通用户终端及实际启动待复核，不擅改Windows功能 |
| `E:\Android\studio\product-info.json`及launcher存在性 | Android Studio AI-261.26222.65.2614.16204760，amd64，`E:\Android\studio\bin\studio64.exe`、jbr/java存在 | 已安装，未开GUI/改设置 |
| `vswhere.exe -products '*' -format json` | Community18.9.12120.119和BuildTools18.9.12120.119均complete，无待重启；Community未找到VC目录 | IDE已装不等于装了C++ |
| `vswhere.exe -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.VC.CMake.Project -property installationPath` | 退出0，返回`C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools` | BuildTools含VC及CMake组件 |
| BuildTools绝对路径`cl.exe` / `cmake.exe --version` / `ninja.exe --version` | 分别退出0；Compiler19.51.36256/MSVC目录14.51.36231；CMake4.3.1-msvc1；Ninja1.13.2；Windows Kits Lib=10.0.26100.0 | 工具能启动，但未编译链接/Flutter构建，Flutter对VS18支持由后续doctor确认 |
| Windows注册表/RuntimeInformation | X64、NT10.0.26200、DisplayVersion25H2/UBR9278；ProductName显示Windows10 Pro（该字段可能保留旧名，不能单凭它判断市场名称）；E盘约147GiB/C盘约80GiB可用 | 基本宿主存在，非完整Flutter Windows验收 |
| `Get-CimInstance Win32_OperatingSystem/Win32_Processor` | `无法从客户端中访问 CIM 资源。` | RAM/CPU固件虚拟化细节未取得，不捏造；explorer/显示设备查询亦无可用输出，当前沙箱不能证明交互桌面/GPU/音频能力 |
| AppModelUnlock注册表查询 | 未得到开发者模式值 | symlink/开发者模式未知；仅doctor要求时再检查，不默认改系统 |
| GraphFlow context | mobile root调用成功，summary/anchors为空，tokenBudget1500，compressedTokens0/raw20 | 服务可用但无相关索引；依workflow定点读文档，不依赖历史聊天 |
| GraphFlow plan/insight | plan无LLM key返回agent桥接；以本agent提交intent和四步串行DAG后merge complete=true/missing=[] | 未读取或配置密钥；桥接成功不等于产品实施完成 |

## 上游核对与缺项影响

2026-10-30读取[Flutter手工安装](https://docs.flutter.dev/install/manual)、[SDK archive](https://docs.flutter.dev/install/archive)、[Android设置](https://docs.flutter.dev/platform-integration/android/setup)、[Windows设置](https://docs.flutter.dev/platform-integration/windows/setup)。官方安装页示例为3.47.5；另尝试旧发布JSON端点得到NoSuchKey/404，故SDK真实发布hash/Dart组合没有核定，不编造固定版本。Windows需C++桌面工作负载；Android需SDK/设备/许可并列NDK、Android CMake。下载/安装/配置步骤已落实到[本机计划](../tasks/prep-01-local-plan.md)，未执行。

包上游页面：[just_audio](https://pub.dev/packages/just_audio)0.10.6、[audio_service](https://pub.dev/packages/audio_service)0.18.19、[audio_session](https://pub.dev/packages/audio_session)0.2.4、[media_kit](https://pub.dev/packages/media_kit)1.2.6；后者音频安装说明含media_kit_libs_audio1.0.7。API端点浏览失败后改用包发布页，未安装/执行包；这些版本只是本次候选快照，实际SDK约束/发布源码/原生资产许可与摘要/lock待A01或使用前审计。无Rust方向不变。

- 缺Flutter：A01工程/构建、A02测试都不能运行；Dart随Flutter补，不另装。
- 无在线Android设备：阻Android启动/安装验收及A03/A04/A07；现有AVD启动仍待验证。模拟器可先跑debug，真机release/后台/音频另验。
- sdkmanager包装器拒绝/NDK和Android CMake未发现：完整Android工具检查和构建有缺口，按本机计划普通终端/SDK Manager复核，不能声称SDK全部可用。
- VS工具存在、Windows图形/开发者模式/Flutter识别未验：A01 Windows完整验收和A05/A06仍待，不要求现在重装。
- 新端无Git：不能提供自身分支/HEAD/diff；保留解压包清单与后续内容差异作本次审查基线，独立Git在未来实施范围建立。

## 本批交付与验收边界

对应需求R-01/08/15/17/20/22/23/32/33/34；计划落实A01/A02 allowlist/候选/命令及TC-56 pending控制、TC-57双端映射清单、TC-05真实文件→新进程读回→缺损退路→P2替换；实际负责人/状态只在status。05/08合同未改；08 O/TC-58留后续阶段。

正常环境枚举有证据；异常缺Flutter/CLI拒绝/加速非0保留；未发生规划取消或多人并发，按条件分支审查、不伪造运行场景。Android/Windows产品构建、TC-01—58、真实源/私人曲库/后台/听感/图像与所有能力门均未运行。没有可执行分支产物；文档就在目标mobile工作区保存并做内容/链接/原包保护检查，不将文档集成说成产品集成。

实际文档差异、校验与GraphFlow索引结果见本记录末尾收尾补充。PREP-01可以完成规划交付，A01/A02仍不具备开工条件；不自动进入安装/编码。

## 收尾补充（本次实际校验）

- 原包57项重新按MANIFEST比较：49项字节未变，仅8项预期修改：README、status、handoff、tasks/phase-0、tasks/phase-1a、ADR-0002/0003/0006。新增2份Markdown：本证据和tasks/prep-01-local-plan。原ZIP、MANIFEST、AGENTS、EV-DOC-001—005、05/08合同、任务依赖索引与归属表均保留。handoff是当前快照更新，旧内容仍可从原ZIP恢复审查。
- 用PowerShell逐项Get-FileHash与清单比较、正则解析本批10份Markdown的非HTTP/非锚点相对链接并Test-Path：150个相对链接、0个失效；shell退出0。按PREP-01验收人工复核：A01/A02范围/前置/命令、TC-56/57/05三项计划、权限/缺项/未测/原型替换齐备；任务DAG/需求/业务字段原字节不变，因此未重跑旧仓库的历史文档检查器或产品套件。
- `Test-Path clients/flutter`=False；新根无.git；旧仓库收尾`git status --short`仍是原3项未跟踪文档/ZIP，`git diff --stat`仍为空。没有新增旧端产品差异。目标mobile工作区仅文档落地校验，无产品分支或产品集成结果。
- `graphflow_index(rootDir=E:\Workspace\project\JJ-Music-mobile)`成功：indexedFiles=59、indexedSymbols=656、indexedReferences=52；vectorBackfill refreshed=256、missing=538、stale=0（单次预算256/2000ms）。索引服务能用，向量回填未完成，不能声称全部向量就绪。不为凑齐数字反复全量重建。服务在新根生成`.graphflow-cache/`，原有`graphflow-out/`保留；后续独立Git建仓时应将私人图谱缓存排除，不默认提交。
- 本记录收尾补充后再做定点校验并增量索引；如向量数变化，只代表服务预算内回填，不改本次环境/产品结论。没有安装、修改全局配置或启动模拟器/手机实验，未请求额外权限。
