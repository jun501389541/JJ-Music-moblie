# 销毁失败安全退路修复（2026-11-06）

AUTH-DESTROY-FAILURE-20261106；用户继续执行开发，接续runtime busy批次的明确缺口。owner Codex串行A07/A02/ConfigIntegrator；codex/seek-boundaries，基线ee0e3471955750315fe945f2b4f057a79b21f5de。本批旧修改全部保留，不改旧JJ-Music、依赖或全局配置，不提交推送发布。

## 已复现问题与修复

受控MethodChannel首次release抛错、资源保持存活。原LocalRuntime.destroyBackend finally清_destroying后仍允许handoff成功，接管不可信资源；NativeLocalBackend._closeHandle永久缓存失败Future，明确重试也不再调用native release。red.log同时记录两项预期行为失败；清理也因同一失败缓存使close中断/写锁未关闭，留下两份该测试自有失败run目录。没有删除这些失败输入或个人数据；不是实际Android/Windows原生故障。

修复：runtime从开始销毁即锁存backend不可信；失败提交暂停意图、保留原异常及不可信状态，不增长backendEpoch/不伪造released。handoff和起播/切轨/seek拒绝，仅完整销毁receipt被共享协调器接受后解锁。物理暂停没有底层证据不能宣称完成；暂停派发失败亦不解除不可信围栏。

薄backend保留失败资源与retiring状态、清播放意图/证据；在release失败时清除失败attempt缓存，下一次明确清理调用才可重试幂等release。未完成同一次attempt仍共用Future，不自动循环，不在失败时删除消费者或返回成功receipt。本批验证单轨失败恢复；多资源部分销毁若无法核对完整receipt则继续不可信，不能猜测成功，需R3退路，未承诺该矩阵自动恢复。

05新增安全补充，A02新[p1-a02-v2.5](../A02/20261106-destroy-failure-freeze.md)记录26文件+05摘要；原v2.4清单不改，协议/快照格式仍1。新清单包含新故障测试及其NativeHost helper，检查选择器串行切换；初始本批清单freeze-initial.json保留，之后只修测试lint并刷新本批清单，不改历史版本。

## 验证与命令

cwd clients/flutter（check.ps1从仓库根执行），完整日志均本目录：

| 执行 | 实际结果 |
| --- | --- |
| flutter test --no-pub test/runtime/runtime_destroy_failure_test.dart --reporter expanded（修复前） | red.log退出1：接管failure实际null、显式重试仍原PlatformException；附清理失败记录 |
| 同命令最小修复后 | green.log退出0，初始2项通过 |
| Quality初轮 | quality-run.log退出1，新测试2个大括号lint，未进入全测试；修正保留失败 |
| Quality最终 | quality-final-run.log及quality-final/退出0，75共同（原72+新增3）、58文件格式0变化/analyze/26冻结+05/锁通过 |
| Android既有真实coordinator_handoff_test | android-regression.log退出0，1项通过；PID6129，epoch1793966810055437→538，backendEpoch1/native-1，保存2345、接管2708，确认1、最终原生空 |
| Windows同一真实测试 | windows-regression.log退出0，1项通过；PID9820，epoch1793966849461111→112，backendEpoch1/native-1，保存2345、接管2794，确认1、最终原生空；host无字段，null不作身份证明 |

新增第三项验证连续两次失败没有自动release重试，明确第三次调用才成功；失败期间consumer仍1/epoch不变/paused/起播拒绝。三项共同结果包含在最终75项内。调用链为真实Dart runtime/backend/coordinator，native由mock代替；平台回归只覆盖正常接管路径，不是原生故障注入、物理听感或断电试验。

普通产物先备份至graphflow-out/destroy-failure-20261106/ordinary-before（APK和Windows整个Release），摘要ordinary-before.json；本批产品变化后普通main需新构建，最终构建/安装/启动与审阅记录在后续收尾段。

## 保留边界

本批未完成多资源部分失败receipt恢复、持续失败时整个close的锁/订阅清理保证、close与save/destroy整体竞争、真实系统release报错、长后台/OS回收、跨engine异常死亡/无损R2、外设或人耳听感。持续失败保持暂停意图及不可信拒绝，不等于全部资源已释放。A07/G-L仍review，不自动P2/正式UI。

## 最终收尾

独立[修复审阅](review.md)无Critical/Important。执行者补pause也失败仍保留原release异常/暂停意图/不可信拒绝且mock物理playing仍true，以及并发两次清理共用一次native release两项；review-tests.log共5项通过。测试清理先放行release gate；最终quality-reviewed-run.log与quality-reviewed/退出0，共77项、58文件格式0变化/analyze、v2.5的26冻结+05/锁全部通过。审阅前新清单保留freeze-pre-review.json；产品字节未因审阅变化，无重复平台回归。

普通main Android/Windows Release均编译成功，见android-release-run.log、windows-release-run.log及builds/。Android已恢复本批新普通APK安装Success，COLD启动Status ok/PID7900/Awake（android-ordinary-*日志及hash.json）。Windows新普通入口隐藏启动2秒PID4684后关闭，仅启动检查（windows-ordinary-start.log）。新普通APK另存graphflow-out/destroy-failure-20261106/ordinary-final/app-release.apk，双端产物摘要ordinary-final.json；旧普通备份仍保留。没有普通播放听感或签名/发布改变。

源码/产物/文档最终校验见final-check.log，实际tracked差异与测试摘要见本目录；GraphFlow定向索引见index.log。限定修复目标完成，所有旧修改和失败证据保留，无提交推送发布；A07/G-L仍review。下一项可先定点处理持续释放失败时close的独立清理保证及写锁收尾，先做受控失败复现，不扩大到全生命周期重写或真实系统故障声明。
