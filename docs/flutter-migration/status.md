# 当前状态、授权与证据索引

更新日期2026-10-31；文档R4、PREP-01及A01/A02实际实施。**双端自有本地播放/系统基础/恢复原型主路径已验证；完整G-L暂不通过，不代表播放器完成。** 开发根为`E:\Workspace\project\JJ-Music-mobile`，旧`JJ-Music`只读参考。本文件是任务状态、实际owner、授权和门结果的唯一维护处。

## 授权记录

AUTH-P1-FOCUS-20261031：用户新增“继续实际开发下一批前置满足任务”授权。本批领取 A04 焦点资源安全子项及 A03/A05 受影响回归，不进入P2/正式UI/在线源。owner Codex 串行兼 Android/A02公共测试维护/ConfigIntegrator/文档协调；消费R4/v2.1开工，因独立审阅发现迟到回包竞态，由A02维护者整合v2.2（协议/快照仍1），旧冻结证据不改。允许范围：Android LocalHost及必要焦点薄适配、integration_test/android_audio_focus_test.dart、Windows入口日志路径的必要修复、相关证据/status/handoff/README。证据目录 [evidence/focus-20261031](evidence/focus-20261031/report.md)；本批目标完成，整体A04/G-L缺口保留。真机仍限定35a63609，已重连核身份与Awake。

| 记录 | 范围 | 边界 |
| --- | --- | --- |
| AUTH-DOC-20261030 | 用户明确要求全局审阅并保存本目录，保留既有内容 | 仅文档/校验；不改AGENTS/产品、不提交推送发布；交付后停止 |
| AUTH-DOC-R31-20261030 | 用户要求R3两项依赖/文件归属核查及跨agent工具前提澄清 | 仅相关文档/校验并保留旧证据；不改AGENTS/产品、不创建工程/安装/执行音源/提交推送发布；交付后停止；不是PREP授权 |
| AUTH-DOC-R32-20261030 | 用户要求六类横向事项覆盖核查与相关文档补充 | 仅文档/校验，保留历史；总体架构/风险门不变、不扩P1；不产品代码/安装/执行源/提交推送发布；交付后停止 |
| AUTH-DOC-R33-20261030 | 用户要求最后四项执行契约核查与相关文档/证据修订 | 架构/功能/路线及风险门不变；不产品代码/安装/音源/提交推送发布；不自动进入PREP，交付后停止 |
| AUTH-DOC-R4-20261030 | 用户要求全阶段任务手册/新手与跨agent流程/校验 | 仅本目录文档，保留既有工作/历史证据；不工程/依赖/源/产品/提交推送发布；交付后停，不自动PREP |
| AUTH-DIRECTION | ADR-0001中的既定方向 | 不等于架构/依赖/实施/真源/视觉/发布批准 |
| AUTH-PREP-01-20261030 | 用户本次明确授权解压、环境检查与首批实施准备，更新计划/状态/ADR/交接 | 仅mobile开发根；不安装、不创建Flutter工程、不改旧Electron、不提交推送发布；不自动执行后续设备/产品实验 |
| AUTH-ENV-20261030 | 用户随后明确要求“直接帮我下载安装配置” | 允许本机开发环境下载、安装、配置与验证；覆盖PREP-01原先不安装限制。不创建Flutter工程、不改旧Electron、不提交推送发布；保留已有Android/JDK/VS工具 |
| AUTH-A01-A02-20261030 | 用户明确授权A01/A02实际开发及范围内常规修复/验证、可靠项目依赖 | clients/flutter双端诊断工程与共享合同/快照/自有fixture；不改旧端、不正式UI/真实源/私人数据，不系统级安装或全局配置，不提交推送发布，不进入A03+ |
| AUTH-A03-A08-20261031 | 用户授权P1-A A03—A08中满足前置的实现、自有夹具验证及常规修复；选定唯一连接手机35a63609 | 不真实源/个人曲库/正式UI/在线下载DLNA/P2，不提交推送发布；各端实际证据，不降低G-L |
| AUTH-BOOTSTRAP-20261031 | 用户本条授权环境检查、A01/A02初始框架/公共合同复核、完善AGENTS、基本检查和CI/首次提交准备 | 只补初始基础设施，保留已有P1代码；旧仓库只读；不安装工具/改全局/变身份，不提交推送创建远端发布，不续做后续阶段 |

