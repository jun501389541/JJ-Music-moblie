# 原WP范围的展开映射（聚合ID废止为执行任务）

R4已将旧23个阶段级WP实际展开为详细任务。**原“尚未展开、不可直接执行的工作包”表述已被本页替代**；WP只作为历史引用/范围聚合，不能领取或另标ready/done。具体依赖唯一看[任务索引](README.md)，步骤见相应任务页，实际状态只在status。

保留旧范围名称与现有全部功能边界，不自动增加首版：下载/逐字支持子集/待写入/桌面词/DLNA等仍在原阶段；可选新行为仍需原有范围决定。阶段入口负责核真实前置与文件细节，不表示本文又是一层未填模板或额外审批。

| 聚合ID（仅旧引用） | 原范围保留 | 现在的详细任务 |
| --- | --- | --- |
| WP-P2-DATA | 正式DB/schema/事务、窄恢复端口适配与原型替换、08存储/锁序；不做全量迁移 | [P2-01](phase-2.md)、[P2-02](phase-2.md) |
| WP-P2-LOCAL | 扫描/资料/本地搜索/目录；按03保留入口差异，不联机改文件 | [P2-03](phase-2.md)、[P2-04](phase-2.md)、[P2-05](phase-2.md) |
| WP-P2-PLAY | 四模式/试听/队列历史/最近/生产恢复，不重新造原生队列 | [P2-06](phase-2.md) |
| WP-P2-UI | 确认稿组件/手机桌面壳/真实本地后端、集中中文文案/IME；不静态假闭环或多语言首发 | [P2-08](phase-2.md)、[P2-09](phase-2.md)、[P2-10](phase-2.md)、[P2-11](phase-2.md)、[P2-12](phase-2.md) |
| WP-P2-LYRIC | LRC/纯文本/跟随/定位，不泛承诺逐字 | [P2-07](phase-2.md)、[P2-11](phase-2.md) |
| WP-P3-DAILY | Android焦点/蓝牙/授权/基础收藏歌单/返回、存储/扫描/IME最低支持边界，Win持续冒烟 | [P3-01](phase-3.md)、[P3-02](phase-3.md)、[P3-03](phase-3.md)、[P3-06](phase-3.md) |
| WP-P3-DISTRIBUTION | 首个对外Android包的ID/目录/渠道/用户保管签名、系统备份安全边界/手动安装回退；不默认自动更新器/多渠道或完整P5备份 | [P3-05](phase-3.md)、[REL-01](releases.md) |
| WP-P3-DIAGNOSTICS | 10最小本地导出/轮转/预览建议；不遥测，导出UI可明确延期 | [P3-04](phase-3.md) |
| WP-P4-CATALOG | 一个资料平台/搜索/partial/错误，无源可用；04网络提交/缓存边界 | [P4-01](phase-4.md)、[P4-05](phase-4.md) |
| WP-P4-ONLINE | 源管理/预算/匹配/解析/Broker/恢复，不全面多平台首版 | [P4-02](phase-4.md)、[P4-03](phase-4.md)、[P4-04](phase-4.md)、[P4-06](phase-4.md) |
| WP-P5-PLAYLIST | CRUD/批量/排序/复制合并/预览，不改系统角色 | [P5-01](phase-5.md) |
| WP-P5-DOWNLOAD | 严格档位/part/验证/标签副本/发布/入库/删除、预算/回收与发布锁序 | [P5-02](phase-5.md)、[P5-03](phase-5.md)、[P5-04](phase-5.md) |
| WP-P5-MIG | v1备份/恢复/Android定位/schema升级，不伪造缺失数据 | [P5-05](phase-5.md)、[P5-06](phase-5.md)、[P5-07](phase-5.md)、[P5-08](phase-5.md) |
| WP-P6-CATALOG | 五平台能力/榜单周期/歌单搜索导入刷新/详情 | [P6-01](phase-6.md)、[P6-02](phase-6.md)、[P6-03](phase-6.md)、[P6-04](phase-6.md)、[P6-05](phase-6.md)、[P6-10](phase-6.md) |
| WP-P6-ASSET | 来源链/缓存/拒绝/待写入/MP3FLAC/LRC/LX增强；引用保护与标签写入锁序 | [P6-06](phase-6.md)、[P6-07](phase-6.md)、[P6-08](phase-6.md)、[P6-09](phase-6.md)、[P6-11](phase-6.md) |
| WP-P7-MIG | Win同机全量/路径验证/并行/数据位置、受控复制分类/脚本禁用重验 | [P7-01](phase-7.md)、[P7-07](phase-7.md) |
| WP-P7-SYSTEM | 桌面词/多屏/托盘/键盘/DPI/休眠/输出/SMTC；外部文件输入归ENTRY | [P7-04](phase-7.md)、[P7-05](phase-7.md)、[P7-06](phase-7.md) |
| WP-P7-ENTRY | 保留Windows拖放导入/聚焦、生产实例排他；关联单/多文件播放是可选新增，不默认Android分享 | [P7-02](phase-7.md)、[P7-03](phase-7.md) |
| WP-P8-AUDIO | 短过渡/自动渐变/EQ/速度/频谱/降级 | [P8-01](phase-8.md)、[P8-02](phase-8.md)、[P8-03](phase-8.md)、[P8-04](phase-8.md) |
| WP-P8-DLNA | 本地MP3→在线/混队列/Stop/接管/自然结束设备规则 | [P8-05](phase-8.md)、[P8-06](phase-8.md) |
| WP-P8-QA | 大数据/资源/功耗/减少动画/可访问性 | [P8-07](phase-8.md)、[P8-08](phase-8.md) |
| WP-P8-RELEASE | 双端成品/许可/ABI/签名/升级/schema降级边界，非自动发布；复用P3首发经验 | [P8-09](phase-8.md)、[REL-02](releases.md) |
| WP-P9-CUTOVER | 关闭必需差距/并行试用/退回旧版/必要维护政策 | [P9-00](phase-9.md)、[P9-01](phase-9.md)、[P9-02](phase-9.md) |

共同约束保持：P2/P5/P6文件任务先按08 O冻结资源/锁序/等待与TC-58；P1不依赖这些生产锁任务。P1文件原型由P2-01正式适配替换/关闭，复用端口不双写。高级能力不支持如实进差距，原必需能力未过不能偷改N/A；旧版替换还需P9具体用户决定。
