# 当前状态、授权与证据索引

2026-11-07 全局审阅：用户授权“没问题提交并推送”；Codex 串行审阅，生产代码只读，证据 [global-review-20261107/report.md](evidence/global-review-20261107/report.md)。本轮 Quality 82/格式/analyze/28 冻结+05/锁通过；切歌撤销后不恢复旧轨（GR-01/P1）、切歌暂停继续选旧轨并悬挂新轨（GR-02/P2）仍复现。条件未满足，未暂存/提交/推送；保留全部既有改动。仅新增本报告/日志/探针并串行更新状态交接；G-L 不变，后续先修两项再复审。

AUTH-P1-PROCESS-20261101：用户手机验收正常后继续开发，领取A07当前v2.3全进程恢复子项。owner Codex串行A07/ConfigIntegrator/证据维护；allowlist lib/p1_process_probe.dart、tool/run_android_recovery_probe.ps1、tool/run_windows_recovery_probe.ps1（均相对clients/flutter）、evidence/process-recovery-20261101、status/handoff。前置A02真实文件和21冻结、两端本地播放已有实际证据；新运行独立核对。旧claim仅测试sidecar不进持久合同；新runId防旧产物误判，证据目录参数化防覆盖历史。保存完成后真实强杀重启，读回默认暂停、旧控制器拒绝、显式恢复再停止。手机35a63609已核2211133C/fuxi/Awake；Windows单独执行。保留全部未提交工作，普通产物先备份；不改共享冻结/正式UI/全局/旧库/P2，不提交推送发布。进行中。

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

依赖与详细说明只看tasks索引；状态含义只在workflow。owner=-表示未领取。文档历史done只证明对应文档验收；A01/A02已完成首批范围，当前共享冻结已更新p1-a02-v2.9（关闭接管即时错误观察），当前32文件清单为evidence/A02/20261107-close-observe-freeze.json；后文旧版本均是历史记录，A03—A08为review（见20261031实际证据与缺口），其余保持proposed。分支证据不等于集成，done须实际必需验收与目标工作区集成证据；单agent同工作区也记录。

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
| A02 | done（本批最小增量） | Codex串行合同维护 | [v2.6冻结](evidence/A02/20261106-close-failure-freeze.md)、[本批证据](evidence/close-failure-20261106/report.md)，82共同测试（含关闭收尾修复）；Windows/Android合作式接管各1项通过；此前v2.3定位证据保留历史 | 已集成mobile当前工作区；不等于完整G-L |
| A03 | review | Codex / 本批串行维护 | [20261031证据](evidence/A03/20261031-batch.md)：真机file/content URI、3项本地验证；[本批Android初始加载4反例](evidence/loading-20261031/report.md)已补，[本批Android再缓冲4项](evidence/rebuffer-20261031/report.md)已补；未知时长/完整后台等未齐 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A04 | review | Codex / 本批串行维护 | [20261031证据](evidence/A04/20261031-batch.md)：Activity重建、后台/实际关屏、系统控制通过；[本批焦点安全修复及release实测](evidence/focus-20261031/report.md)已补；独立engine/服务回收/完整焦点矩阵未齐 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A05 | review | Codex / 本批串行维护 | [20261031证据](evidence/A05/20261031-batch.md)：WinRT3项本地验证/释放与真实回滚；[本批Windows初始加载及关闭异常](evidence/windows-loading-20261031/report.md)已补，输出失效/播放后再缓冲等未齐 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A06 | review | Codex / 本批串行维护 | [20261031证据](evidence/A06/20261031-batch.md)：真实OS pause/play/seek/next与timeline通过；物理媒体键/可见系统面板尚未验 | mobile目标已集成主路径，完整任务验收未宣称；无提交 |
| A07 | review | Codex / 本批串行维护 | [20261031证据](evidence/A07/20261031-batch.md)；[20261101当前v2.3双进程复验](evidence/process-recovery-20261101/report.md)：双端真实保存/强杀/完整运行快照读回默认暂停、旧claim拒绝、显式恢复去重及原生释放通过；死engine独存接管/新进程损坏退路等未齐 | mobile目标已集成限定主路径，完整任务验收未宣称；无提交 |
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