工具安装/配置已按AUTH-ENV授权，[EV-ENV-001](evidence/EV-ENV-001.md)保存实际版本/配置/日志。已获得并执行A01/A02诊断与合同授权；A03—A08已新增授权并执行本批限定实验；正式视觉、真实源/私人数据、P2及正式签名发行未授权。环境安装不等于整套R4架构或依赖批准；已授权工程细节由agent处理，不要求新手逐类命名。

AUTH-ENV本批执行者/协调者：Codex；环境准备已完成。Flutter3.47.9/Dart3.13.7、Android CLI1.1.16717390、NDK28.2.13676358、Android CMake3.22.1已安装配置，既有JDK/SDK/VS复用；安装后doctor全通过，现有模拟器完成实际启动验证后关闭。工具就绪不代表A01或任何产品门完成，仍需独立工程验收。

## 任务状态

依赖与详细说明只看tasks索引；状态含义只在workflow。owner=-表示未领取。文档历史done只证明对应文档验收；A01/A02已完成首批范围，当前共享冻结已更新p1-a02-v2.3（单轨定位能力/拒绝回执），当前21文件清单为evidence/A02/20261031-seek-freeze.json；后文旧版本均是历史记录，A03—A08为review（见20261031实际证据与缺口），其余保持proposed。分支证据不等于集成，done须实际必需验收与目标工作区集成证据；单agent同工作区也记录。

