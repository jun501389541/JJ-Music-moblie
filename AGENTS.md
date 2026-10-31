# JJ-Music Flutter project instructions

本仓库是独立 Flutter 客户端；旧 `JJ-Music` 仅只读参考。先核实际文件，
保留全部未提交工作，不凭历史聊天重建、覆盖或删除已有工程。

## 开工与任务领取

1. 从 [开发入口](docs/flutter-migration/README.md) 读取
   [status](docs/flutter-migration/status.md)、[handoff](docs/flutter-migration/handoff.md)、
   [任务索引](docs/flutter-migration/tasks/README.md) 和当前任务页。
2. 在广泛探索、实施、排错或审阅前使用已安装 GraphFlow 技能，先调用
   `graphflow_context`，按 summary/anchors/tokenBudget 定点读取；多步实施先
   `graphflow_plan` 并完成返回的桥接提交/合并，修改后定向 `graphflow_index`。
   rootDir 必须是当前 checkout 的绝对路径，本机为
   `E:/Workspace/project/JJ-Music-mobile`，不能传旧参考仓库或私人目录。
   工具不足时遵守 [执行流程](docs/flutter-migration/agent-workflow.md) 的降级边界。
3. 按当前用户授权、实际前置和现有证据领取一小批，在 status 登记任务、
   owner、文件范围、合同版本和证据目录。新授权不自动扩大到后续阶段。

## 归属与接口

- 依赖只维护于任务索引，文件归属只看
  [contracts-ownership](docs/flutter-migration/tasks/contracts-ownership.md)。
  共享接口、配置、锁文件、状态与交接必须由已登记维护者串行整合。
- 接口字段和行为引用 [05](docs/flutter-migration/05-architecture-contracts.md)、
  [07](docs/flutter-migration/07-background-downloads.md)、
  [08](docs/flutter-migration/08-data-migration.md)；本文件不重新定义接口。
  合同变化按归属流程更新版本及消费者，不静默重写历史冻结哈希。
- 已有后续原型保留；本批只做授权范围。正式 UI、真实源、个人数据、
  安装系统工具/全局配置、身份/签名和发布各自遵守实际授权边界。

## 验证、证据与交接

- 使用可信且相关的已安装技能；不批量安装。缺关键技能只从 OpenAI
  官方/curated 来源按 skill-installer 获取。普通操作流程必须同时留在仓库文档。
- 实际检查命令见 [基础检查](docs/flutter-migration/bootstrap-checks.md)，
  Flutter 工作目录为 `clients/flutter`；不要运行旧 Electron 专用命令。
- Android 与 Windows 分开记录编译、启动、设备和人工检查；单元、fake、
  构建、原型及真实设备结果不得互相替代，未执行不写通过。
- 每批保存命令/退出码、输入及夹具、实际差异、合同摘要、结果和限制至
  `docs/flutter-migration/evidence/`，再串行更新 status/handoff；done 必须
  满足 [执行流程](docs/flutter-migration/agent-workflow.md) 的实际验收与集成标准。
- 不自动 commit、push、创建远端或发布；不 reset/stash/清理他人工作，
  不扫描个人曲库或执行真实音源。首次提交范围先看基础检查中的提交清单。