AUTH-P1-SEEKBOUND-20261101：用户按文档继续，领取A02/TC57补充并发/桥接验证，Codex串行A02/文档维护。基线4b5d4b8干净，分支codex/seek-boundaries；allowlist新test/playback/seek_concurrency_test.dart、test/platform/native_seek_capability_test.dart及evidence/seek-boundaries-20261101、status/handoff。消费v2.3/21冻结，新增验证非公共接口/夹具冻结增量，不重写历史哈希。无生产逻辑变化时不制造红色失败，不改UI/原生/全局/旧仓库，不提交推送发布。进行中。

限定目标完成：[报告](evidence/seek-boundaries-20261101/report.md)。新增6并发+3mock桥接，最终共同51项/格式47文件0变更/analyze/21冻结+05/锁通过；生产源码/依赖/合同/夹具无变化。独立审阅的释放时序覆盖漏洞已补交接前0后1断言；首次lint失败保留，完整复验通过。不称生产缺陷/平台运行，Android/Windows均未重新构建或运行、原产物不变。codex/seek-boundaries未提交推送发布，下一批真实门控自然超时/恢复，G-L未过。GraphFlow见本批index.log。


AUTH-P1-TIMEOUT-20261101：用户继续开发，A03/A05真实读取超时及恢复验证。owner Codex串行双端/文档维护；allowlist新integration_test/read_timeout_recovery_test.dart及evidence/read-timeout-20261101、status/handoff；若实际原生失败需修，先登记扩展。保留前批未提交测试，v2.3/21冻结不变。设备35a63609用户已连接，先核身份；不模拟超时、不UI/全局/新依赖/旧仓库/提交推送发布。进行中。

限定目标完成：[报告](evidence/read-timeout-20261101/report.md)。Windows/Android真实超时恢复各1通过，初次均通过、无生产修复；共同51/格式48文件0变更/analyze/21冻结+05/锁通过。首轮清理if风格lint失败保留，纯语句块修正后quality-final过。两端普通Release未重建；Android原已验APK哈希核对后重装冷启动ok/PID22482，Windows普通窗口未动。具体输入/通用error归因与350ms短窗/关闭计数边界见报告；G-L未过。全部前批未提交工作保留，不推送发布，下一批重复加载停止/容量压力，GraphFlow见本批index.log。

AUTH-P1-CAPACITY-20261101：用户继续开发，A03/A05容量与重复加载停止验证。owner Codex串行双端/文档维护；allowlist新integration_test/resource_capacity_test.dart及evidence/resource-capacity-20261101、status/handoff。当前codex/seek-boundaries未提交工作全部保留，v2.3/21冻结不变；真实native2槽拒绝3/释放重入、12轮pending停止与8历史边界，再真实普通样本。非长期压力/OS堆泄漏证明；如实际原生缺陷需修先登记。手机35a63609已核在线，不改UI/全局/旧库/依赖，不提交推送发布。进行中。

限定目标完成：[报告](evidence/resource-capacity-20261101/report.md)。Windows2/Android2最终通过，双槽拒绝/释放重入及12轮加载停止真实读数归零、history<=8、晚allow新快照仍闭合、普通样本可确认；共同51/格式49文件0变化/analyze/21冻结+05/锁通过。首轮多余import失败保留，修正并加强断言后重跑两端通过；无生产修改，非长期内存/句柄泄漏证明。两端普通Release未重建，Android原已验APK恢复COLD启动ok/PID25080，Windows窗口不动。前批未提交工作均保留，不提交推送发布，下一批A04重建与媒体控制并发，G-L未过。GraphFlow见本批index.log。

AUTH-REVIEW-CLEANUP-20261101：用户要求先落实reviewer修复。领取capacity setup失败清理弱项，已修late-allow快照/提前释放断言保留。Codex串行测试/文档维护，allowlist integration_test/resource_capacity_test.dart、新support/diagnostic_cleanup.dart、新test/diagnostic_cleanup_test.dart、evidence/reviewer-cleanup-20261101及status/handoff。仅测试生命周期，v2.3/21冻结不变，保留先前未提交修改；无生产/native/UI/全局/提交推送。进行中。

修复完成：[报告](evidence/reviewer-cleanup-20261101/report.md)。setup整体进入test-only清理scope，逆序await/抛错继续/原异常优先，7故障单测及两端各3实际场景通过；共同58/格式51文件0变化/analyze/21冻结+05/锁通过（quality-complete）。复核无Critical/Important，补两个轻微单测后全部通过。先前lint/编辑编码失败按证据保留或说明，不作生产缺陷。原APK哈希核对后恢复冷启动ok/PID28127，无普通Release重建/生产修改；前批未提交修改保留，无提交推送发布，G-L仍未过。旧review记录不改，当前修复以本报告为准。