| 任务 | 状态 | owner | 分支/任务证据或阻塞 | 目标工作区集成结果 |
| --- | --- | --- | --- | --- |
| DOCSET-01 | done | 历史文档执行者 | [EV-DOC-001](evidence/EV-DOC-001.md) | 当轮文档校验；非产品 |
| DOCSET-02 | done | 历史文档执行者 | [EV-DOC-002](evidence/EV-DOC-002.md) | 当轮文档校验；非产品 |
| DOCSET-03 | done | 历史文档执行者 | [EV-DOC-003](evidence/EV-DOC-003.md) | 当轮文档校验；非产品 |
| DOCSET-04 | done | 历史文档执行者 | [EV-DOC-004](evidence/EV-DOC-004.md) | 当轮文档校验；非产品 |
| DOCSET-05 | done | 本轮手册文档执行者 | [EV-DOC-005](evidence/EV-DOC-005.md)，DOC-01—05文档验收证据，不代表开发批准 | 目标工作区文档检查通过；产品未运行 |
| PREP-01 | done | Codex（本批协调/检查/文档） | [EV-PREP-001](evidence/EV-PREP-001.md)、[本机计划](tasks/prep-01-local-plan.md)；仅检查/规划完成，环境缺项保留 | mobile文档落地及静态校验；非产品集成 |
| PREP-02 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| V01 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| V02 | needs-user | - | 无具体稿件确认 | 未运行 |
| A01 | done | Codex / ConfigIntegrator | [实际证据](evidence/A01/20261030-batch.md)：双端release构建与native烟测通过，Android release三按钮通过 | mobile目标工作区已集成；仅诊断工程，无提交 |
| A02 | done（本批最小增量） | Codex串行合同维护 | [v2.3冻结](evidence/A02/20261031-seek-freeze.md)、[本批证据](evidence/seek-capability-20261031/report.md)，42共同测试；双端消费验证 | 已集成mobile当前工作区；不等于完整G-L |
| A03 | review | Codex / 本批串行维护 | [20261031证据](evidence/A03/20261031-batch.md)：真机file/content URI、3项本地验证；[本批Android初始加载4反例](evidence/loading-20261031/report.md)已补，[本批Android再缓冲4项](evidence/rebuffer-20261031/report.md)已补；未知时长/完整后台等未齐 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A04 | review | Codex / 本批串行维护 | [20261031证据](evidence/A04/20261031-batch.md)：Activity重建、后台/实际关屏、系统控制通过；[本批焦点安全修复及release实测](evidence/focus-20261031/report.md)已补；独立engine/服务回收/完整焦点矩阵未齐 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A05 | review | Codex / 本批串行维护 | [20261031证据](evidence/A05/20261031-batch.md)：WinRT3项本地验证/释放与真实回滚；[本批Windows初始加载及关闭异常](evidence/windows-loading-20261031/report.md)已补，输出失效/播放后再缓冲等未齐 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A06 | review | Codex / 本批串行维护 | [20261031证据](evidence/A06/20261031-batch.md)：真实OS pause/play/seek/next与timeline通过；物理媒体键/可见系统面板尚未验 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A07 | review | Codex / 本批串行维护 | [20261031证据](evidence/A07/20261031-batch.md)：双端组件/CAS/原生资源销毁与两进程R3通过；死engine原生独存接管未证 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A08 | review | Codex / 本批串行维护 | [20261031证据](evidence/A08/20261031-batch.md)：G-L实际证据及缺口报告已交；缺口保留，不放行P2 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| PREP-03 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B01 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B02 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B03 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B04 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B05a | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B06 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B05b | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B07 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B08 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| B09 | proposed | - | 无对应范围授权或前置证据 | 未运行 |
| P2-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-07 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-08 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-09 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-10 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-11 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-12 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P2-13 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P3-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P4-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-07 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P5-08 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-07 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-08 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-09 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-10 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P6-11 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P7-07 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-03 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-04 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-05 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-06 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-07 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-08 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P8-09 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P9-00 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P9-01 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| P9-02 | proposed | - | 手册已填；缺相应授权/前置实际结果/版本冻结 | 未运行 |
| REL-01 | proposed | - | 无本次具体产物/渠道发行授权 | 未运行 |
| REL-02 | proposed | - | 无本次具体产物/渠道发行授权 | 未运行 |

## 共享角色的实际登记

职责和计划交接唯一看tasks/contracts-ownership。当前Codex串行兼ConfigIntegrator、A02合同/夹具维护、Android平台与文档协调；本批领取A04焦点子项及A03/A05回归，见AUTH-P1-FOCUS-20261031。当前冻结v2.2及消费者复验见本批证据；历史v1/v2/v2.1保持原字节。

## 风险门状态

| 门 | 结果 | 证据 |
| --- | --- | --- |
| G-L | not-run | 双端真实本地/系统基础/组件恢复/两进程强杀主路径通过；完整TC57、独立engine/服务回收、输出失效等缺证据，见A08报告 |
| G-V | awaiting-user | 无具体视觉产物/确认 |
| G-N | not-run | TC-46/13早期合同尚未执行；TC-33不反向前置 |
| G-B | not-run | 回环/协议/资源联调未运行 |
| G-S0 | not-run | 自有JS兼容/隔离未运行 |
| G-S1 | not-authorized | 未授权真实源验证 |
| G-D | not-run | 无独立后台下载/检查点实验证据 |

A02已运行TC03、06—09、31/32、56/57共享子项，TC05仅文件前置，均不等于整项产品TC通过；其余未运行。63个注册ID只是58产品TC+5文档检查。R4将23个WP展开为详细任务，WP只保留映射，不再维护状态。当前双端API主路径映射、存活权威CAS、隔离两进程强杀恢复及指定Android真机已有证据；完整反例/回收矩阵、正式DB/锁序/JS兼容/其他设备仍待对应任务，不能因有任务页标通过。

## 证据索引

