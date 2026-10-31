# A03 / TC57 Android初始持续加载：实施与证据

2026-10-31；AUTH-P1-LOADING-20261031。本批只补Android初始持续加载反例及A05既有回归，不表示完整A03/A05/TC57或G-L已通过。开发根mobile，旧Electron只读；Codex串行承担Android、A02维护、ConfigIntegrator和文档协调。Git feat/flutter-a01-a02、无HEAD/暂存/远端，已有未提交工作保留。

## 实际代码

- Android `LocalHost.kt`：只在明确自有/tone-long?gate=initial内容URI上装门控DataSource.Factory；新增gatedFixtureUri/allowOwnedRead诊断方法和有界readGates观测；release先唤醒取消再调用ExoPlayer.release。普通播放不启用门控。
- 新 `OwnedReadGate.kt`：真实loader线程read等待，控制线程只发信号；既有DefaultDataSource读自有WAV，取消后allow不能重新启用；等待预算15秒、历史最多8项；同步记录读取者、字节、等待和close调用。没有fake状态、网络或静音保活。
- 新 `integration_test/android_loading_test.dart`：4个Android专属场景，共用现有协调器与公共断言；增加控制提交及观察到close的时序、控制前原生快照、原始样本输出。

共享v2.2的20文件及05权威哈希保持一致，无公共接口、协议/快照格式、锁文件或依赖变更，不需要重写冻结。原生没有新增队列、随机、重试或音质业务。[计划/前置/范围](plan.md)、[实际源码差异](source-diff.patch)、[文件摘要](source-manifest.json)。GraphFlow返回的历史before锚点只作定位提示，实际读当前源码。

## 已执行结果

| 检查 | 实际结果 |
| --- | --- |
| 起点/设备 | 冻结20摘要匹配；35a63609、Xiaomi2211133C/fuxi、Android13/API33，与已选设备一致；普通屏幕可能自动Dozing，本批非UI测试不绕锁屏 |
| 先行RED | [android-red.log](android-red.log)退出1，4失败，原因为尚无gatedFixtureUri新方法；这是新能力缺失，不是已复现旧播放器bug |
| 初轮实现 | [android-initial.log](android-initial.log)退出0、4项通过；是真实Media3 state2与实际阻塞read |
| Android最终 | [android-final.log](android-final.log)退出0、11项通过：加载4、本地3、焦点3、生命周期1；默认debug原生运行 |
| Windows | [windows-final.log](windows-final.log)退出0、3项真实原生本地用例通过，含共享身份/控制/资源释放、确认前失败回滚和自然结束/坏文件；没有Windows延迟输入实验 |
| 公共质量 | [final-check-summary.log](final-check-summary.log)与final-checks/：20冻结及05哈希/依赖锁/格式通过，analyze无问题，39共享测试通过 |
| 普通release | final-checks/android-build.log及windows-build.log均退出0、普通lib/main.dart构建通过；normal-install.log为Success，normal-start.log为Status ok/UNKNOWN，PID4756存在。只记命令启动，非普通UI人工验收；本批门控运行仍是debug，不称release门控实测 |

完整[命令](commands.md)及[退出码](command-results.json)与日志分开保存。旧报告/日志不覆盖；没有把runner输出尾部命令的退出码当测试退出码。

## 真实读取与控制时序

增强版最终测试每次先观察blocked=true、readers=1、bytesRead=0、Media3 state2，持续至少650ms、没有项目播放确认，再派发命令。[原始数据提取](loading-observations.json)保留PID、控制前快照、控制后门控与原生状态集合，原始记录仍在android-final.log。

| 场景 | 共享命令提交 | 观察到上游close调用结束 | 实际不变量 |
| --- | ---: | ---: | --- |
| pause | 7ms | 1338ms（包含后续允许/继续/停止） | 放行read后仍paused且零确认；明确resume后一次确认，再暂停/继续不增加 |
| stop | 25ms | 129ms | 旧请求取消、零字节、关闭调用结束；晚到allow不重新确认 |
| cancel | 4ms | 110ms | 请求级取消不等旧读取完成；旧allow不复活 |
| new-play | 8ms | 431ms（也包含新曲确认等待） | 旧读取退出、新普通曲确认一次；不等15秒门控预算 |

实际原生累计等待837/895/859/863ms（对应上表顺序）；字节/ready/播放确认都来自真实后端链，非仅改变Dart快照。500ms阈值约束同步共享提交；2.5秒阈值约束stop/cancel/new-play后观察到close及必要新曲确认，两者不混称原生执行耗时。这些是本机一次受控时序，不是性能承诺。

## 审阅与证明限制

[唯一独立只读审阅](review.md)未发现必须阻断本批集成的重要问题。非阻断Minor延期：close异常时计数仍在finally归零，closed=true只能证明close调用结束，不能证明close失败反例或OS句柄级独立关闭。本批正常自有本地场景未诱发该错误；后续补closeError/故障用例，不将本计数提升为全提供方释放证明。Windows自身文件rename释放证据来自其独立测试。

仍未验证：Windows真实持续加载；已经播放后的再缓冲；未知时长/不可seek提供方；15秒预算自然到期；门控open/close故障、历史淘汰压力与OS独立句柄证明；独立engine/服务回收、焦点外设与人工听感等原G-L缺口。本批没有修改原门槛、删失败用例或冒充N/A。

## 怎样检查成果

普通界面保持技术诊断。手机打开jj_music_mobile→打开自有样本播放诊断；播放A应位置前进/确认一次，暂停停住，继续不重复确认，停止消费者归零。Windows普通程序仍位于clients/flutter/build/windows/x64/runner/Release/jj_music_mobile.exe，必须保留整个Release目录。当前构建/安装结果与哈希见[普通产物](normal-artifacts.json)；本批不声称普通UI人工按钮及听感验收。

本批门控为自动测试入口，不增加正式界面按钮。开发者在clients/flutter执行commands.md中的android_loading_test命令，预期4项通过并打印各场景原始记录；会临时替换诊断包，结束需按同页重建/安装普通lib/main.dart。只能使用已选手机和已冻结自有样本，不导入私人曲库。

下一批建议A05 Windows等价本地受控读取实验，先核真实WinRT可取消输入能力，再消费同一共享语义；Android剩余再缓冲/未知能力独立补证。不提前实现网络Broker、不进入P2/正式UI。状态/交接将本批子目标与完整G-L区分；不提交、推送、合并或发布。