AUTH-P1-RECREATE-20261101：用户按文档继续，A04重建/媒体暂停交错提交验证。owner Codex串行Android/文档维护；allowlist新integration_test/android_recreate_controls_test.dart及evidence/recreate-controls-20261101、status/handoff。复用review后DiagnosticCleanup，保留当前全部未提交工作、v2.3/21冻结；设备35a63609在线Awake。不同提交顺序非严格物理同时/系统杀进程，不改UI/生产逻辑除非实际回归需登记，不提交推送发布/全局/旧库。进行中。

限定目标完成：[报告](evidence/recreate-controls-20261101/report.md)。手机两顺序2项通过，实际Activity变更/engine会话handle保留/媒体暂停及显式恢复；reviewer位置断言P2补原生新采样和双绝对差后复验通过。共同58/格式52文件0变更/analyze/21冻结+05/锁通过（android-reviewed、quality-reviewed）。生产未改、普通包不重建；手机原APK恢复COLD启动ok/PID31159，Windows未验证/未动。前批全部修改保留，无提交推送发布，G-L未过；下一批A07独立进程恢复/默认暂停/旧控制器失效，先核入口前置。GraphFlow见index.log。

AUTH-P1-PROCESS-20261101限定目标完成：[报告](evidence/process-recovery-20261101/report.md)。最终Android/Windows各一组真实两进程通过，完整runtime读回、默认暂停、旧claim拒绝、显式恢复/去重、原生释放已验；审阅两项P2已修复复核。quality-final共同58、格式52文件0变更、analyze、21冻结及05/锁通过。普通APK/Windows整目录核哈希后恢复，手机COLD启动ok，Windows普通启动2秒后关闭。a2日志截断失败保留，a3重跑通过。无生产修复/提交推送发布；旧修改保留，A07/G-L仍review，下一批自有快照异常/中断新进程退路。GraphFlow见本批index.log。

AUTH-GIT-PUSH-20261101：用户明确要求先提交并推送当前开发成果。允许把codex/seek-boundaries内已验A02并发/桥接、A03/A05超时容量、reviewer清理、A04重建及A07进程恢复的代码/证据/status/handoff提交，并推送origin同名分支。旧批次不提交约束保留为历史；本次不合并、不发布、不上传安装包、不修改全局配置。

AUTH-P1-SNAPSHOTFAULT-20261101：用户继续开发，A07新进程快照异常退路子项。owner Codex串行A07/ConfigIntegrator/文档维护；allowlist新clients/flutter/lib/p1_snapshot_fault_probe.dart、tool/run_snapshot_fault_probe.ps1、本批evidence/snapshot-faults-20261101及status/handoff。只消费v2.3/21冻结真实FileSnapshotStore，不改原型存储/合同/native/UI。6自有场景：missing/corrupt/unknown-version/unavailable-fixture/partial-temp/corrupt-newest，真实seed保存/造故障后强杀再check进程，分别Android35a63609和Windows；遗留tmp是受控故障夹具，不称真正saveFuture中途强杀或断电原子性通过。当前基线ee0e347、分支codex/seek-boundaries，与origin一致干净；新开发不继承上次提交推送授权。普通产物备份还原；不提交推送发布/P2/全局/旧库。进行中。

2026-11-06收尾AUTH-P1-SNAPSHOTFAULT-20261101：限定目标完成，证据见evidence/snapshot-faults-20261101/report.md。实际双端测试在2026-11-01执行，各6组新进程场景通过；58共同测试/53格式文件/analyze/21冻结通过。今天只核代码摘要、冻结与保存proof并补交接索引，未重跑设备、不称当前手机在线。两项诊断验证问题已修复复验，原普通产物此前恢复；A07整体/G-L仍review，真实写中断/独立engine/R2仍未证。新开发修改保持未提交，无推送发布；下一批A08更新剩余矩阵。

AUTH-A08-REVIEW-20261106：用户按文档继续，Codex领取A08增量G-L审阅（A07整体未完成，故仅审已有证据与缺口，不宣称后继实施前置已全满足）。owner串行文档维护；allowlist evidence/A08/20261106-review.md、status/handoff；产品代码只读，保留未提交snapshot-faults。核09门和现有各端报告/真实Activity与engine入口，不安装/运行产品/改合同/P2/提交推送。