| ID | 内容 |
| --- | --- |
| [EV-DOC-001](evidence/EV-DOC-001.md) | 历史R3系列当轮证据，原字节保留，不充当本轮运行 |
| [EV-DOC-002](evidence/EV-DOC-002.md) | 历史R3系列当轮证据，原字节保留，不充当本轮运行 |
| [EV-DOC-003](evidence/EV-DOC-003.md) | 历史R3系列当轮证据，原字节保留，不充当本轮运行 |
| [EV-DOC-004](evidence/EV-DOC-004.md) | 历史R3系列当轮证据，原字节保留，不充当本轮运行 |
| [EV-DOC-005](evidence/EV-DOC-005.md) | 本轮R4基线/手册字段/链接/依赖/追踪/范围/语义及索引；仅文档 |
| [EV-PREP-001](evidence/EV-PREP-001.md) | 本次解压完整性、双工作区、工具/设备/错误及首批计划/收尾校验；非产品通过 |
| [EV-ENV-001](evidence/EV-ENV-001.md) | 新授权后的Flutter/Dart、Android CLI安装/配置、doctor全通过及模拟器实际启动；不代表工程验收 |

领取和收尾由协调者单写，不允许多个agent同时改此表。不把本文件存在当作架构、阶段、视觉、私人实验或发行批准。


本批实际实施证据：[A01](evidence/A01/20261030-batch.md)、[A02](evidence/A02/20261030-batch.md)、[冻结合同](evidence/A02/20261030-freeze.md)。



当前共享冻结：[p1-a02-v2.2](evidence/A02/20261031-focus-freeze.md)，原v2保留历史。20261031实际实施/差异/产物与缺口：[阶段报告](evidence/p1-a/20261031/report.md)、[简单验收](evidence/p1-a/20261031/acceptance.md)。A01/A02旧证据是历史构建，当前build目录产物以本批artifacts-final为准。



## 当前初始框架维护批次
AUTH-BOOTSTRAP-20261031：Codex兼ConfigIntegrator/A02维护/文档协调；范围AGENTS、基础检查/CI、忽略/字节属性、必要格式修复及状态交接。未重建已有工程、未继续A03—A08功能。当前证据见[evidence/bootstrap-20261031/report.md](evidence/bootstrap-20261031/report.md)，普通检查流程见[bootstrap-checks](bootstrap-checks.md)。历史任务/风险门结果保持原范围。


BOOTSTRAP-CHECK状态：review（基础维护实现及本地验证完成；独立审阅未完成）；owner Codex。当前Quality/38测试/两端release/Windows原生启动通过；Android重连后原生A01测试1项（含三个按钮）通过，普通release重新构建/安装成功；详见[手机补验](evidence/android-recheck-20261031/report.md)。GitHub CI未运行；独立审阅因review agent额度限制无有效意见，未把这些写通过。未改变G-L及A03—A08的review结论。




本批allowlist扩展（独立审阅发现迟到poll竞态）：由同一Codex A02维护者串行修改lib/platform/local/native_local_backend.dart，新增test/platform/native_focus_command_test.dart，必要更新tool/check.ps1与当前冻结p1-a02-v2.2。只新增平台内部transportRevision围栏，不改公共端口/消息语义/协议/快照格式；两端消费者暂停至新摘要生成并复验。允许新增显式release焦点探针lib/p1_focus_probe.dart及当前批运行脚本，用于弥补Flutter test无--release；普通入口最终重建。

## 当前播放焦点子批收尾

AUTH-P1-FOCUS-20261031已完成限定目标：Android v2.2原生7项通过、专用release焦点5检查通过；Windows原生本地3项通过；冻结20文件/格式/analyze/39共享测试/两端普通release构建通过。Android已重装lib/main.dart普通包，启动命令与PID存在；未把UNKNOWN当普通UI人工验收。独立限定审阅发现1竞态，已用迟到平台回包红绿修复。实际命令、差异、签名限制、产物及未验项见[本批证据](evidence/focus-20261031/report.md)。未验跨应用/电话/蓝牙、OS拒绝、真实跨轨loss、持续缓冲/未知时长/不可seek、engine/服务死亡与Windows输出失效等继续保留；A03—A08整体review及G-L结果不变。下一批建议先补A03/A05 TC57真实受控本地加载，不进入P2/在线/正式UI。

