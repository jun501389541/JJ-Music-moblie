# A03：Android未知时长/不可定位顺序PCM

2026-10-31，AUTH-P1-ANDROIDUNKNOWN-20261031限定目标完成。owner Codex串行Android/ConfigIntegrator/文档协调；共享R4/p1-a02-v2.2、20摘要、协议/快照1不变。HEAD86053e5，上一批Windows全部未提交代码/测试/文档保留；本批不提交/推送/发行，不改旧Electron、全局、工具/依赖或正式UI。A03—A08整体仍review，G-L未过。

## 输入、实现及边界

新增OwnedPcmStream.kt和android_unknown_duration_test.dart，LocalHost接入显式自有/tone-pcm并记录实际原生能力。未新增媒体、编码器或网络。现有冻结WAV的PCM16/mono16k载荷经本机asset流读取，验证固定头后只暴露头后样本；DataSource只支持初始position0/length unset，向消费者返回C.LENGTH_UNSET，不给出WAV长度/文件头。不是把既有WAV播放器返回值强改为未知。

专用Media3 Extractor仅作100ms rawPCM样本framing及时间戳，使用原ExoPlayer/音频renderer，SeekMap.Unseekable(C.TIME_UNSET)。DataSource在loader读取，非平台控制线程；没有producer写线程、私有目录扫描或原生队列/重试。既有门控只在该输入供2秒PCM后等显式放行，诊断小缓冲250ms起播；避免EOF已经到达并被Media3推导时长后才做未知证明，不改普通WAV或既有gate参数。

poll新增私有诊断canSeek/isCurrentMediaItemSeekable及nativeDuration/p.duration；真实不可定位时native seek在改变位置前抛UnsupportedOperationException。仅原生能力观测和拒绝，不是共享seek能力协商/命令ack拒绝或正式UI禁用已完成。共同端口和冻结文件未改。

依据：[官方Media3组件定制](https://developer.android.com/media/media3/exoplayer/customization)、[DataSource API](https://developer.android.com/reference/androidx/media3/datasource/DataSource)。实际编译使用已锁定Media3 1.11.0，API抓取的cache miss没有当作成功；不靠另一平台或单个bool证明Android播放。

## 实际结果

| 检查 | 本批结果 | 证据 |
| --- | --- | --- |
| 新测试先失败 | 缺unknown入口/known能力字段，0/2，EXIT1 | red.log |
| 首次新输入及已知对照 | 2/2，EXIT0 | attempt-1.log |
| 最终新增：未知自然结束/等待中停止/已知WAV | 3/3 | final-android.log |
| 原普通本地/content URI及定位/资源 | 3/3 | 同上 |
| 原服务销毁/满队列/旧销毁新注册/后台控制 | 4/4 | 同上 |
| 原播放后再缓冲 | 4/4 | 同上 |
| Android不同场景合计 | 14/14，约1分35秒，EXIT0 | final-android.log |
| 格式/静态分析 | 44文件0变化/No issues | quality-final/ |
| 共享测试 | 39/39 | quality-final/tests.log |
| 冻结/05/依赖锁 | 20摘要及权威哈希一致，锁未变 | baseline及Quality/Release检查 |
| 普通AndroidRelease | 构建15.7秒；安装Success，COLD启动ok/PID14824 | release/android-build.log、install.log、normal-start.log |
| Windows本批 | 生产代码未改，未构建/启动/运行；现有EXE保留 | normal-artifacts.json、前批unknown-duration-20261031 |

真实观测见observations.json：未知自然/停止两场景首次确认后position380/309ms、nativeDuration=-9223372036854775807(TIME_UNSET)、duration0、canSeekfalse；已知WAV position308ms、duration12000/canSeektrue且定位3秒成功。未知定位9000返回android-local/UnsupportedOperationException，位置未跳到目标；暂停恢复共享确认仍1。

未知自然场景放行后读完整384000字节PCM并出现真实ended；未知停止场景读取阻塞于64000字节时接受Stop并取消loader。两项最终input opens1/closes1/active0/closeErrors0，门控readers0/closedtrue，共享消费者0。同步Stop接受<500ms只是短提交证明；原生/输入关闭另等观测，没有测得资源释放<500ms的承诺，不把这些计数当独立OS句柄检测。

EOF后Media3根据末样本推导nativeDuration=11910ms，而不是继续TIME_UNSET。本批证明EOF前未知，不宣称永远未知，也未证明末尾推算时长精度。普通12秒WAV仍12000ms。

首轮Quality在两处if缺花括号的lint info上失败，quality/analyze.log保留；仅补语句块，不改变控制流，最终quality-final全过。14项真机运行在这两处纯样式修正前，未重复整套手机测试；最终构建/分析/格式在修正后执行。没有删失败日志、降规则或改冻结哈希。

限定只读审阅无Critical/Important，Minor按上述计时边界明确记录，见review.md。source.patch对本批before原生基线；新源码/测试及hashes.json、设备environment.json可复核。GraphFlow定向结果见index.log。

## 简单验收及剩余任务

手机已恢复普通“JJ-Music 技术诊断”入口。进入自有样本播放诊断：A进度应增长；暂停/继续有效；普通样本“定位3秒”仍可用；停止后资源0。本批未知输入是专属自动化测试，没有给正式界面添加开关。可在clients/flutter终端复跑commands.md新测试，应3项通过；不用个人曲库。

当前APK在 `clients/flutter/build/app/outputs/flutter-apk/app-release.apk`，内部诊断签名，非发布包；哈希/大小见normal-artifacts.json。Windows继续使用前批Release整个目录，本批不代验或要求重装。

下一小批建议A02/TC57共享层定位能力及明确拒绝回执：先按05/归属确定最小增量及冻结/消费者验证，再实现，避免明知原生不支持而共享只回applied。当前不静默改已确认端口。自然15秒超时/资源压力、长Doze/独立engine与系统杀进程、外设/物理媒体键/听感等仍开放；不自动进入P2、在线/下载或正式UI。