AUTH-A08-REVIEW-20261106增量审阅完成：见evidence/A08/20261106-review.md。后续报告已覆盖早期未知输入/定位能力/超时/容量/异常快照若干缺口，当前不重复领取；G-L仍未过、A03—A08仍review。代码核MainActivity保留cached engine，recreateActivity不销毁engine，现无独立engine.destroy入口。下一小批A04/A07先设计可控engine死亡与安全R3验证，不声称R2通过。仅文档/链接检查，无设备运行或产品改动/提交推送。

AUTH-ENGINE-LOSS-20261106：用户继续，领取A04/A07显式engine销毁安全R3。Codex串行Android/A07/ConfigIntegrator维护；allowlist LocalHost.kt/MainActivity.kt、lib/p1_process_probe.dart（仅optin诊断）、tool/run_android_engine_probe.ps1及evidence/engine-loss-20261106、status/handoff。真实手机35a63609/2211133C/Awake。设计：save确认落盘后显式诊断请求Activity finish，super.onDestroy完成detach后再释放native资源/焦点/服务、清旧命令并真实engine.destroy，外部据原生凭据显式重启同PID新engine，恢复默认暂停，拒旧claim后显式继续；不声称原生存活无损R2。保留先前未提交工作、21冻结不变；不改正式UI/全局/旧库/P2/提交推送。

AUTH-ENGINE-LOSS-20261106限定目标完成：evidence/engine-loss-20261106/report.md。真机同PID13305、旧engine26135275真实销毁、新241633931，保存暂停态一轨→R3清资源→同修订位置默认暂停→旧claim拒绝→显式继续/停止通过；非播放中异常死亡/R2。Android本地3+重建2回归共5通过；共同58/格式53/analyze/21冻结+05+锁通过；普通Android Release重建安装COLD启动ok，Windows未验。独立review无阻断，服务退出证据仅最终采样。所有旧修改保留，无提交推送发布；G-L仍review，下一批播放态显式engine销毁扩展。

AUTH-ENGINE-PLAYING-20261106：继续A04/A07播放态显式engine销毁。Codex串行A07诊断/文档维护，allowlist lib/p1_process_probe.dart、tool/run_android_engine_probe.ps1及evidence/engine-playing-20261106、status/handoff。只增编译optin与RequirePlaying断言，不改native实现/21冻结；保存2345暂停态后同handle播放，两个真实nativePlaying+position递增采样后调用既有销毁入口，新engine同PID恢复原落盘位置默认暂停。手机35a63609在线Awake。保留全部旧修改，不提交推送/P2/UI/全局/旧库。

AUTH-ENGINE-PLAYING-20261106限定目标完成：evidence/engine-playing-20261106/report.md。手机销毁前两个同handle真实nativePlaying样本2465→2707；同PID18536，新engine160958312从保存2345暂停恢复，旧claim拒绝、显式2709/停止0通过；shared58/format53/analyze/21冻结+05+锁通过，聚焦review无问题。普通APK哈希还原安装COLD启动ok，Windows未验；native未变，不重复先前5项回归。当前仅显式销毁，非异常回收/R2；G-L仍review，旧修改保留无提交推送发布。

AUTH-COORD-RESTART-20261106：继续A07 R2边界核对与既有安全退路。owner Codex串行共享诊断测试/文档；allowlist新integration_test/coordinator_restart_test.dart及evidence/coordinator-restart-20261106、status/handoff。现有acquireController只同对象换owner，dispose释放资源，没有存活资源adopt接口，不冒称R2。验证save→播放→close释放→新LocalRuntime新协调器读回暂停/旧claim拒绝/显式继续停止，双端分别实跑。只用自有fixture，冻结21/合同/native/UI不变，保留旧修改，不提交推送/P2/全局/旧库。

AUTH-COORD-RESTART-20261106 partial：evidence/coordinator-restart-20261106/report.md。Windows真实1项新协调器安全重建通过；共同58/格式54/analyze/21冻结+05/锁通过。Android首帧停滞时Dozing，执行者中止未通过；已请求解锁并补测试窗口亮屏清理，等待重跑，不以另一端替代。普通APK已还原安装。R2现无adopt接口，CAS仅同对象，不改冻结伪接管。保留未提交修改无推送发布；下一步优先接续本Android测试。

