# 单轨存活后端的协调器替换设计

2026-11-06，A07/A02，设计提案，尚未实施。接续[边界核查](../A08/20261106-r2-boundary.md)。本批owner Codex串行合同设计/文档维护；实际基线codex/seek-boundaries / ee0e3471955750315fe945f2b4f057a79b21f5de。当前冻结仍p1-a02-v2.3、协议/快照1，不更改任何旧摘要。

## 目标与范围

同一个Dart isolate及NativeLocalBackend仍活，旧协调器能够合作退休时，创建不同对象的新PlaybackCoordinator，保持唯一已确认活动轨的物理资源、位置推进和确认凭据，不额外prepare/play。此实验只覆盖合作式对象替换，不证明旧协调器异常死亡、跨engine接管或无缝听感；不能将结果扩写为完整R2通过。无法可信接管时沿[05 C-03](../../05-architecture-contracts.md)的暂停恢复退路。

## 方案比较

| 方案 | 价值与代价 | 本批选择 |
| --- | --- | --- |
| 保留旧协调器，仅acquireController换owner | 已有低成本CAS，但没有新协调器对象，不能验证重建 | 不作为本批实现 |
| 同isolate同步替换协调器，保留backend | 不新增原生业务；可以精确控制转移点及事件围栏；依赖旧对象合作 | 推荐，工程选择待设计评审 |
| 跨engine原生存活注册/接管 | 接近异常engine死亡场景，但必须另建跨边界身份、权威和重连协议 | 后续单独设计，本批不扩展 |

选择同isolate范围是执行者建议，不记为用户已经批准新协议。共享实现遵守[归属流程](../../tasks/contracts-ownership.md)，不新增原生队列/随机/重试逻辑。

## 拟议入口与不变量

在PlaybackCoordinator新增窄入口`handoffSingleTrack({required ControllerClaim expectedClaim, required String newOwner})`，返回包含新协调器或明确拒绝原因的结果；具体类型由实现阶段统一于共享合同。它不是可序列化快照、可重用token或任意对象导入接口。调用者不能提供伪造的native handle或私有Track对象。返回成功后旧对象永久退休；它的dispose只能清理自身订阅，不能释放已转移轨。新对象dispose仍按真实释放语义处理轨道。

新对象保留backend引用、session、backendEpoch、generation、queueRevision、队列/模式/试听、当前条目、位置/时长、确认列表及计数；明确保留活动轨PrepareRequest/PreparedTrack身份、canSeek、最后eventSequence与confirmation，避免用公开TrackSnapshot丢失请求和定位能力。新owner不同且非空，coordinatorEpoch严格增加，eventCursor递增，UI重新订阅；不改backendEpoch或重发play。ack缓存按新epoch重新开始，旧claim在新旧对象均不可执行控制。

只有一个已确认active且未revoked的轨道可接管；允许desired playing或paused。必须没有pending/preparing/waitingPrepare、容量timer、incoming/outgoing/prepared/retiring资源、release timer以及尚未结束的后端控制操作。已释放历史轨道不转移。队列当前entry和资源entry须对应，确认须包含于确认列表。任何不匹配返回拒绝，不修改owner/epoch/订阅/资源，不自动停止仍合法的旧播放。

当前代码没有在途pause/play/seek操作的统一计数，因此实现时必须先补内部派发计数及finally清理，覆盖同步throw和异步失败。不能仅检查pending prepare就宣称稳定。计数须覆盖所有后端Future入口及其回调收尾，包括prepare、cancelPrepare、play/pause/seek/stop和直接调用的release；尤其released事件可能先于release Future完成，不能依据TrackRole.released就放行。计数在then/onError的业务处理完成后才finally减回，迟到_acceptRelease也须检查退休围栏。只要计数非零，本入口返回busy；旧运行不被破坏，稍后由调用者明确重试，无自动无限循环。

## 转移点与事件顺序

为避免转移时重新listen的异常和事件间隙，采用一个同isolate内部事件路由槽：首次协调器创建时只建立一次backend.events订阅，数据和onError回调均读取槽的currentAuthority；新协调器不再listen。路由槽不保存队列或业务决策，仅指定唯一事件接收者。它不是跨engine注册服务。

入口同步校验完整expectedClaim、路由槽仍指向当前对象及稳定条件，创建新状态容器但不注册新订阅；所有可能失败的准备完成后进入不调用外部代码的提交段，标记旧对象retired、交出其资源所有权并交换槽的currentAuthority，最后返回新对象。中间不await、不访问磁盘、不派发native操作，没有Stream取消/重订阅窗口。相同isolate中事件不会插入无外部调用的同步提交段；转移前已分派的事件由旧对象完成，之后由新对象处理，并沿活动轨sequence去重。

旧对象dispose只退休自己，不能取消共用路由槽或释放转移轨；新owner dispose先使槽停止派发，再取消唯一订阅并按现有语义释放轨。重复旧dispose、新旧close顺序及onError需测试。首次构造的listen失败仍走现有初始化失败清理，不变成转移中半提交。共享订阅所有权作为内部新结构明确实现，不借用旧对象作为永久转发协调器；旧对象可被回收。