## 当前Android持续加载子批
AUTH-P1-LOADING-20261031：用户按文档继续开发授权。领取A03/TC57 Android初始持续加载/暂停/停止/取消/新意图及A05回归；owner Codex串行兼Android/A02维护/ConfigIntegrator/文档协调。消费R4与p1-a02-v2.2、协议/快照1，20摘要已核匹配。允许LocalHost.kt、新OwnedReadGate.kt、integration_test/android_loading_test.dart及必要测试支持、相关证据/status/handoff。证据evidence/loading-20261031。仅自有12秒本地WAV、指定35a63609；不网络/P2/正式UI/旧端/全局/提交。共享冻结若实际回归需改，先按归属登记再新版本，不改历史。本批限定目标完成；Android加载4及受影响回归共11项、Windows既有原生3项、39共享/格式/分析/20冻结哈希/双端普通release构建通过。手机普通包重装及启动命令通过，未作本批普通UI可视/听感验收；[证据](evidence/loading-20261031/report.md)。Windows真实延迟输入、Android播放后再缓冲/未知时长等未验证，A03—A08整体review及G-L不放行。审阅无阻断问题，关闭异常诊断维度为Minor延期，不将close计数当OS句柄证明。

## 当前Windows持续加载子批
AUTH-P1-WINLOADING-20261031：用户继续执行授权。领取A05/TC57 Windows初始真实加载子项，owner Codex串行兼Windows/A02维护/ConfigIntegrator/文档协调。消费R4/v2.2、20文件、协议/快照1，摘要已核匹配。allowlist：windows/runner/local_playback.cpp、新owned_gate_stream.h、integration_test/windows_loading_test.dart及必要Windows专属验证支持，证据/windows-loading-20261031、status/handoff。自有冻结WAV经显式有界内存流，不网络/私人媒体/新codec/正式UI/P2；旧仓库只读，不全局配置/提交推送发布。共享修改须先登记归属/冻结。本批限定目标完成：Windows6加载/关闭场景+3本地+1SMTC+1组件恢复均通过；Android回归曾真实崩溃，服务登记修复后9项通过；39共享/格式/分析/20摘要/双端普通release构建通过。详见[本批证据](evidence/windows-loading-20261031/report.md)。多入口Windows连接失败、Android原始崩溃及lint失败日志均保留，不混为成功。完整G-L仍未通过。

本批allowlist补记：ConfigIntegrator维护根.gitignore，新增忽略运行GraphFlow生成的未跟踪.graphflow/；保留该目录内容，不读取私人对话、不删除/移动/暂存或改全局配置。

本批前置回归修复扩展：Android加载复跑出现真实ForegroundServiceDidNotStartInTimeException（PID7480），为已有启动/停止服务资格路径问题。Codex串行兼Android维护，允许LocalHost.kt/PlaybackService.kt及android_service_registration_test.dart，改为每次启动登记前台、未完成登记前延后stop；保存崩溃及修复证据。用户已再次解锁原手机；不绕锁屏/改全局，不称完整Doze矩阵通过。

本批最终程序：Windows普通release进程13080/窗口已启动，Android普通入口重装并COLD启动/PID13442；各有独立日志，不称人工按钮/听感通过。Native接口/共享冻结仍v2.2，旧证据不改。下一批优先Android主线及双端播放后再缓冲反例；不进入P2/正式UI/网络。