AUTH-COORD-RESTART-20261106最终接续完成：用户解锁后android-retry.log真机1项通过（PID26238，新epoch1793961384773375，修订1/位置2345暂停读回、旧claim拒绝、显式播放停止资源0）；Windows此前1项通过，本批双端限定目标完成。首次前台条件失败修正为同谓词有界等待并实跑通过，失败日志保留。quality-final共同58/格式54/analyze/21冻结+05/锁通过，普通APK恢复安装COLD启动ok。无损R2仍未实现/未验证，G-L仍review。无提交推送发布。

AUTH-R2-BOUNDARY-20261106：接续用户“继续按开发文档执行”，Codex串行A07/A02只读合同核查和文档协调。allowlist evidence/A08/20261106-r2-boundary.md及配套check/index日志、status/handoff；消费p1-a02-v2.3/协议快照1，不改冻结。源码核查确认同对象CAS、释放后重建与存活资源R2的区别，完成下一批排他转移/身份核对/事件间隙/失败退路验收输入，见[报告](evidence/A08/20261106-r2-boundary.md)。本批无产品变更、设备/构建/安装或提交推送；已有未提交工作保留。R2未实现/未验证，A07/A08/G-L仍review；下一批先由共享维护者评审窄单轨接管合同与失败测试设计，再实施，不复制私有状态或改写历史冻结。

AUTH-R2-DESIGN-20261106：用户“继续执行”后领取A07/A02单轨存活backend协调器替换设计，owner Codex串行合同设计/文档协调。allowlist evidence/r2-handoff-20261106/design.md及检查/索引/审阅记录、status/handoff；当前消费p1-a02-v2.3，不改冻结或产品。本批设计同isolate合作式同步handoff，拒绝pending/双轨/释放/在途控制，明确事件和旧对象退休围栏；不代替跨engine异常死亡R2。设计进入review，实施前按已安装brainstorming技能完成设计检查及具体文档确认；不新增全局工具/设备实验/提交推送，既有全部改动保留。

AUTH-R2-IMPLEMENT-20261106：用户确认design.md，Codex串行A02/A07/ConfigIntegrator实施。allowlist coordinator/runtime、共同及新集成handoff测试、05、A02新v2.4冻结、tool/check.ps1选择器、evidence/r2-handoff-20261106及status/handoff；必要测试support仅本批使用。旧冻结不改，协议/快照仍1；双端分验及普通产物备份恢复，手机35a63609须在线解锁。不跨engine/P2/依赖/旧库/全局/提交推送。当前in-progress，所有已有修改保留。

AUTH-R2-IMPLEMENT-20261106 partial/review：同isolate合作式单轨新协调器已实现；最终quality-final锁/24文件+05哈希/56文件格式0变更/analyze/68共同测试通过。Windows真实1项PID9948、单轨native-1、确认一次、接管位置2794>保存2345、停止原生空；独立review无Critical/Important，补3项清理/route错误测试通过。两端普通main Release已构建，Windows启动PID23372后由工具关闭，非播放验收；Android实际Dozing且未获解锁回复，本批真机测试/安装未执行。旧普通APK和Windows整目录已备份，新普通产物摘要ordinary-current.json。R2跨engine/异常死亡、完整runtime交错/听感未验，G-L保持review。保留全部旧修改，无提交推送。接续先核35a63609解锁/foreground，跑新integration_test/coordinator_handoff_test.dart，结束恢复本批新普通APK；勿重复实现或重写冻结。

AUTH-R2-IMPLEMENT-20261106最终接续完成：用户解锁后android-final.log退出0，Android真实1项通过；PID372，epoch1793965093366385→1793965093366386，backendEpoch1/单轨native-1，同host，接管2709>保存2345，确认一次、旧claim拒绝、系统pause/play/stop及最后原生空。此前Windows1项通过，限定双端目标完成。未改源码，未重复共同68/Windows；沿用quality-final及独立审阅。本批新普通APK核哈希恢复安装Success，COLD启动ok/PID980/Awake。A07/G-L仍review，合作式同isolate不等于异常死亡/跨engine无损R2；完整runtime交错等未验保留。不提交推送，已有修改全部保留。

AUTH-RUNTIME-BUSY-20261106：用户继续开发，领取A07已批准handoff设计的runtime busy确定性验证；owner Codex串行共享测试/文档。allowlist新clients/flutter/test/runtime/runtime_handoff_busy_test.dart、evidence/runtime-busy-20261106及status/handoff；消费v2.4/24文件/协议快照1，不改产品/原生/冻结/依赖。Mock MethodChannel+Completer控制mirror/release，覆盖mirror成功失败、destroy成功及save验证失败，拒绝不变权威资源。只宿主验证，不设备/构建/安装/私人数据/提交推送；全部旧修改保留。整体close/save和真实销毁失败资源恢复另保留未验。

