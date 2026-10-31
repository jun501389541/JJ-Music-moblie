# 任务索引与唯一依赖图

R4已把P0—P9及独立发行写成详细任务。**本表只维护任务前置与独立条件**；状态/实际负责人/授权/集成证据只在[status](../status.md)，字段只在05/07/08，文件维护角色只在[归属表](contracts-ownership.md)。手册完整不等于ready；实际授权与验收只看status；旧“仅文档”记录是历史，未知/未验原型项仍不得当作通过。

## 如何开始

当前先读[新手一页](../beginner-guide.md)和[任务地图](../task-map.md)。已有工程及历史实现时先核实际证据，不重复PREP或create；当前用户已新增初始框架基础维护授权，具体范围见status。视觉规划PREP-02独立。阶段入口P2-00等仅在相应阶段授权后把已填手册映射到真实树/前置结果，常规工程细节由agent处理，不新增逐层审批。一次批次一个可审查结果；阶段授权可连续推进满足前置的批次。

条件列是已有门/能力/授权的适用范围，不是新增门。前置逗号为全部满足；条件性功能未启用可有依据记N/A，但实际失败/未测不得冒充N/A。REL-01允许Android在P3安全验收后首发，不被P8高级能力阻塞；REL-02针对完整Windows/双端候选。公开兼容声明仍需实际G-S1范围。

当前DAG描绘完整范围。若用户已明确接受本批延期某可选能力，协调者先按03/09登记差距/决定、更新本批任务范围与下游依赖，再执行受影响后继；延期任务不能伪done、失败不能改N/A，也不能直接跳过仍列在表中的前置。阶段入口负责这一实际范围核对，不让未选可选功能暗中阻塞首版，也不新增审批层。

## 稳定任务注册表

