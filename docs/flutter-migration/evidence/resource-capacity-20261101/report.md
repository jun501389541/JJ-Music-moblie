# A03/A05 双资源容量与12轮加载中停止

2026-11-01，AUTH-P1-CAPACITY-20261101限定目标完成。owner Codex串行双端/文档维护，分支codex/seek-boundaries。保留前批全部未提交seek/timeout验证；只新增resource_capacity_test.dart及证据文档，不改生产源码/依赖/UI、v2.3的21冻结或05摘要。未提交推送发布、改全局或旧Electron。

## 实际行为

同一平台测试先直接创建两个真实blocked读取资源，第三个原生prepare被拒绝；拒绝后样本集合仍只有原两个、没有第三gate。释放A后观察A closed/readers0，B仍blocked且cancelled=false；用刚才同一第三输入重试成功，样本集合为B/C；最后全部释放，原生samples空且三个gate关闭/读取数0。这证明所测2槽限额及释放后可重入，不是普通音频混音/双轨听感。

第二组使用同一共享coordinator/backend连续12轮初始门控加载，不放行数据：每轮真实blocked、bytesRead0、消费者1、确认0；Stop后等待消费者0/gate.closed/readers0/cancelled。晚allow后再等两轮新poll（最多一个poll可能在放行前在途），重新断言仍关闭、读取0字节，再记录。可见历史一直<=8，越过边界后仍可循环；最后普通自有输入真实确认、位置>300ms、累计确认恰好1，Stop消费者0。Windows逐轮注册新token，Android按唯一track id建gate，未在原生复制队列规则。

| 检查 | 最终结果 | 证据 |
| --- | --- | --- |
| Windows原生容量/12轮取消 | 2/2、约6秒、EXIT0 | windows-final.log |
| Android已选手机容量/12轮取消 | 2/2、约6秒、EXIT0 | android-final.log |
| 共同测试 | 51/51 | quality-final/tests.log |
| 格式/分析 | 49文件0变化/No issues | quality-final/ |
| 冻结/05/锁 | 原21摘要及权威哈希匹配，锁未改 | Quality检查 |
| Android普通入口恢复 | 原已验APK哈希一致；安装Success，COLD启动ok/PID25080 | install.log、android-start.log、normal-artifacts.json |
| 普通Release本批 | 两端均未重建；Windows普通窗口未重启；Android重装原包 | normal-artifacts.json |

观察保存在observations.json，含两平台容量最终host与12轮逐次gate/历史，完整原始事件见日志。它们是已执行的原生集成测试，不是假后端；但资源计数/历史边界不等同进程堆、系统句柄或平台内部缓冲检测，也不证明长期无泄漏。

首轮windows.log/android.log各2项通过。quality/分析发现多余dart:typed_data导入，失败日志保留；移除后，依限定审阅建议补late allow后的新快照断言，重新完整跑两端及quality-final。未缩短原超时、放宽容量或改旧冻结哈希来通过测试，生产代码未发现需要修复的缺陷。独立只读审阅无Critical/Important，处理一个快照Minor，setup失败前清理覆盖等限制见review.md；加强断言后由执行者复验，未再派审阅。

## 复跑与交接

具体命令见commands.md，cwd clients/flutter，两端分别运行integration_test/resource_capacity_test.dart；执行真实播放的一轮手机须保持已解锁/应用前台资格，本次起始主机ADB确认35a63609/2211133C/fuxi、Awake。仅自有固定12秒WAV，未访问私人曲库或真实源。test-hash.json记录新测试，不纳入旧公共合同冻结清单；Git前后文件范围、GraphFlow context/plan桥接及定向index记录可复核。

没有新UI或安装包功能；现有普通诊断程序仍可验收A播放、暂停/继续、定位3秒和停止资源0，手机已恢复原入口。源码预发布标签不变。A03—A08整体review/G-L仍未通过；下一小批建议A04 Activity重建与媒体控制并发，核同一engine/会话/资源及暂停不误恢复，再继续长后台/独立engine/输出失效/听感等剩余矩阵。并发接口或设备条件不足时按实际阻塞，不进入正式UI/P2/在线下载。
