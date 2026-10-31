# JJ-Music Flutter

独立 Flutter 客户端工作区：Android 为主线，Windows 做早期验证。
当前是技术诊断与自有样本原型，尚不是正式播放器；实际完成范围与缺口以
[status](docs/flutter-migration/status.md) 和 [handoff](docs/flutter-migration/handoff.md) 为准。
旧 Electron 仓库只读参考，不在此重建或替换。

- [开发文档入口](docs/flutter-migration/README.md)
- [工程与运行说明](clients/flutter/README.md)
- [基础检查、CI与首次提交清单](docs/flutter-migration/bootstrap-checks.md)
- [项目执行规则](AGENTS.md)

本机使用 Flutter 3.47.9 / Dart 3.13.7。准备好相应工具链后，在仓库根 PowerShell：

```powershell
./clients/flutter/tool/check.ps1 -Mode Quality
./clients/flutter/tool/check.ps1 -Mode AndroidRelease
./clients/flutter/tool/check.ps1 -Mode WindowsRelease
```

公共合同版本、任务前置和文件归属引用开发手册，不在本页重复定义。
CI配置已准备，实际云端运行结果尚未验证。构建产物、SDK、私有缓存和签名材料
不提交；MANIFEST.sha256及README-打包说明.md是原文档包的历史资料。