AUTH-RUNTIME-BUSY-20261106限定目标完成：[报告](evidence/runtime-busy-20261106/report.md)。新增4项宿主MethodChannel门控验证，mirror成功/失败finally后可转移，destroy等release时拒绝handoff/save/重复destroy且无权威资源副作用，完成后paused/空资源；save校验失败无busy泄漏。最终Quality72/格式57文件0变化/analyze/原v2.4的24冻结+05/锁通过。独立测试审阅无阻断，Minor初始化失败mock清理已补并复验。产品/冻结/native/普通双端产物未改，本批不设备/构建/安装/提交推送；不把mock写成真机故障通过，A07/G-L仍review。销毁失败安全退路和整体close/save竞争等未验保留。

AUTH-DESTROY-FAILURE-20261106：用户继续执行，Codex串行A07/A02/ConfigIntegrator核查并修复销毁失败退路；allowlist runtime/local_runtime.dart、platform/local/native_local_backend.dart、新test/runtime/runtime_destroy_failure_test.dart（相对clients/flutter/lib或test）、必要双端新故障集成入口、05、A02新v2.5冻结、tool/check.ps1及evidence/destroy-failure-20261106/status/handoff。先受控复现单轨release失败后错误接管与失败Future缓存，再最小修复不可信状态阻断及显式重试；旧v2.4/全部旧工作保留，不跨engine/P2/真实源/全局/提交推送。原生不新增故障API；平台回归与受控故障分别记录。

AUTH-DESTROY-FAILURE-20261106限定修复完成：受控红例证实release失败后错误接管及失败Future缓存，已修runtime不可信锁存/暂停意图/接管起播围栏、native失败释放显式重试。最终quality-reviewed77/格式58/analyze/新v2.5的26冻结+05/锁通过；旧v2.4不改。独立review无Critical/Important，pause失败与并发release复用2测试已补。真实Android/Windows正常handoff回归各1项通过，不等于真实native故障注入。双端普通main Release构建通过，手机普通安装COLD ok/PID7900/Awake，Windows启动PID4684后关闭；产物摘要ordinary-final.json。部分多资源恢复/持续失败close收尾及整体竞争、跨engine/听感仍未验，A07/G-L仍review。旧修改全部保留，无提交推送发布。

AUTH-CLOSE-FAILURE-20261106：用户继续执行，Codex串行A07/A02/ConfigIntegrator修复持续release失败阻断关闭清理；allowlist runtime/local_runtime.dart、platform/local/native_local_backend.dart、必要窄清理helper、新test/runtime/runtime_close_failure_test.dart、05/A02新v2.6/tool/check.ps1、evidence/close-failure-20261106/status/handoff。先红例确认writer锁/notifier/流/后续资源清理中断及mirror Future覆盖，再最小独立收尾与close去重。旧v2.5/全部既有改动保留，不全生命周期重写、不原生故障API/P2/全局/提交推送，双端正常回归与mock失败分开记录。

AUTH-CLOSE-FAILURE-20261106限定目标于2026-11-07完成：持续release失败不再阻断后续独立清理，close成功/失败共用Future、首错stack保留、writer/notifier/流和后续handle尝试；真实mirror Future不被skip tick覆盖。最终Quality82/格式60/analyze/v2.6的28冻结+05/锁通过；旧v2.5不改。独立review首次额度失败、重试无阻断，两个测试缺口已补。Android11-06/Windows11-07真实正常close→读盘恢复各1项通过，非故障注入。普通双端Release构建通过，手机恢复新普通APK COLD ok/PID23428，Windows启动PID15784后关闭。never-completing Future/暂停订阅及整体save/destroy竞争仍未保证，A07/G-L仍review；无提交推送，旧修改保留。

AUTH-GR-FIX-20261107：用户按review文档修改，领取global-review GR01/02；Codex串行A02/播放维护/ConfigIntegrator。allowlist playback_coordinator.dart、新test/playback/transition_recovery_test.dart、必要集成测试、05/A02新v2.7/check.ps1及evidence/gr-fixes-20261107/status/handoff。旧v2.6/全部修改保留，不提交推送或放行G-L。先红例再修复，平台结果与fake分开。