## 当前Android播放后再缓冲子批
AUTH-P1-REBUFFER-20261031：用户继续执行授权。领取A03/TC57 Android已确认播放后的真实再缓冲4场景，owner Codex串行兼Android/A02维护/ConfigIntegrator/文档协调。消费R4/v2.2、20摘要已核匹配、协议/快照1。allowlist LocalHost.kt、OwnedReadGate.kt、新integration_test/android_rebuffer_test.dart及证据/rebuffer-20261031、status/handoff。只自有冻结12秒WAV；诊断专用前缀门控与小缓冲参数，不改普通路径/共享合同/全局/旧仓库/正式UI，不网络/P2/提交。Windows既有加载/本地回归，播放后再缓冲不代验；无Windows生产源码变化，不重建/打断可能运行的普通Release，只记录其上一批产物。本批限定目标完成：[证据](evidence/rebuffer-20261031/report.md)。Android前台再缓冲4项及initial/service回归5项通过，Windows既有gate6/local3回归通过；39共享/格式/分析/20冻结及05/锁核验通过，普通Androidrelease重建安装启动通过。息屏后两项首播遭ForegroundServiceStartNotAllowedException的失败保留，前台首帧前检查失败也保留；最终严格前台条件下复验通过，不冒充后台起播资格。共享冻结仍v2.2，A03—A08整体review/G-L未通过。

## 当前Windows播放后再缓冲子批
AUTH-P1-WINREBUFFER-20261031：用户继续执行授权，领取A05/TC57 Windows真实播放后再缓冲。owner Codex串行兼Windows/A02维护/ConfigIntegrator/文档协调；消费R4/v2.2、20摘要已核匹配、协议/快照1。allowlist：local_playback.cpp、新owned_pcm_source.h、必要owned_gate_stream.h内部观测、新integration_test/windows_rebuffer_test.dart及证据/windows-rebuffer-20261031、status/handoff。仅现有自有冻结PCM WAV，通过官方MediaStreamSource延后sample，不换MediaPlayer、不改普通file/原initial门控/共享规则，不网络/新codec/P2/正式UI/全局/旧仓库/提交。本批进行中；Android生产源码不改，结果保持各端独立。

限定目标完成：[报告](evidence/windows-rebuffer-20261031/report.md)。Windows真实播放后再缓冲4项、原gate6/local3/SMTC1/runtime1合计15项通过；共享39/格式41文件0变化/analyze/20冻结及05/锁一致。普通WindowsRelease构建和实际窗口启动通过，PID46856；按钮/听感未人工验。Android本批未改/未构建/未真机测试，保留前批依据。新增诊断PCM供样不改变公共合同或生产路径；独立限定审阅无Critical/Important。A03—A08整体review/G-L仍未放行，下一小批Android后台资格/生命周期，15秒超时/压力/外设听感等缺口照实保留。GraphFlow定向索引结果见本批index.log。

普通Windows启动观测补记：2秒PID46856之后续跨调用已不在，原因未定；独立复核同一调用内8秒PID47532/窗口600200仍存活。仅记录启动窗口，不保证当前仍运行或听感通过。见startup-followup.json。

## 当前Android服务销毁安全子批
AUTH-P1-SERVICELOSS-20261031：用户验收正常并继续开发；领取A04服务销毁安全退路/已有服务后台控制。owner Codex串行Android/A02只读消费/ConfigIntegrator/文档协调。v2.2/20摘要、协议快照1。allowlist LocalHost.kt、PlaybackService.kt、新integration_test/android_service_loss_test.dart、evidence/service-loss-20261031及status/handoff。设备35a63609/2211133C/API33已在线核对。以真实stopService触发onDestroy，不冒充系统杀服务/进程；先复现后最小修复，不改共享合同/依赖/UI/全局/旧仓库/网络/P2，不提交。Windows本批不改。进行中。
用户本轮反馈上一批简单验收正常，作为用户报告记录；未单独确认的听感、后台或完整G-L不扩大通过。

