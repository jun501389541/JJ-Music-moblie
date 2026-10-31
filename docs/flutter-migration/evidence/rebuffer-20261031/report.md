# A03 / TC57 Android播放后再缓冲：实际实现与验收

2026-10-31，AUTH-P1-REBUFFER-20261031。本批完成Android前台、已确认播放后真实再缓冲的4场景及受影响回归。旧Electron只读、独立mobile根、feat/flutter-a01-a02无HEAD/暂存/远端，原有工作保留。A03—A08整体仍review，完整G-L未放行。

## 实际实现

- `OwnedReadGate.kt`按每个DataSource的DataSpec.position限长读：明确前缀模式先给64044字节（冻结16kHz/mono/PCM16的44头+2秒），到边界才真正阻塞loader。allow后可继续读完整样本，cancel后不可复活。增加prefix/furthestPosition观测；原initial模式仍0前缀。
- `LocalHost.kt`只在显式自有content/tone-long?gate=rebuffer装上述门控及诊断用500/1000/250/250ms加载参数。普通输入/普通缓冲配置不变。增加白名单原生阶段/异常类别观测，不记录源地址/路径/秘密；增加只读前台条件查询，不绕锁或改系统。
- 新`android_rebuffer_test.dart`用真实NativeLocalBackend和同一共享协调器，先合法播放确认、位置>300ms，再观察原生BUFFERING/state2；自动恢复、pause放行后保持暂停、stop关闭读、新意图切B分别验。硬切完成由共享completeTransition处理，不放原生队列。
- 新测试只在自身Activity临时KEEP_SCREEN_ON，产出最小测试首帧后仍严格核interactive、未锁定和本窗口焦点，tearDownAll清flag。不是正式UI或普通程序新增按钮。

公共v2.2的20冻结文件、05、协议/快照1、依赖锁、fixture字节均未改，无新依赖或网络。Cancel(requestId)的既有pending/prepared语义不改；活跃轨读取的取消由Stop或新意图撤销测试，不把Cancel(active)偷改成Stop。[计划](plan.md)、[实际源码差异](source-diff.patch)、[文件摘要](source-manifest.json)、[完整命令](commands.md)。

## 实际结果及失败边界

| 检查 | 结果/证据 |
| --- | --- |
| 新能力RED | android-red.log退出1，4项缺新入口失败；不是原播放逻辑bug复现 |
| 首轮 | android-initial.log退出1，recover/pause通过；stop/new-play在首次确认前失败，尚未进入控制目标 |
| 原生诊断复现 | android-diagnose.log退出1；后两项明确play:ForegroundServiceStartNotAllowedException，screenInteractive=false，系统拒绝新FGS启动；前两项已证真实运行→缓冲，不把此后台资格失败写通过 |
| 前置检查纠正 | 用户解锁后，android-foreground.log在首帧前setUpAll焦点检查失败。最终在真实测试首帧后核同样严格条件，短时等待窗口焦点，不放宽条件；不把用户解锁回复直接当测试通过 |
| Android最终再缓冲 | [android-visible.log](android-visible.log)退出0，4项全部通过；真实前台、屏幕interactive=true，保留原始样本/确认/错误/读取时序 |
| Android旧路径回归 | [android-regression.log](android-regression.log)退出0，initial gate4 + service登记1，共5项；本批合计9个Android场景 |
| Windows实际回归 | windows-gate.log退出0、6项，windows-local.log退出0、3项；均独立Flutter进程。只证已有初始加载/关闭/本地能力，不证Windows播放后再缓冲 |
| 质量 | quality-summary.log退出0，quality/中锁/20文件及05哈希/格式通过，analyze无问题，39共享测试通过 |
| Android普通release | build-summary.log及build/android-build.log退出0，显式lib/main.dart；normal-install.log为Success，normal-start.log为Status ok/COLD、PID24031存在 |
| Windows普通release | 本批未重建/启动，避免把未改动源码当新编译；现有EXE哈希与上一批一致，见normal-artifacts.json，前批实际release证据保持历史 |

准确[退出码](command-results.json)与原始失败/成功日志分别保留。仅在本机/此指定35a63609小米2211133C、Android13/API33及固定样本验证；不冒充release门控运行、全设备、人工听感或完整后台矩阵。

## 关键时序与映射

最终每项先取得A的项目确认及位置推进，然后真实DataSource被卡在64044，Media3变state2、nativePlaying=false、playWhenReady仍true、position=2000ms。持续400ms后才派发控制；不是初始prepare等待或假事件。[结构化观测](rebuffer-observations.json)从原始日志提取，保留完整state序列。

| 场景 | 共享提交 | 观测恢复/关闭完成 | 实际后置 |
| --- | ---: | ---: | --- |
| recover | 无新增共享命令 | 810ms | 放行后同handle继续推进，同一个确认ID，不重记历史 |
| pause | <1ms | 1416ms（含固定观察与明确resume） | 放行到READY仍paused、位置不推进；明确resume才继续，确认ID保持 |
| stop | <1ms | 103ms | 旧读取取消、close调用结束；晚到allow不重新播放/增加确认 |
| new-play | 1ms | 407ms（也包含B确认等待） | B确认新增一次，共2；旧A通过共享transition完成后关闭，旧allow不复活 |

上述为单次本机受控观测，不是性能承诺。500ms阈值只约束同步提交，2.5秒约束停止/切换后的后端后置；recover无共享命令，不把noop计时当控制性能。原生状态3+实际位置推进与共享有效性才形成首次确认；缓冲及同轨恢复不重新签发确认。

## 审阅与未验证

[唯一限定独立审阅](review.md)未发现Critical/Important。审阅时测试前置在setUpAll；后来的首帧时机调整由执行者核对并实际复验，未伪称再次独立审阅。已知Minor仍保留：上游close异常时包装计数可能归零，closed仅表示close调用结束，非OS句柄独立证明；本批正常自有本地路径未诱发该异常，不改原验收门槛或宣称全提供方释放。

息屏后从已停止状态重新启动FGS已实际遇到系统拒绝，本批没有绕过它。既有播放存活后后台继续、系统媒体合法恢复等应按A04/07的明确资格逐项验证，不可由本批前台成功外推。Windows真实再缓冲、未知时长/不可seek、15秒自然超时、关闭异常、独立engine/服务回收、外设与人工听感仍待验；不放行G-L/P2/正式视觉。

## 用户怎样检查

手机已装回普通jj_music_mobile。打开“自有样本播放诊断”，播放A后位置前进、确认增加一次；暂停/继续不重复确认，停止后消费者归零。再缓冲门控是自动测试能力，不在普通界面造正式交互按钮。Windows普通程序路径仍为clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe，需保留整个Release目录。

当前APK及保留的WindowsEXE哈希见[产物](normal-artifacts.json)；Android仍内部debug签名，不是发行。本批旧仓库/全局设置未改，未提交推送发布。下一批建议A05等价播放后再缓冲实验，先核WinRT预读/可取消输入实际行为，不盲套Android的2秒配置；Android后台合法起播资格与其他生命周期缺口保持独立。