AUTH-GR-FIX-20261107完成：GR01/02及追加pending B失败回退已修，9项红绿回归、最终91共同/格式分析/新v2.7的30冻结+05/锁通过。独立review追加Important已修并复核无新阻断。Android/Windows专项各4项真实事件介入通过，普通双端Release新构建，手机恢复COLD ok/PID27568。旧v2.6/所有旧工作保留，尚未提交推送；更广全局差异及条件提交授权需另作最终核对，G-L仍review。证据evidence/gr-fixes-20261107。

AUTH-CLOSE-RACE-20261107：用户继续开发，基线e57079d干净，Codex串行A07/A02/ConfigIntegrator领取close与在途save/destroy竞争修复。allowlist runtime/local_runtime.dart、新test/runtime/runtime_close_race_test.dart、05/A02新v2.8/check.ps1、evidence/close-race-20261107/status/handoff；受控复现后最小等待已开始操作、抑制closed后通知，旧v2.7保留，不扩无穷Future策略/全局/P2，不提交推送。

AUTH-CLOSE-RACE-20261107 partial/review：3红→3绿，补2项listener重入及busy拒绝不覆盖pending，最终96共同/格式63文件0变更/analyze/31冻结+05/锁通过，独立review无阻断。Windows正常restart1项通过，双端普通main Release构建成功；Android本批未执行/未安装，待用户解锁，旧手机普通入口未动。新普通APK备于graphflow-out/close-race-20261107/ordinary-final。保持G-L review，旧v2.7不改，不提交推送。

AUTH-CLOSE-RACE-20261107限定目标完成：用户解锁后android-final.log真机1项exit0，PID29736/新epoch1794017525694897/修订1位置2345默认暂停及最终原生空；此前Windows正常restart1项通过。本批源码未变，沿用96共同/63格式/analyze/31冻结+05/锁和独立review，不称本次重新运行。普通APK核哈希恢复安装Success/COLD ok/PID30184/Awake。受控竞态与真实正常回归分证，G-L仍review。无提交推送，未动旧库/全局。

CHECKPOINT-20261107：沿用global-review-20261107记录的条件提交推送授权，对e57079d之后本批close-race增量完成最终复核；Quality96/格式63/analyze/31冻结+05/锁通过，待提交文本凭据扫描无命中，远程当前分支仍e57079d。当前准备在既有codex/seek-boundaries创建阶段checkpoint并推送，实际结果见Git回执，不merge/release，不视为完整G-L通过。详见evidence/checkpoint-20261107/report.md。

AUTH-CLOSE-OBSERVE-20261107：用户继续执行，基线6bb75bc干净，Codex串行A07/A02核查mirror等待时已接管操作Future的错误观察。allowlist runtime/local_runtime.dart、新test/runtime/runtime_close_observe_test.dart、05/A02新冻结/检查选择器及evidence/close-observe-20261107/status/handoff。先受控复现，仅必要最小修复；不超时策略/原生/全局/P2/自动提交推送。

AUTH-CLOSE-OBSERVE-20261107限定目标完成：mirror挂起时close已接管destroy失败形成未处理错误，corrected red复现；改为接管时立即观察并记录，关闭仍等待mirror/操作后收尾，原操作/close同错误对象。green1+全97/格式64/analyze/32冻结+05/锁通过，独立review无阻断。旧v2.8保留，普通产物摘要未变，本批不设备/构建/安装，手机仍旧已验包；不称save故障注入、全跨zone/无穷等待或G-L通过。不提交推送。报告evidence/close-observe-20261107/report.md。

AUTH-CLOSE-OBSERVE-PLATFORM-20261107：用户继续执行，Codex 串行 A07/A02 验证既有 p1-a02-v2.9；范围为 evidence/close-observe-platform-20261107、status/handoff 和忽略的普通产物。验证正常关闭恢复，构建普通 main 并恢复已选手机；不修改源码、冻结或提交推送。

AUTH-CLOSE-OBSERVE-PLATFORM-20261107 限定目标完成：Android/Windows 各 1 项正常关闭恢复通过；普通 main 两端构建并启动，已选手机已从测试包恢复普通 APK；普通产物 18 文件哈希与上批一致，v2.9 冻结与锁保持。证据见 evidence/close-observe-platform-20261107/report.md。G–L 仍 review，未提交推送。
