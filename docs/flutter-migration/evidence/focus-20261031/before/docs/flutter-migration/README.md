# JJ-Music Flutter 迁移开发文档

版本：R4（通用全阶段任务手册版）；修订日期：2026-10-30。**本目录是待审核设计，不是已批准架构或已完成的 Flutter 产品。**

适用于单个 coding agent 连续开发，也适用于有人协调的多 agent 协作。Codex、Claude Code、Cursor 或其他工具均可使用；不需要读取历史聊天或私人记忆。

## 从这里开始

1. 读取仓库及目标路径适用的 AGENTS.md；本文不覆盖它们。
2. 读取 [状态与授权](status.md)、[交接](handoff.md)、[全局审阅](review.md)。最新授权以status为准；当前仅做初始框架/A01/A02基础维护。已有P1原型保留、G-L缺口不变，不重建工程、不续做后续阶段。
3. 读取 [执行流程](agent-workflow.md)，确认当前工具、平台、设备与允许修改范围。
4. 从 [任务索引](tasks/README.md)选择一个**已获授权、前置满足、已展开**的任务。没有符合条件的任务则报告阻塞，不自行开始产品开发。
5. 完成验证后更新证据、状态、受影响决定与交接。未运行不能记作通过。

快速入口：[新手一页](beginner-guide.md) → [任务地图](task-map.md) → [任务索引](tasks/README.md)；换agent用[通用开工提示词](start-prompt.md)。

R4基于实际R3.3展开全阶段任务手册，架构/功能/路线与7门不变。[完整性审阅](review.md)、[变更摘要](CHANGELOG.md)、[R4历史证据](evidence/EV-DOC-005.md)。2026-10-30已执行PREP-01检查/规划：[本机计划](tasks/prep-01-local-plan.md)、[历史检查证据](evidence/EV-PREP-001.md)；之后按新增授权安装配置环境，见[EV-ENV-001](evidence/EV-ENV-001.md)。2026-10-31完成[A01诊断工程](evidence/A01/20261030-batch.md)和[A02合同](evidence/A02/20261030-batch.md)；不是播放器完成；后续A03—A08本批双端自有播放/系统基础/恢复主路径与缺口见[20261031阶段报告](evidence/p1-a/20261031/report.md)，完整G-L暂不通过。

当前基础检查/CI与首次提交准备见[bootstrap-checks](bootstrap-checks.md)，本批新增授权及实际复核见[证据](evidence/bootstrap-20261031/report.md)。

## 文档地图与权威来源

