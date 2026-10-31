# 当前冻结 p1-a02-v2.2：焦点命令迟到围栏

2026-10-31，AUTH-P1-FOCUS-20261031；Codex兼A02维护与ConfigIntegrator串行整合。消费v2.1后独立审阅指出poll已出原生队列的旧focus pause仍可能覆盖新意图；新增可控迟到平台回包红例，实际退出1，再修复转绿。

公共接口/协议1/快照格式1/05权威字段不变。修改范围仅冻结中的NativeLocalBackend内部transportRevision：prepare/play/pause/stop同步推进；Android焦点请求捕获play的修订，焦点命令随原始请求携带修订；Dart接收回包时再次核验，不靠poll起点判定，避免误丢真正新请求的loss。普通系统媒体命令不受焦点围栏过滤。Windows薄桥忽略额外play参数，原控制路径保留。

原19文件加新native_focus_command_test.dart，共20文件摘要见[JSON](20261031-focus-freeze.json)。新增文件由本批A02维护者整合；旧v1/v2/v2.1与历史证据不改。check.ps1改为消费新摘要，双端后续检查重新消费v2.2。不是公共接口重大重设计，不升级消息或快照格式；完整G-L仍未通过。

验证及平台消费者结果见[本批报告](../focus-20261031/report.md)；哈希冻结不代表未运行场景通过。