AUTH-P1-SERVICELOSS-20261031限定目标完成：[报告](evidence/service-loss-20261031/report.md)。先后真机复现并修复服务销毁仍播放、满队列丢安全pause、旧销毁误消费新登记；具体Service expectedStop及单独安全pause槽沿用原fence。最终Android13/13（新4/登记1/焦点3/Activity1/再缓冲4）、共享39、格式42文件/analyze/20冻结+05/锁通过；普通Androidrelease构建安装COLD启动ok/PID2870。Windows不改/本批未重建或运行，保留前批结果；共享v2.2不变。审阅两项Important均红绿修复，完整G-L仍未通过。下一批A03未知时长/不可定位自有输入，后台首次起播/长Doze/engine与系统杀服务/外设听感仍待验。GraphFlow结果见本批index.log。

## 首次提交与推送授权

AUTH-GIT-FIRST-20261031：用户明确“先提交并推送吧”，新增授权当前独立Flutter工作区的首次本地提交及推送；替代历史“本次不提交”的本次操作限制，不扩大开发/发行/全局配置或新建远端授权。owner Codex串行ConfigIntegrator/文档协调。提交范围为既有源码/配置/依赖锁/自有夹具、迁移文档和必要证据；现有署名jun/已配置邮箱沿用，不修改身份配置。排除构建/SDK/Gradle与Dart缓存/私有GraphFlow/ZIP/密钥/本地环境以及两份下载probe.bin（原文件保留）。常见私钥及令牌格式扫描未命中，不保证识别全部秘密；原证据含已登记设备编号、本机路径等诊断元数据，远端可见性待目标地址核实。当前无远端，已请求准确URL，不猜测、不新建、不强推。基础验证引用刚完成service-loss-20261031的39共享/格式/分析/冻结及两端分批证据，不把Git操作当功能或CI通过。

实际结果：用户指定现有jun501389541/JJ-Music-moblie（按原拼写）；首次提交b4e01705fac7208702bb967164757fcce5a1e91f已普通推送origin/feat/flutter-a01-a02，远端SHA及HEAD独立读回一致，上游已设置。详见[首次Git证据](evidence/git-first-20261031.md)。本记录作为后续文档提交一起推送，最终SHA看Git；无强推/合并/发行，未修改旧仓库。历史“无HEAD/远端”“不提交”为各批当时状态，当前以本节为准；云端CI尚未验收。

## 当前Windows未知时长/不可定位子批
AUTH-P1-UNKNOWN-20261031：用户继续开发；owner Codex串行Windows/ConfigIntegrator/文档协调，消费R4/v2.2的20冻结摘要、协议快照1。基线86053e5干净。领取A05真实MediaStreamSource未知时长/不可定位诊断输入。allowlist owned_gate_stream.h/owned_pcm_source.h/local_playback.cpp、新integration_test/windows_unknown_duration_test.dart及evidence/unknown-duration-20261031、status/handoff。仅已有PCM固定WAV载荷，不改普通路径/共享冻结/依赖/UI/全局/旧仓库，不P2/网络。本次开发不自动再次提交推送；上一条首次提交授权已完成。Android已有WAV明确长度，不能当未知时长输入；本批该端保留缺口。进行中。

本批验证范围补记：Windows SMTC外部探针首步返回error:true而无错误码；allowlist增加windows/runner/smtc_probe.cpp仅记录受控stage/HRESULT，不输出其他应用媒体信息、不启动/修改系统服务。用于分辨环境阻塞/回归，不降验收。

AUTH-P1-UNKNOWN-20261031限定目标完成：[报告](evidence/unknown-duration-20261031/report.md)。Windows未知0/对照12000、实际不可定位、native拒绝seek/暂停恢复/未知自然EOS/资源归零2项通过；旧rebuffer4/gate6/local3/SMTC1合计16不同用例通过；共享39/格式43文件/analyze/20冻结+05/锁通过。SMTC候选属性0x80070015先失败后补有限发现扫描，命令不重试；保留错误及候选对照日志。原Release因旧诊断进程占用失败，核路径后正常关闭旧两窗口，最终release-final构建及8秒启动观测PID49240通过。Android本批不改不验，共享v2.2不变，仍未实现共享seek能力协商/ack拒绝；G-L保持未过。基线86053e5，本批不自动提交推送。下一批A03 Android自有未知时长/不可定位输入；GraphFlow定向结果见本批index.log。

