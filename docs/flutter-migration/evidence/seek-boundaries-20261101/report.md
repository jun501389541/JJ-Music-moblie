# A02/TC57 定位拒绝并发与缺字段桥接补充验证

2026-11-01，AUTH-P1-SEEKBOUND-20261101限定目标完成。基线main 4b5d4b8干净，新开发分支codex/seek-boundaries。owner Codex串行A02/文档维护。本批只新增两个验证文件及文档，没有修改生产逻辑、公共断言或夹具，v2.3的21文件/05摘要原样保留；不需要新合同版本。新增测试摘要在test-hashes.json，不冒充历史冻结已覆盖新文件。未提交/推送/合并/发布、改全局或旧Electron。

## 实际实现与结论

- test/playback/seek_concurrency_test.dart：false/null各覆盖B pending、B incoming、B active且A outgoing三类场景，共6项。先断言真实角色/当前轨，再断言拒绝ack.accepted/applied均false、正确失败原因；过一轮事件后actions、位置、generation、角色、确认均未变。原B的准备/确认仍可完成；completeTransition前A未释放、之后A恰好释放一次，B不被误释放。测试为ControlledBackend，不等于真实双轨音频输出。
- test/platform/native_seek_capability_test.dart：true、false、原生reply缺canSeek三项Mock MethodChannel验证。PreparedTrack分别保持true/false/null，缺字段没有默认支持；准备期间没有seek/play。真实Android/Windows能力取值仍引用前批实际证据，mock不代替平台运行。

9项首次运行通过，说明既有v2.3实现正确覆盖这些新增场景，没有复现生产缺陷，不修改生产代码来制造红绿过程。本批填补上次独立审阅列出的动态验证缺口。

## 验证记录

cwd clients/flutter：

```powershell
flutter test test/playback/seek_concurrency_test.dart test/platform/native_seek_capability_test.dart --reporter expanded
./tool/check.ps1 -Mode Quality -EvidenceDirectory <本批绝对目录>/quality-final
```

focused.log：首轮9/9、EXIT0。之后加强角色前置和ack断言，并根据独立审阅补释放时序断言，最终全套见quality-final/tests.log：51/51、EXIT0；format.log为47文件0变更；analyze.log No issues；依赖锁、21冻结和05权威摘要通过。

quality/保留首次分析失败的4条info（花括号及null-aware collection），没有记作通过；修正后完整复验。测试逻辑依旧用省略字段的native样本，不把字段null与实际省略混为平台事实。没有扩大构建/设备验证，因为运行时代码与依赖均未改；Android/Windows本批均未编译、安装、启动或真机运行，原有产物继续可用。

## 限定独立审阅及修复

按executing-plans/requesting-code-review使用一次只读seek_boundaries_review，未写文件或执行测试。指出一处重要覆盖漏洞：最终release计数1并不能单独证明没有提前释放，某种错误实现会假阳性。执行者补上completeTransition紧前release:ha为0（且hb未释放）的断言，后面继续断言A释放1次；完整51项通过。这里是补强测试，而非宣称修复了生产提前释放缺陷。该修订由执行者验证，没有再次派审阅。桥接三态未发现重要假阳性；依然仅模拟桥接，不证明OS返回。

## 交接与下一步

没有新增UI、APK或Windows程序；现有诊断入口无需重装。本批人工验收可在项目根运行上述Quality脚本，应51项共同测试通过；不需要手机或个人曲库。Git工作区应仅两个新增测试、证据与status/handoff差异；基线及after.log可核对。GraphFlow执行context/plan required submit+merge，变更后定向index，见index.log。

v2.3准备时能力快照的动态变化、自然15秒读超时/故障后新意图恢复、资源压力、长后台/独立engine与系统杀进程、物理媒体键和听感仍未齐。下一小批建议A03/A05自有门控自然超时及错误后恢复，用真实输入分别记录，不以fake代实际端。A03—A08整体review/G-L不放行，不进入P2、正式UI、在线/下载或真实源。