| 文件 | 唯一维护的内容 |
| --- | --- |
| [01-current-repository.md](01-current-repository.md) | 不可变审计快照、当前实现、代码证据、五条真实流程 |
| [02-reference-research.md](02-reference-research.md) | 固定提交的参考研究、许可、采用与不采用依据 |
| [03-product-rules.md](03-product-rules.md) | 产品规则与范围；语义变更先改这里 |
| [04-playback-interaction.md](04-playback-interaction.md) | 页面、组件、列表、歌词、状态、输入与动效规格 |
| [04-visual-review.md](04-visual-review.md) | 视觉交付及用户确认的流程与标准 |
| [05-architecture-contracts.md](05-architecture-contracts.md) | 状态所有权、消息合同、恢复、音轨资源；字段以此为准 |
| [06-audio-backends.md](06-audio-backends.md) | 播放与系统组件候选、能力差距、失败出口 |
| [07-media-broker.md](07-media-broker.md) | 本机媒体服务、网络与流生命周期 |
| [07-source-runtime.md](07-source-runtime.md) | JS 兼容、宿主、隔离、真实源实验 |
| [07-background-downloads.md](07-background-downloads.md) | 下载调度、所有权、持久化、取消和恢复 |
| [08-data-migration.md](08-data-migration.md) | schema 设计、迁移、备份与回退 |
| [09-roadmap.md](09-roadmap.md) | 阶段和风险门定义；任务依赖以任务索引为准 |
| [10-testing-release.md](10-testing-release.md) | 测试 ID、证据等级、命令、性能及发布验收 |
| [11-risks-experiments.md](11-risks-experiments.md) | 未知项、实验、失败出口与待确认事项 |
| [12-requirements-traceability.md](12-requirements-traceability.md) | 需求 ID 与文档、任务、测试映射 |
| [decisions/README.md](decisions/README.md) | ADR 索引；每项状态及批准记录在对应 ADR |
| [tasks/README.md](tasks/README.md) | 全任务唯一前置/适用门索引；分阶段页实际填写步骤 |
| [task-map.md](task-map.md)、[beginner-guide.md](beginner-guide.md) | 导航视图与新手使用，不另维护依赖/状态 |
| [tasks/contracts-ownership.md](tasks/contracts-ownership.md) | 合同定位/文件维护角色/并行与集成，字段仍在原规范 |
| [tasks/conditional-branches.md](tasks/conditional-branches.md) | 实验问题/分支/确定者/原型处置与用户决定选项 |
| [tasks/batch-record.md](tasks/batch-record.md) | 每批实际证据的填报字段，非完成记录 |
| [status.md](status.md) | 可变任务状态、负责人、授权边界、门结果与证据索引 |
| [handoff.md](handoff.md) | 一次交接的 Git/工作区快照、未完成项和下一步 |
| [evidence/README.md](evidence/README.md) | 不可变证据记录要求；已发生的验证记录 |
| [CHANGELOG.md](CHANGELOG.md) | 文档版本差异；不重复维护任务/批准状态 |

禁止在多个文件维护另一份任务完成表、接口定义或批准状态。阶段图是解释图；依赖冲突先修任务索引及图，不由执行者任意选一份。

## 证据与决定分类

- **U／已确定方向**：用户明确指定，见 ADR-0001；不代表授权开工。
- **F／代码事实**：固定提交中实际装配、调用或实现；不等于运行通过。
- **D／官方描述**：上游文档、包说明或发布记录；注明来源和快照。
- **O／交互观察**：实际看到的运行或图像，写明条件；不能推断未观察手势。
- **P／设计提案**：本目录推荐，尚待对应批准或阶段决定。
- **H／待验证假设**：必须有实验、负责人任务及失败出口。
- **E／实际证据**：已经执行的命令或实验、输入、结果和限制。

原型门通过只降低风险，不自动把生产能力、视觉稿、真实设备或发行验收标为通过。实际状态只看 status.md 与链接证据。

## 固定方向与非目标

Flutter/Dart 单仓库、无 Rust；Android 首发、Windows 早期验证并逐步替换 Electron；共享业务、模型、主要 UI 与设计体系，平台能力适配。保留现有数据与产品含义。不增加账号、云端或跨设备同步，不把参考项目全部功能列入首版。不承诺 iOS/macOS/Linux 已兼容。

## 路径和命令约定

文档链接全部相对本目录。代码链接使用仓库相对路径。当前开发根为`E:\Workspace\project\JJ-Music-mobile`，尚无Git仓库，不能用`git rev-parse --show-toplevel`获取该根。旧`E:\Workspace\project\JJ-Music`仅参考；原源码链接指旧仓库，不表示mobile已有源码。Flutter路径为新根下`clients/flutter`，目前未创建。下方Git变量示例只适用于以后初始化Git后；不要把别人的绝对路径复制到配置。

PowerShell 可用 `$repoRoot = git rev-parse --show-toplevel`；POSIX shell 可用 `repo_root=$(git rev-parse --show-toplevel)`。这只是变量示例，不改变系统或用户目录。

## 本轮范围

最新范围为PREP-01及用户随后明确授权的环境下载安装配置，允许相关用户级Flutter/缓存/Path设置；保留已有工作与历史证据，不改AGENTS/旧产品，不创建Flutter工程，不执行音源/私人资料，不提交推送发布。具体已安装与未验项见EV-ENV-001，不能沿用历史“不可安装”作为本次阻塞。