## 当前Android未知时长/不可定位子批
AUTH-P1-ANDROIDUNKNOWN-20261031：用户继续执行，领取A03。owner Codex串行Android/ConfigIntegrator/文档协调，消费v2.2/20冻结/协议快照1。保留Windows上一批全部未提交工作；allowlist LocalHost.kt、新OwnedPcmStream.kt、integration_test/android_unknown_duration_test.dart及evidence/android-unknown-20261031、status/handoff。仅冻结自有WAV载荷的无长度顺序PCM输入、专用Media3 framing extractor和原生能力观测/拒绝seek，不改普通路径、共享合同、夹具、依赖、全局、正式UI、旧仓库，不P2/网络/提交推送。设备35a63609身份已核。进行中。

本批限定目标完成：[报告](evidence/android-unknown-20261031/report.md)。Android未知natural/等待中stop/knownWAV共3与旧local3/service-loss4/rebuffer4合计14通过；共享39/格式44文件/analyze/20冻结+05/锁通过，普通Release构建安装COLD启动ok/PID14824。首次Quality花括号lint修正后最终quality-final通过，原失败保留；14项真机在纯样式修正前、不重复运行。Windows本批不改不验；全部前批未提交差异保留。共享v2.2仍不变，仅native seek能力guard，不等于共享能力协商/明确拒绝ack。EOF前真实TIME_UNSET，EOF后11910推导时长；关闭计数和短提交各按边界说明，G-L未过。下一批先界定A02/TC57定位能力与拒绝回执的最小合同增量/冻结及双端验证。GraphFlow见index.log。

AUTH-P1-SEEK-20261031：领取A02/TC57共享定位能力增量。owner Codex串行A02维护/双端消费者/ConfigIntegrator/文档协调；allowlist contracts.dart、playback_coordinator.dart、native_local_backend.dart、diagnostic_checks.dart、controlled_backend.dart、两端unknown测试、新共享seek测试、05增量、新v2.3冻结、check.ps1及本批证据/status/handoff。保留旧v2.2及所有前批差异。无UI/全局/提交推送，进行中。


AUTH-P1-SEEK-20261031限定目标完成：当前v2.3/21文件冻结及05摘要，旧v2.2保留。42共同/格式/analyze/锁/新冻结通过；Windows2+local3、Android3共8项通过。两端普通Release构建成功并恢复入口，实际进程见本批normal-artifacts.json。能力unknown/false无副作用拒绝，动态变化不保证，G-L未过；无提交推送，既有差异保留。见evidence/seek-capability-20261031/report.md。

2026-11-01发布收尾已完成：用户明确只发源码预发布；b502240已提交推送，PR #1合并main为f05a23b，两轮双端云端CI成功，tag v0.1.0-dev.1=f05a23b，公开prerelease且手动附件0，不含APK/Windows包。候选包本地忽略保存，未改正式身份/签名/默认分支/全局。详见[evidence/source-release-20261101.md](evidence/source-release-20261101.md)。此文档记录随后推送main，不移动标签；本地当前main。历史未提交状态被本次Git授权替代，功能范围/G-L缺口不变。

AUTH-GIT-MERGE-RELEASE-20261031：用户授权提交推送合并发布。合并到从86053e5建立的main，普通PR/merge不强推，保留分支。发布候选0.1.0-dev.1仅技术诊断，G-L未通过/Android调试签名/P1身份；当前候选包和摘要留graphflow-out/release-candidate，不自动对外发布未经确认身份的二进制。历史CI因SDK浅克隆识别0.0.0-unknown失败，补SDK checkout fetch-depth0；本地质量42/21冻结/分析格式本轮复验通过。