| ID | 阶段 | 前置任务（-为无） | 独立门/授权及条件 | 详细说明 |
| --- | --- | --- | --- | --- |
| DOCSET-01 | P0 | - | 本轮仅文档授权 | [phase-0.md](phase-0.md) |
| DOCSET-02 | P0修订 | DOCSET-01 | R3.1定点文档/校验授权 | [phase-0.md](phase-0.md) |
| DOCSET-03 | P0补充 | DOCSET-02 | R3.2横向审阅/相关文档校验授权 | [phase-0.md](phase-0.md) |
| DOCSET-04 | P0契约澄清 | DOCSET-03 | R3.3四项执行契约文档/校验授权 | [phase-0.md](phase-0.md) |
| DOCSET-05 | P0手册 | DOCSET-04 | 仅本轮文档授权，交付停止 | [phase-0.md](phase-0.md) |
| PREP-01 | P1-A规划 | DOCSET-05 | 后续阶段规划/设计审核范围 | [phase-0.md](phase-0.md) |
| PREP-02 | P0-V规划 | DOCSET-05 | 视觉规划范围 | [phase-0.md](phase-0.md) |
| V01 | P0-V | PREP-02 | 视觉产物编制范围 | [phase-0.md](phase-0.md) |
| V02 | P0-V | V01 | 用户对具体版本确认 | [phase-0.md](phase-0.md) |
| A01 | P1-A | PREP-01 | P1-A批次实施授权/依赖范围 | [phase-1a.md](phase-1a.md) |
| A02 | P1-A | A01 | 同上；短提交/共享合同与隔离文件快照负责人 | [phase-1a.md](phase-1a.md) |
| A03 | P1-A | A02 | 共享测试/夹具冻结；Android设备 | [phase-1a.md](phase-1a.md) |
| A04 | P1-A | A03 | 系统生命周期实验 | [phase-1a.md](phase-1a.md) |
| A05 | P1-A | A02 | 同一共享测试/夹具冻结；Windows工具链/原生资产 | [phase-1a.md](phase-1a.md) |
| A06 | P1-A | A05 | Windows系统控制实验 | [phase-1a.md](phase-1a.md) |
| A07 | P1-A | A02,A04,A06 | A02真实文件快照完成；双端映射/排他接管实验，不等P2 | [phase-1a.md](phase-1a.md) |
| A08 | P1-A | A07 | G-L证据审阅 | [phase-1a.md](phase-1a.md) |
| PREP-03 | P1-B规划 | A02 | P1-B规划/安全实验范围 | [phase-0.md](phase-0.md) |
| B01 | P1-B | PREP-03 | 网络/回环原型授权 | [phase-1b.md](phase-1b.md) |
| B02 | P1-B | B01 | 受控网络范围 | [phase-1b.md](phase-1b.md) |
| B03 | P1-B | PREP-03 | 自有脚本，不含真实源 | [phase-1b.md](phase-1b.md) |
| B04 | P1-B | B03,B02 | 隔离/资源上限实验 | [phase-1b.md](phase-1b.md) |
| B05a | P1-B | B04 | 独立真实脚本/曲目/平台授权 | [phase-1b.md](phase-1b.md) |
| B06 | P1-B | B02,A07 | 后端/Broker联调，非完整渐变 | [phase-1b.md](phase-1b.md) |
| B05b | P1-B | B05a,B06 | G-B/G-S0和同范围真实源授权 | [phase-1b.md](phase-1b.md) |
| B07 | P1-B | PREP-03,A07 | 无播放后台实验 | [phase-1b.md](phase-1b.md) |
| B08 | P1-B | B07,B06 | 中断/恢复/单writer实验 | [phase-1b.md](phase-1b.md) |
| B09 | P1-B | B04,B06,B08 | 分别审阅门；B05可明确待验 | [phase-1b.md](phase-1b.md) |
| P2-00 | P2 | A08 | G-L；正式UI任务另需G-V | [phase-2.md](phase-2.md) |
| P2-01 | P2 | P2-00 | G-L；数据方案在已授权范围有决定记录 | [phase-2.md](phase-2.md) |
| P2-02 | P2 | P2-01 | 08 O锁/归属表已冻结 | [phase-2.md](phase-2.md) |
| P2-03 | P2 | P2-01 | G-L；FileAccess能力及08 O表已冻结 | [phase-2.md](phase-2.md) |
| P2-04 | P2 | P2-02,P2-03 | 08 O扫描/发布锁序冻结 | [phase-2.md](phase-2.md) |
| P2-05 | P2 | P2-04 | 03文本基线已接受，候选拼音实现已审计 | [phase-2.md](phase-2.md) |
| P2-06 | P2 | P2-01 | G-L，A02确认/短提交及A03/A05映射已冻结 | [phase-2.md](phase-2.md) |
| P2-07 | P2 | P2-00 | 不要求正式UI；格式范围沿当前基线 | [phase-2.md](phase-2.md) |
| P2-08 | P2 | P2-00,V02 | G-V具体稿件版本及G-L | [phase-2.md](phase-2.md) |
| P2-09 | P2 | P2-04,P2-05,P2-08 | G-V对应页面 | [phase-2.md](phase-2.md) |
| P2-10 | P2 | P2-06,P2-08 | G-V播放页版本 | [phase-2.md](phase-2.md) |
| P2-11 | P2 | P2-07,P2-10 | G-V歌词状态 | [phase-2.md](phase-2.md) |
| P2-12 | P2 | P2-06,P2-08 | G-V队列/历史稿 | [phase-2.md](phase-2.md) |
| P2-13 | P2 | P2-09,P2-10,P2-11,P2-12 | G-L/G-V及本地子任务集成证据 | [phase-2.md](phase-2.md) |
| P3-00 | P3 | P2-13 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-3.md](phase-3.md) |
| P3-01 | P3 | P3-00 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-3.md](phase-3.md) |
| P3-02 | P3 | P3-00 | G-V歌单稿件 | [phase-3.md](phase-3.md) |
| P3-03 | P3 | P3-01 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-3.md](phase-3.md) |
| P3-04 | P3 | P3-00 | G-V诊断稿；若延期记录依据不阻MVP | [phase-3.md](phase-3.md) |
| P3-05 | P3 | P3-00 | 首次对外包已获选；实际签名/分发仍需现有独立授权 | [phase-3.md](phase-3.md) |
| P3-06 | P3 | P3-01,P3-02,P3-03 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-3.md](phase-3.md) |
| P4-00 | P4 | P3-06,B02 | G-N；不要求G-S1才能计划资料 | [phase-4.md](phase-4.md) |
| P4-01 | P4 | P4-00 | G-N；平台资料范围在阶段授权内 | [phase-4.md](phase-4.md) |
| P4-02 | P4 | P4-00,B04 | G-S0；正式源管理UI需G-V；真实脚本另授权 | [phase-4.md](phase-4.md) |
| P4-03 | P4 | P4-00,B04 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-4.md](phase-4.md) |
| P4-04 | P4 | P4-02,P4-03,B06 | G-B/G-S0；实际真实源验证按B05a/b授权，不等P4才做首次实验 | [phase-4.md](phase-4.md) |
| P4-05 | P4 | P4-01,P4-04 | G-V相关在线页面；无真实源证据仅受控验证不宣称兼容 | [phase-4.md](phase-4.md) |
| P4-06 | P4 | P4-05 | 公开日用兼容声明需对应G-S1；未满足可做受控工作但不完成该声明 | [phase-4.md](phase-4.md) |
| P5-00 | P5 | P3-06 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-5.md](phase-5.md) |
| P5-01 | P5 | P5-00,P3-02 | G-V管理稿，schema串行 | [phase-5.md](phase-5.md) |
| P5-02 | P5 | P5-00,P4-04,B08 | G-D和G-B/G-S0；真源另需对应证据/授权 | [phase-5.md](phase-5.md) |
| P5-03 | P5 | P5-02 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-5.md](phase-5.md) |
| P5-04 | P5 | P5-03 | G-V下载稿；私人文件删除仍需授权 | [phase-5.md](phase-5.md) |
| P5-05 | P5 | P5-00 | G-V备份稿；数据仅自有或明确授权 | [phase-5.md](phase-5.md) |
| P5-06 | P5 | P5-05,P3-01 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-5.md](phase-5.md) |
| P5-07 | P5 | P5-00 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-5.md](phase-5.md) |
| P5-08 | P5 | P5-01,P5-04,P5-06,P5-07 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-5.md](phase-5.md) |
| P6-00 | P6 | P5-08 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-6.md](phase-6.md) |
| P6-01 | P6 | P6-00 | G-N及该平台资料范围、公共模型冻结 | [phase-6.md](phase-6.md) |
| P6-02 | P6 | P6-00 | G-N及该平台资料范围、公共模型冻结 | [phase-6.md](phase-6.md) |
| P6-03 | P6 | P6-00 | G-N及该平台资料范围、公共模型冻结 | [phase-6.md](phase-6.md) |
| P6-04 | P6 | P6-00 | G-N及该平台资料范围、公共模型冻结 | [phase-6.md](phase-6.md) |
| P6-05 | P6 | P6-00 | G-N及该平台资料范围、公共模型冻结 | [phase-6.md](phase-6.md) |
| P6-06 | P6 | P6-00 | G-V来源稿 | [phase-6.md](phase-6.md) |
| P6-07 | P6 | P6-06 | G-V待写入稿 | [phase-6.md](phase-6.md) |
| P6-08 | P6 | P6-07 | 自有写入范围和08 O冻结；私有数据另授权 | [phase-6.md](phase-6.md) |
| P6-09 | P6 | P6-06,P2-11 | G-V增强歌词状态 | [phase-6.md](phase-6.md) |
| P6-10 | P6 | P6-00,P4-01,P5-01 | G-N/G-V及启用平台证据 | [phase-6.md](phase-6.md) |
| P6-11 | P6 | P6-01,P6-02,P6-03,P6-04,P6-05,P6-08,P6-09,P6-10 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-6.md](phase-6.md) |
| P7-00 | P7 | P5-07,P2-13 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-7.md](phase-7.md) |
| P7-01 | P7 | P7-00,P5-06 | G-V迁移稿；私人数据另授权 | [phase-7.md](phase-7.md) |
| P7-02 | P7 | P7-00 | 所选形态/试用范围已授权 | [phase-7.md](phase-7.md) |
| P7-03 | P7 | P7-02 | G-V；新增关联动作需用户选定 | [phase-7.md](phase-7.md) |
| P7-04 | P7 | P7-00 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-7.md](phase-7.md) |
| P7-05 | P7 | P7-00,P2-11 | G-V桌面词稿及窗口能力 | [phase-7.md](phase-7.md) |
| P7-06 | P7 | P7-00,P2-13 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-7.md](phase-7.md) |
| P7-07 | P7 | P7-01,P7-02,P7-03,P7-04,P7-05,P7-06 | 私人试用/设备另授权；否则只自有profile | [phase-7.md](phase-7.md) |
| P8-00 | P8 | P6-11,P7-07 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-8.md](phase-8.md) |
| P8-01 | P8 | P8-00 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-8.md](phase-8.md) |
| P8-02 | P8 | P8-00,B06 | G-B及真实双轨能力 | [phase-8.md](phase-8.md) |
| P8-03 | P8 | P8-00 | G-V效果设置与已审能力 | [phase-8.md](phase-8.md) |
| P8-04 | P8 | P8-00 | G-V效果状态/已验采样 | [phase-8.md](phase-8.md) |
| P8-05 | P8 | P8-00 | 明确LAN/设备授权；回环令牌不等于LAN授权 | [phase-8.md](phase-8.md) |
| P8-06 | P8 | P8-05,P4-06 | G-B/G-S0/G-S1相应profile及真实源/LAN设备授权 | [phase-8.md](phase-8.md) |
| P8-07 | P8 | P8-00,P8-04 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-8.md](phase-8.md) |
| P8-08 | P8 | P8-00 | G-V与实际辅助技术环境 | [phase-8.md](phase-8.md) |
| P8-09 | P8 | P8-01,P8-02,P8-03,P8-05,P8-06,P8-07,P8-08 | 启用能力必需测试齐，未支持高级能力须有明确范围/差距决定 | [phase-8.md](phase-8.md) |
| P9-00 | P9 | P8-09,P7-07 | 对应阶段范围已授权；仅启用已满足能力门的功能 | [phase-9.md](phase-9.md) |
| P9-01 | P9 | P9-00,REL-02 | 用户对具体替换/维护范围的明确决定，REL-02交付证据 | [phase-9.md](phase-9.md) |
| P9-02 | P9 | P9-01 | 已授权维护交接范围；产品修复另按相应任务 | [phase-9.md](phase-9.md) |
| REL-01 | REL | P3-05 | 明确本次签名/交付或公开发行授权；Android首发启用能力均已验。若采用P8较新候选，还需其对应证据 | [releases.md](releases.md) |
| REL-02 | REL | P8-09,REL-01 | 本次各端产物/渠道/说明明确发行授权；未授权端不操作 | [releases.md](releases.md) |

## 保留的分流与文件规则

A08/G-L不等B；P2非视觉本地不等音源/正式UI稿。G-V只阻对应正式UI。G-N仅B02 TC-46/13，P4/P6 TC-23/33不回指早期；B05a/b用最小诊断链，不等P4，B09只是汇总不成为所有门签发前置。TC-58文件锁交错不倒灌P1。A07显式依赖A02真实文件前置，不等正式P2库。

A03/A05在A02合同/fixture/快照接口冻结且共用配置已整合后才可独立；归属/版本/并行/集成只按[contracts-ownership](contracts-ownership.md)。原tasks索引里的重复文件归属表已迁至该唯一表，不再两处维护。

旧23个WP已被下列详细任务展开，只保留[范围映射](phase-backlog.md)供旧引用和覆盖核对，**WP不是可领取任务，不再称未展开**。阶段开始仍需核实真实工具/API/文件、冻结版本和精确allowlist；未知项按[条件分支](conditional-branches.md)负责任务确定，不能因标题存在自动ready。旧聊天P1-xx/R2-Txx不作执行编号。

