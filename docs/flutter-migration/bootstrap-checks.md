# 初始框架检查与首次提交准备

当前独立根为 `JJ-Music-mobile`，Flutter 工程在 `clients/flutter`。
已有 A01/A02 及后续历史原型，先读 status/handoff，不重新 create 或覆盖。
本次基础维护授权不继续实现后续阶段。字段、任务依赖和文件角色仍分别引用
05、tasks/README、tasks/contracts-ownership，本页只定义可复现检查流程。

## 本机检查

前置：Flutter 3.47.9 / Dart 3.13.7、Git；Android 构建还需现有 JDK21/SDK，
Windows 构建需 Visual Studio C++/Windows SDK。缺失时记录影响，不能替另一端通过；
不自动安装工具或改全局配置。在仓库根 PowerShell 执行：

```powershell
./clients/flutter/tool/check.ps1 -Mode Quality
./clients/flutter/tool/check.ps1 -Mode AndroidRelease
./clients/flutter/tool/check.ps1 -Mode WindowsRelease
```

也可 `-Mode All` 串行执行；默认日志在忽略目录 `graphflow-out/checks`。
需要保存本批证据时显式传 `-EvidenceDirectory <绝对证据目录>`。
Quality 依次执行锁文件严格解析、公共合同哈希、只读格式检查、静态分析和共享测试；
任何退出码失败即停止，不自动改源码/哈希或降测试。只需格式修复时，在
`clients/flutter` 执行 `dart format lib test integration_test tool`，审查差异后重验。
若变更了冻结文件，须按 A02 归属流程产生新摘要，旧冻结保留历史。

Release 构建允许 Flutter 刷新生成的插件注册信息，构建前后检查 pubspec.lock
不变。不要在 integration_test 后强行 `--no-pub` 构建 Release：当前 SDK 下
可能留下 integration_test 的旧原生注册，真实失败及修复证据已保存。

原生启动/设备验收独立运行，cwd 为 `clients/flutter`：

```powershell
flutter test integration_test/diagnostic_smoke_test.dart --device-id windows --reporter expanded
flutter devices
# 仅对已选定、已授权且解锁亮屏的实际Android设备，替换设备编号
./tool/flutter_with_proxy.ps1 -FlutterArgs @('test','integration_test/diagnostic_smoke_test.dart','--device-id','DEVICE_ID','--reporter','expanded')
```

截图写本次进程的临时文件，不覆盖历史证据。Android测试/安装同一包必须串行，
确认前一工具进程退出后再启动下一项；真机不可用时只记录构建，不把启动命令、
进程存在、模拟器或共享测试当成真机交互通过。运行测试包后需交付普通程序时，
用 AndroidRelease/WindowsRelease 重建 `lib/main.dart`，不能交付探针入口。

## 基本CI

[flutter-foundation.yml](../../.github/workflows/flutter-foundation.yml) 在 Ubuntu 和
Windows 两个独立 job 上执行基础检查，再分别编译 Android debug、Windows release。
CI不运行手机/音频/系统控制实验、不上传产物、不签正式包、不发布。
它只获取官方 Flutter 仓库固定提交及官方 checkout/setup-java 固定 SHA；JDK21
在 GitHub 临时 runner 中获取，不修改本机。Pub主机与既有锁文件保持一致。
首次上云前没有远端执行结果，YAML解析或本机通过不得记作 GitHub CI 通过。

当前环境依据：[本批证据](evidence/bootstrap-20261031/report.md)。doctor 的 iOS
CocoaPods网站握手检查不用于判断 Android/Windows 工程结果，其他网络失败单列。

## 首次提交清单（本批不执行提交）

建议审查范围：README.md、AGENTS.md、.gitignore、.gitattributes、.github/workflows、
clients/flutter 源码/配置/锁文件/自有夹具、docs/flutter-migration 文档与必要证据。
原始 MANIFEST.sha256 是历史 ZIP 清单，不是当前工程完整性清单；保留其语义。

1. 用 `git status --short` 和 `git ls-files --others --exclude-standard` 核文件。
2. 保留 pubspec.lock、Gradle wrapper properties；Flutter会生成其已忽略的 wrapper
   脚本/JAR和插件注册。不要纳入 build/.dart_tool/.gradle-user-home、SDK、原ZIP、
   local.properties、key.properties、密钥、.env、私有GraphFlow/技能/对话缓存。
3. `.gitattributes` 保留准确字节，避免 Windows/Git EOL 转换破坏历史冻结哈希；
   Dart 排版仍由 formatter 统一，不改全局 Git 配置。
4. 审查日志公开范围：测试设备编号、本机用户名/绝对路径虽非密钥，公开仓库前
   仍需决定是否脱敏。检查不输出可疑秘密正文，只报文件名和类别。
5. 确认仓库可见性、仓库名/归属及许可证等对外决定后，才按用户明确授权提交/
   创建远端/推送；当前不代选身份、正式包标识、签名或许可证。

首次源码提交可在基础检查通过、范围审查完成后准备；不等于 G-L、正式产品、
发行或所有平台真机验收完成。下一批按最新授权与索引选择一个最小任务，保留
已有 review/未验项，不能因本次基础设施补齐自动进入后续阶段。

