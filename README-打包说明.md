# JJ-Music Flutter 迁移文档包 R4

打包时间：2026-10-30T20:24:35+08:00
代码基线：main / 4f47d10cd4d8deb0118e35198105f11bee754246
本包包含当前 docs/flutter-migration/ 的全部 55 份 Markdown（含历史证据）及仓库现有 AGENTS.md 的原字节副本。未改写原文档，未包含产品源码、依赖、个人数据或音源文件。

先打开 [文档总入口](docs/flutter-migration/README.md) 或 [新手一页](docs/flutter-migration/beginner-guide.md)。
换 agent 时使用 [通用开工提示词](docs/flutter-migration/start-prompt.md)；进度以文档内 status/handoff 为准。

文档仍为待审核设计，不代表批准进入 PREP 或产品开发。原型和产品测试的状态保持原记录；打包完整性检查不能替代产品验收。

请完整解压并保留目录层级，便于内部相对链接工作。源码引用需在对应 JJ-Music 仓库基线上查看；本包不是可运行工程。若放回已有仓库，先核实际 Git 状态及适用规则，不直接覆盖同名文件；附带 AGENTS 只是打包时的规则快照，不能覆盖目标仓库的新规则。

MANIFEST.sha256 列出除清单自身以外每个文件的 SHA-256，路径相对本解压根。压缩包外的 .zip.sha256 用于核对整包；Windows 可用 Get-FileHash -Algorithm SHA256 <压缩包路径> 比对。
