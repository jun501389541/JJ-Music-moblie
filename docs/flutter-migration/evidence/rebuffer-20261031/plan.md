# A03 / TC57 Android播放后再缓冲

2026-10-31，AUTH-P1-REBUFFER-20261031。Codex串行兼Android、A02维护、ConfigIntegrator和文档协调；mobile根，旧Electron只读。GraphFlow context和plan成功；服务无LLM密钥时已完成intent/decomposition submit+merge，使用自分解计划而非启发式占位节点。按实际源码/最新status/handoff/任务索引/归属/05/条件分支核对，不用历史before锚点冒充当前代码。

消费R4/v2.2共20冻结文件、协议/快照1，开工核全部摘要。只改LocalHost、OwnedReadGate、新android_rebuffer_test及证据/status/handoff。无依赖、fixture或公共合同变更。Windows源码不改，仅既有原生回归；普通WindowsRelease保留前批程序，不为Android专属改动打断用户窗口或冒称本批重新构建。

## 设计和顺序

1. 先写4个真机用例：recover、pause、stop、new-play，保存尚无新入口的RED。
2. 自有冻结PCM16/mono/16kHz/12秒WAV按绝对DataSpec.position提供64044字节（44头+2秒），然后在真实loader read等待。显式?gate=rebuffer才启用；原?gate=initial仍零前缀，普通路径不门控。
3. 仅这条诊断路径设置Media3加载缓冲500/1000/250/250ms，使前缀可先开始播放；不是正式音质/重试/队列策略或普通缓冲参数变更。依据[DefaultLoadControl.Builder](https://developer.android.com/reference/androidx/media3/exoplayer/DefaultLoadControl.Builder)，实际固定1.11.0编译/运行复证。
4. 必须先合法项目确认一次、实际位置>300ms，再观察真实Media3 state2/原生不运行、读取仍blocked，保持400ms；不靠初始buffering或假事件。
5. 自动放行应继续推进、沿用handle和确认；缓冲中pause再放行应保持paused/位置稳定，明确resume才前进，同一确认。stop或新意图须实际取消旧读，晚到allow不复活，切B只新增B确认。P1硬切的completeTransition仍由共享协调器完成。
6. 取消活跃读取通过Stop/新意图测试，不改变现有Cancel(requestId)只针对pending/prepared的语义，不把对已确认active的Cancel改成Stop。
7. Android新增/初始加载/服务登记及必要本地回归、Windows既有gate/local独立进程回归，Quality及普通Androidrelease/安装；Windows本批真正再缓冲仍未验。每项保存失败/成功原始日志与退出码。
8. 唯一独立只读审阅，范围/实际偏差记普通文档，再更新status/handoff、定向index，不自动进P2/网络/正式UI或提交。

## 验收边界

新场景不能仅在prepare一直pending时测控制；必须完整运行→buffering序列。阈值500ms约束共享提交，2.5秒约束旧读退出/必要新轨确认，不是性能承诺。现有readGates.closed仅表示close调用结束，关闭异常/OS句柄独立证明仍未验，不扩大声明。prefix基于已冻结样本，不宣称通用媒体流格式。真实音频在同一指定手机35a63609执行，不访问私人媒体，不用静音保活。

Git无HEAD，沿用工作区并保存before/哈希/补丁，不建立依赖提交的worktree或执行提交脚本。若实际不能诱发则保留未验/实验结论，不能伪造state2。最终结果见report.md。

## 实际调整和结果

- 初轮及带诊断复现均是recover/pause通过，stop/new-play在首播前被系统拒绝FGS；新增的白名单错误分类确认为ForegroundServiceStartNotAllowedException、手机息屏。不把该错误改成后台可启动通过，用户解锁后限定前台复验。
- 首次严格前置检查位于setUpAll、实际首帧前失败；改成测试绘制最小真实诊断首帧后核相同条件，短时等待focus，不降低条件。KEEP_SCREEN_ON仅测试窗口，tearDownAll清除。审阅之后这一测试装配调整由执行者自检/真机证明。
- 最终前台4个再缓冲场景、Androidinitial4/service1、Windows既有gate6/local3均通过；Quality39共享/20冻结及05/锁/格式/分析通过，普通Androidrelease重建/安装/COLD启动通过。Windows源码/EXE与前批一致，本批未重新构建普通WindowsRelease。
- 取消active读取使用Stop/新意图，未修改Cancel(active)语义。既有close异常计数Minor保持延期，不把wrapper计数外推为OS句柄证明。