活动轨的原请求generation保持不变，因此真实后端后续事件仍能通过身份核验。sequence<=转移时最后值的重复事件拒绝，之后progress/playing只由新对象处理；playing不新增确认。自然结束、错误、revocation和stop由新对象唯一决策。旧对象的completeTransition/revokeResource/backendReleased/acquireController/命令入口及迟到Future均须退休围栏，不能只检查旧claim命令路径。

## 运行时接线

LocalRuntime目前coordinator为final，而systemCommands、镜像和保存均经该字段读取。改为私有可替换引用及只读getter，通过runtime窄入口在同一同步调用中发布新对象。backend、store、writer锁、轮询timer、系统命令订阅及request计数保持唯一；禁止另建LocalRuntime争同一writer锁。低层handoff仅供runtime包装及独立协调器测试使用，UI和系统命令不得直接调用；包装必须在同一同步调用中取得成功结果并更新引用，再通知观察者。新增断言验证替换后的系统pause/stop和close只作用于当前权威。发布后旧UI连接失效，新连接取snapshot；UI不得保存旧对象作为权威。原LocalRuntime.close和R3读盘恢复语义保留。

运行时入口还须拒绝_closed、_mirroring、save进行中或销毁后端进行中的调用；为save和destroyBackend加明确busy状态，防旧快照/镜像在转移后才落地或旧销毁操作作用于新权威。拒绝不排队、不隐式重试。初始化和清理失败须finally清除忙标记，已closed则永久拒绝。

不将磁盘save纳入同步提交；存活状态为本次接管权威，历史落盘位置不能覆盖它。新协调器后续save沿现有store修订继续，快照格式无需新增native handle/claim；任何协议版本变动在实现前按A02维护步骤落入05及新冻结记录。

## 失败、取消与并发验收

| 输入/时机 | 预期 | 验证层 |
| --- | --- | --- |
| 已确认单轨playing或paused | 不同对象、新owner/epoch，同backend/资源/确认；无新增prepare/play/release | 共同测试及双端真实测试 |
| 旧claim、旧dispose、旧revoke、旧transition回调 | 不控制或释放新权威的资源 | 共同测试，真实测试核stop前资源仍活 |
| 重复playing/旧sequence及随后progress | 去重、拒旧、位置只由新对象推进 | 共同测试与真实native新采样 |
| pending prepare、双轨、retiring、revoked、在途seek/pause | 返回明确busy/unsupported；旧对象状态/控制仍有效 | 可控Future单测 |
| released事件先到、release Future后到 | Future及回调收尾前仍busy，迟到回执不修改旧权威或新资源 | 可控Future单测 |
| 两次接管连续调用或使用旧claim竞争 | 仅第一次可成功；第二次拒绝，无双订阅业务执行 | 共同测试 |
| 转移前stop或取消意图先执行 | 不复活，转移拒绝；该入口同步无可中途取消Future | 共同测试 |
| 转移后stop | 新对象唯一释放；实际released后归零 | 共同测试及分端真实集成 |
| 实际资源死亡/身份不符/订阅故障 | 不声称无损，显式记录失败并按可证资源状态暂停恢复 | 故障测试，未覆盖部分保留review |

真实测试先保存有意落后的2345ms快照，再播放推进并转移；证明新对象位置来自存活状态、同一backend实例及未释放的资源，而非重新prepare。原生观察窗口前后保留新采样、确认一次，最后显式stop确认资源空。它仍不能证明连续硬件静音/无缝听感。Android仅已选设备解锁时运行，Windows独立；均须备份并恢复普通产物。

## 实施归属及分批

批准设计后由同一A02/A07维护者串行更新05的窄合同、coordinator及必要共享类型、LocalRuntime和共同测试；冻结变化产生新版本，原21文件旧摘要保留，不原位刷新历史哈希。新增单轨handoff测试先观察失败，再实现最小路径。共同检查通过后，真实集成测试分别消费新冻结；无双端结果只能保持partial/review，不能完成G-L。

预计代码范围（本批尚未改动）：lib/domain/playback/contracts.dart、lib/application/playback/playback_coordinator.dart、lib/app/runtime/local_runtime.dart、test/playback/coordinator_handoff_test.dart、integration_test/coordinator_handoff_test.dart（均相对clients/flutter），05、A02新冻结、证据及status/handoff。暂不修改NativeLocalBackend/原生文件或依赖；如订阅/在途操作审计发现必须扩展，先记录实际原因及范围。共享冻结检查脚本如需选择新清单，归ConfigIntegrator串行整合，不把哈希检查关掉。

本批只形成设计；文档检查日志与定向索引同目录保存。未实施、不运行设备、不提交推送，既有未提交修改全部保留。

独立builder check已完成，返回的全Future收尾围栏与runtime唯一包装入口两项均已纳入本设计。审阅是静态设计检查，不是实现或设备验收；记录见review.md。
