# A02/TC57 v2.3 定位能力及明确拒绝

用户继续P1授权，Codex串行兼A02维护/双端消费者/ConfigIntegrator。保留前批全部未提交修改；不提交/推送/全局修改/旧Electron写入/UI或P2扩展。当前冻结p1-a02-v2.3，21文件，旧v2.2 JSON和摘要保留。05只追加增量，协议/快照格式仍1；新能力不持久化。

PreparedTrack新增必填bool? canSeek，绑定单条准备资源；原生适配在ready采样真实canSeek，缺失为null。所有构造消费者已补齐；受控fake/入口自检显式true。共享seek仅明确true时接受，false返回seek-unsupported，null返回seek-capability-unknown。在取消prepare、generation/position变化、释放及原生派发前拒绝；applied仍是短提交接受，非原生定位完成。原生自身能力检查继续保留，能力后续动态变化不由当前准备快照保证；恢复目标无法定位仍走既有原生失败退路，不偷偷丢弃目标位置。

## 实际证据

- red.log：Windows两个不可定位PCM场景，共享seek原先applied=true，2项真实反例失败；先于实现。
- unit.log及quality/tests.log：三态新用例加共同回归42项通过。拒绝保持actions、generation、position和confirmations；true会派发定位。
- windows.log：未知/已知但不可定位的PCM两项通过，新增共享拒绝及位置/代次不变检查，原生拒绝/恢复/EOS/释放断言保留。
- android.log：unknown-natural/unknown-stop/known三项通过；未知输入共享拒绝，已知WAV共享定位3秒仍正常。首帧因原手机Dozing等待；用户确认解锁后原运行继续并全部通过（约2分50秒），没有重跑掩盖、绕锁或改系统息屏。
- quality/：21冻结文件及05摘要/锁依赖、格式、静态分析及42共同测试通过。
- windows-local.log：Windows普通文件正向定位/共享合同回归；最终退出码见日志。
- release/和normal-artifacts.json：两端普通入口构建及启动/安装记录，未执行的人工操作不算通过。

新旧冻结是不同版本，不更新旧哈希来假装无漂移；check.ps1显式切到新清单。新增三态单测也纳入冻结。source.patch为本批共享代码差异；当前真实输入的原生能力来源仍引用前两批报告，不重复实现原生规则。

限定只读审阅未发现Critical/Important。覆盖限制见review.md：没有单独桥接缺字段测试、没有构造第二轨/待prepare的拒绝用例，副作用顺序由代码静态确认；不把这些边界称为动态验收完成。整体A03—A08/G-L仍review，动态能力/资源压力/自然超时/长后台及外设听感仍有缺口。

普通界面仍播放自有12秒WAV，可检查播放A、定位3秒、暂停/继续、停止资源0；未知/不可定位输入仍为专属自动化入口，未包装正式UI。下一小批建议补拒绝时并发prepare/第二轨隔离及原生缺能力观测的桥接反例，再推进剩余超时/恢复矩阵。无真实源、个人曲库或发布。
