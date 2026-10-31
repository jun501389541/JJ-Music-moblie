# 契约版本、文件归属与集成

本页是**文件维护角色及合同定位的唯一表**；字段/业务规则仍在05/07/08/03，依赖只在任务索引，实际负责人/冻结证据/进度只在status。角色是职责，不指定某款agent或必须多人；单agent可顺序承担全部角色。A01/A02及本批P1薄适配路径已实际落地；未实现路径仍是计划。当前消费冻结见status与A02/20261031-freeze，不能把计划表当运行结果。

## 版本与消费记录

每批记录：文档版本R4、所消费C/M/D及schema/compat profile/视觉稿的实际版本或文件摘要、证据链接。05当前协议初值是提案，不能把“文档R4”当运行协议4或已冻结实现。阶段入口根据原型实际结果锁定需要的字段/API/文件；未定项指向任务和条件分支，不生成假方法。

| 合同/共享文件 | 规则/版本权威位置 | 初始维护角色与交接时点 | 受影响消费者 |
| --- | --- | --- | --- |
| C身份/队列/确认/恢复；lib/domain/playback、lib/application/playback公共端口 | 05 C-01—06；选择依据ADR-0002 | A02合同维护者；P2-00登记后可交P2-06维护者，交接前仍A02 | A03—A07、B06、P2播放/UI、P4在线、P8双轨 |
| RecoverySnapshotStore端口、lib/data/prototype_recovery/file_snapshot_store.dart | 05 C-03 | A02；A07只读消费；P2-01实现正式适配，P2-00定保留测试/关闭原型 | A07、P2-01/P2-06、生产恢复 |
| integration_test/support/local_playback_contract.dart、fixtures/local_playback/**、test/playback公共断言 | 05公共合同；用例含义10 | A02唯一维护；冻结文件/摘要后A03/A05只导入 | Android/Windows入口与后续生产回归 |
| android_local_playback_test.dart、support/android_local_playback_adapter.dart | C-05公共输入输出 | A03；后续Android适配变更由已登记平台维护者 | A04、A07、生产Android |
| windows_local_playback_test.dart、support/windows_local_playback_adapter.dart | 同一C-05 | A05；不复制共享断言 | A06、A07、生产Windows |
| 本目录evidence/A03或A05批次的事件映射及各端日志 | C-05交付维度；具体条件以实际映射/原始证据 | A03和A05各自写独立文件；公共字段变化交合同维护者 | C项目确认、系统媒体、去重与交接 |
| 数据库schema、迁移、索引和唯一writer装配 | 08；ADR-0004和实际schema迁移版本 | SchemaMaintainer角色始于P2-01；P5-07/P7迁移申请变更，由同一角色串行整合 | 所有Repository/备份/恢复/扫描/下载/资产 |
| pubspec.yaml/pubspec.lock、原生依赖锁、ABI/资产清单 | 06/ADR及真实锁文件/摘要 | ConfigIntegrator始于A01，后续阶段入口登记承接者 | 全部构建/平台注册及插件使用者 |
| Android服务/Manifest/Gradle、Windows runner/CMake/安装/更新配置 | 05平台职责、10分发 | 对应平台维护角色；共用文件由ConfigIntegrator串行改；P3-05/P7-02/P8-09给明确批次 | 后台、文件、通知、窗口、SMTC、分发 |
| CatalogAdapter公共模型/通用Transport；lib/data/catalog/platforms/<id> | 05资料接口、07 M、03/TC-33/46 | 公共模型/Transport维护角色在P4-00登记；P6-00冻结后五平台任务只改各自目录 | 搜索/榜单/歌单/详情/资料缓存 |
| SourceRuntime/profile/shim/预算/代次 | 07-source-runtime；实际profile版本 | B03/B04维护者；P4-00登记生产承接，不各端自定重试 | 解析/后台下载/撤源/Broker |
| 下载任务与part/checkpoint/发布 | 07 D、08 schema/O | P5-02协调者消费schema，平台执行器只改执行适配；发布由P5-03 | 下载UI/入库/恢复/删除 |
| 资产来源/pending/Writer、文件锁序/预约协议 | 08与03；锁表具体版本在相应阶段证据 | 公共Asset角色P6-00登记；08 O统一规则，SchemaMaintainer整合字段 | 播放释放、清理、扫描、标签、下载发布 |
| UI令牌/基础组件/strings、路由根/运行时装配 | 04/04-visual-review、ADR-0006、实际稿件批准 | P2-08维护令牌/文案；路由/组合根整合者在P2-00登记 | 所有页面；页面作者不各自改一份主题/播放器生命周期 |
| status/依赖索引/本次handoff、批准记录 | 各自权威文件 | 当前批次协调者单写；实际执行者另交独立证据 | 所有agent |

代码范围相对clients/flutter，证据范围相对本目录。表内角色交接只在status登记人员与证据，不在多个文件再填姓名/完成状态。任务allowlist中的共享文件不意味着执行者可抢写：由维护者在该批次整合，同一人承担两角色时也记录版本。

## 契约变更步骤

1. 在本批证据提出旧/新版本或摘要、原因、受影响任务/字段/兼容与重验范围；先改对应权威合同及ADR，不能只发聊天。
2. 协调者暂停正在消费旧版本的任务；维护者串行整合共享文件，schema升级保持版本链，锁文件不得最后写入覆盖。
3. 消费者重新读取并记录确认的新版本；未确认不得继续。常规已授权修复不需用户再批准类名；涉及产品语义、权限/范围或原有独立边界才转用户决定。
4. 重跑受影响共享测试与两端平台路径；原型结果、分支通过、集成通过分别记录。不能删除失败用例、降条件、吞错误或把失败改N/A。

## 可并行与必须串行

可选并行：A02公共合同/快照/fixture冻结且共用配置整合完成后的A03/A05；各自前置满足的纯搜索与歌词模块；P6-00公共schema冻结后的五平台目录。每次仍须比较实际文件allowlist，以上不是自动并行许可。

必须串行：共享模型/schema/迁移号、锁文件、同一平台注册/构建文件、令牌/路由根、公共测试、状态/批准文件；P1恢复A07等A02文件与两端前置。未冻结接口或文件重叠时先整合/缩范围，不复制两套业务规避冲突。任何端都不能在原生再实现队列/随机/重试/音质策略，详见05。

多agent先由协调者在status领取/复读确认，每人有独立工作区或不相交文件；无可靠协调者/隔离方式时单agent顺序执行。工作树/分支不自动授权提交、合并、推送、发布。不能覆盖/回滚他人未提交改动，跨工具交付使用仓库内证据/补丁或可审查差异，不要求共享聊天/记忆或自动互发消息。

## 集成与完成

执行者先交分支/工作区完整SHA和未提交实际差异、合同版本、用例结果及未完成部分；status先review。集成者核差异/冲突/owner和目标基线，将修改放入目标工作区后跑受影响共同用例及平台检查，保存独立集成结果。只有本任务必需验收与集成均有证据才done；无集成资源可留review，不能以分支成功代替。具体结果术语以agent-workflow为准。

