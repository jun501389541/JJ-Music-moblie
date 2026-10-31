# 下载后台与执行合同（D）

分类P/H；B07/B08风险探针，P5完整实现。保留PR-09/13/21/22。现有Electron下载退出中断并可断点重试，不是Android后台能力证明。

## D-01：职责

系统调度取得运行机会；RuntimeHost持有所需Dart运行时；DownloadCoordinator决定源、档位、重试/发布/入库；TransferExecutor只执行获授权字节传输。

优先复用可靠组件。传输器可为共享Dart IO经受控Transport，也可为经验证的原生组件；**不因设计合同就强制自建一套Kotlin/C++下载器**。Dart可直接消费Broker内部受控流；原生需要本机端点时使用其消费者令牌，不拿rawURL绕过安全。两者不能同时写同一part。

## D-02：独立运行资格

Android用户主动长下载优先验证API34+ UIDT，旧系统验证WorkManager前台长任务退路；可延期短任务用WorkManager。调度/通知/启动条件受OS约束，不播放静音音频、不冒用mediaPlayback保活。[官方选择](https://developer.android.com/develop/background-work/background-tasks/data-transfer-options)、[UIDT](https://developer.android.com/develop/background-work/background-tasks/uidt)。

WorkManager长任务也有生命周期与配额，不是永久保活；Android16有长任务配额边界；dataSync前台服务按目标系统处理限制。[长任务](https://developer.android.com/develop/background-work/background-tasks/persistent/how-to/long-running)、[FGS超时](https://developer.android.com/develop/background-work/services/fgs/timeout)。

RuntimeHost有独立downloadRef；无播放仍由下载自己的任务持有。UI消失不释放；播放停止不结束下载/共享来源；系统收回资格时检查点/中断，不靠计数强行存活。后台入口复用唯一权威运行时，不为每个Job创建第二套协调器/DB。

## D-03：存活矩阵

| 事件 | 行为 |
| --- | --- |
| 页面/Activity重建 | 重新订阅原任务，不重建执行 |
| 停止播放/音频服务结束 | 下载自己的资格与持有继续 |
| 协调器重建但执行存活 | 排他接管快照，禁止重复执行 |
| engine/Broker丢失 | 中断流，保留已验证part；合法调度重建后恢复，不假报持续下载 |
| 进程回收 | 从持久任务/实际文件/日志恢复；不可依赖回调必达 |
| 用户强制停止 | 尊重停止，不自动复活 |
| Windows托盘隐藏 | 当前进程可继续 |
| Windows明确退出 | 检查点并停止，不默认增加常驻服务/BITS；关闭仍按既定偏好 |

UIDT用户Stop可能直接杀进程且不调用onStopJob；定期持久化，不能只靠退出回调。

## D-04：持久任务与执行凭证

持久taskId与业务身份；attemptId一次重试/重解析；executionId实际传输；ownerEpoch权威协调；transferEpoch写入fencing；eventSequence；publishOperationId幂等发布。短期URL/token/头不入持久记录。

UI/通知/系统重复唤醒合并为一个有效attempt。调度唯一名不足以防重复；part需排他写入。心跳超时不等于旧执行停止；新执行前要停止确认或确认进程死亡/文件锁释放。旧epoch不能写/发布/提交终态。

## D-05：URL更新

传输错误→关闭流→保存实际长度/验证器→needsResolution→共享协调器按原身份/严格档位重新请求当前源→校验新旧表示→签发新资源。

来源内容修订变化清旧part；仅运行实例变化先重获授权，是否保留字节需验证器/表示证据。歌名/ID/相同总长不足以追加；无法证明则重写。200忽略Range重写，206范围错误拒绝。源不可用等待明确恢复，不无限重启；预算和429重试有界。执行器不运行JS或自己换平台。

## D-06：单写入者

- Dart业务DB：任务策略/修订、来源、验证、发布/入库。
- 有效执行器：仅获授权part字节及独立有界执行日志。
- 没有DB写入者时原生保留日志，不打开另一套业务DB。
- 实际文件长度校验检查点；不能信日志offset超出文件。
- 发布/标签/入库由共享层幂等编排；文件和DB非共同原子事务，用日志恢复。

## D-07：取消/暂停/完成

Pause/Cancel携带task/attempt/execution/fence，幂等；先失去后续发布资格，再实际终止解析/网络/文件写，确认后可新执行。用户暂停保留可用part，取消是否清残片按显式选择；系统中断不当完成。停止播放不发送下载Cancel。

完整管线：strict解析→有界part→容器/规格/长度验证→stage→标签副本（失败保音频及warning）→独占发布/同名编号→sidecar不覆用户文件→下载完成→独立入库/只重试入库。源URL扩展名不可信，低档文件不能冒充所选档；删除/回收与扫描/入库互斥。

## D-08：P1与P5边界

B07/B08只用自有受控文件证明无播放后台、页面/engine/进程中断、一次过期重解析、重复唤醒/排他写入、单DB；不实现完整下载UI或标签系统。G-D通过不表示生产下载通过。P5再展开全部文件/质量/发布/迁移/删除竞态任务。
