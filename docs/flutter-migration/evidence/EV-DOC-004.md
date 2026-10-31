# EV-DOC-004：R3.3执行契约核查证据

日期2026-10-30；任务DOCSET-04；需求R-08/09/17/21/22/24/32—35；等级L0，DOC-01—05。仅文档核查，不代表TC-05/56/57/58或任何产品/原型/真机能力通过。

## 基线与授权

cwd为实际仓库根`<repo>`；Windows/PowerShell、Git、Python 3.14.7。只读实际核对status/branch/rev-parse/log、`git ls-remote origin HEAD refs/heads/main`及package版本：main，完整SHA `4f47d10cd4d8deb0118e35198105f11bee754246`，提交2026-10-30T09:02:44+08:00，远程HEAD/main同SHA，package0.7.1。当前本地日期核对为2026-10-30。开始39份已有未跟踪Markdown，status仅`?? docs/flutter-migration/`，无tracked差异；保存39文件及AGENTS的SHA-256快照，不把整目录当本次新增。

最新授权AUTH-DOC-R33-20261030仅四项执行契约及相关文档/证据；未进PREP/产品/原型，未创建Flutter工程、快照适配器或实验文件，未安装依赖、执行音源/私人数据、提交推送发布。总体架构/功能/阶段/风险门未变；相关A任务说明按本轮授权澄清，B任务/产品规则/路线原文保持。旧EV-DOC-001—003不修改。

## 方法与限制

GraphFlow先以实际项目rootDir、recordDialogue=false调用context，返回15条summary/15 anchors，compressedTokens1441/tokenBudget1500；含历史workbench/无关源码线索，不足以判定四项细节，改为05及相关任务/测试/ADR等定点文档读取，未把历史记忆当当前批准或运行事实。plan返回agent-delegated，已提交intent及audit→revise→verify串行DAG并merge，complete=true、missing=[]；未配置或读取密钥，未依赖私有聊天。

实际读AGENTS/安装的GraphFlow和审阅技能；核C-02/03/04/05、A02/A03/A05/A07、PREP-01、08互斥、后续工作包、TC与追踪。四项判断见review R3.3，不需本轮选择/执行后端API，因此未浏览新API或编造表达式。一次多文件patch因06标题不匹配被整体拒绝；随即只读核实前面的修改也未落盘，读取实际标题后重试成功。未覆盖用户文件或把补丁失败当产品失败。

变更后按规则index，实际响应见末节。全部产品/原型测试、受控Future、真实事件映射、文件跨进程恢复与锁交错仅有后续规格，本轮未执行。

## 可复现文档检查

工作目录`<repo>`，前置Python 3与Git；复用历史EV-DOC-002固定检查正文，在本次运行内调整注册集合并追加R3.3断言，不改旧证据。以下入口只读，不创建脚本文件/安装包。预期JSON errors=[]及退出0。

```powershell
@'
from pathlib import Path
s = Path('docs/flutter-migration/evidence/EV-DOC-004.md').read_text(encoding='utf-8')
f = chr(96) * 3
exec(compile(s.split(f+'python\n', 1)[1].split('\n'+f, 1)[0], 'EV-DOC-004.md:python', 'exec'))
'@ | python -
```

```python
from pathlib import Path
import re, json, hashlib

root = Path('docs/flutter-migration')
protected = {
    root/'evidence/EV-DOC-001.md': '859ba231a53843f7509a72d79d09bf677e0d9ee7798bbc0b8531b0c767b51c2f',
    root/'evidence/EV-DOC-002.md': '75d5ea8510e189c944d0c5aad1e9c92e82963a881625140cdf91804a50321d26',
    root/'evidence/EV-DOC-003.md': '7db09c8ffab5de9e454ae59a644ae582ff008856046bfac67352638dd9c05c96',
    root/'09-roadmap.md': '98b465b6134fa3262efdbfe5e95f59e21def79d86aa2fb8639eaa37617decf3e',
    root/'03-product-rules.md': 'b585a18b6cfbf3e01031697f4090bcfe210b64e8f70df1b697c4cd0f41ffb23a',
    root/'decisions/ADR-0001-direction.md': '6e0412c35cf89f17760137a54d42d7f5d9c4cf8f5f25370289872e412eed68b2',
    root/'tasks/phase-1b.md': '3f748d4861dbed2d4ce84e143ee3616f93ff3e30a181bfa4a584f8af9f5ba5cf',
}
for p, digest in protected.items():
    assert hashlib.sha256(p.read_bytes()).hexdigest() == digest, 'protected changed: ' + str(p)
fence = chr(96) * 3
legacy = (root/'evidence/EV-DOC-002.md').read_text(encoding='utf-8')
code = legacy.split(fence+'python\n',1)[1].split('\n'+fence,1)[0]
updates = {
    'range(1,47)': 'range(1,59)',
    'range(1,26)': 'range(1,36)',
    "['DOCSET-02']": "['DOCSET-04']",
    "{'DOCSET-01','DOCSET-02'}": "{'DOCSET-01','DOCSET-02','DOCSET-03','DOCSET-04'}",
}
for old, new in updates.items():
    assert old in code, 'unexpected legacy checker: ' + old
    code = code.replace(old, new)
ns = {}
exec(compile(code.split('result = dict',1)[0], 'EV-DOC-002-adapted', 'exec'), ns)
check, rows, texts = ns['check'], ns['rows'], ns['texts']
graph = ns['graph']
check(graph.get('A07') == ['A02','A04','A06'], 'A07 file snapshot dependency')
check(len([x for x in graph if re.fullmatch(r'A\d+|B\d+[ab]?',x)]) == 18, 'A/B task count')
check(all(not d.startswith('WP-') for k,dlist in graph.items() if re.fullmatch(r'A\d+|B\d+[ab]?',k) for d in dlist), 'P1 depends on future WP')
gates = [r[0] for r in rows('09-roadmap.md') if re.fullmatch(r'G-[A-Z0-9]+',r[0])]
check(len(gates)==7 and set(gates)=={'G-L','G-V','G-N','G-B','G-S0','G-S1','G-D'}, 'risk gates changed')
wp_rows = [r for r in rows('tasks/phase-backlog.md') if re.fullmatch(r'WP-[A-Z0-9-]+',r[0])]
check(len(wp_rows)==len(ns['wp']) and {r[0] for r in wp_rows}==ns['wp'], 'WP index mismatch')
for r in wp_rows:
    check((ns['refs'](r[3],'TC') | ns['refs'](r[3],'DOC')) <= ns['tests'], 'WP unregistered test: '+r[0])
trace_tests = set().union(*(ns['refs'](r[4],'TC') for r in ns['requirements']))
check({'TC-05','TC-56','TC-57','TC-58'} <= trace_tests, 'new contract tests not traced')
architecture = texts[root/'05-architecture-contracts.md']
check(all(x in architecture for x in ['意图接收与权威状态提交','不把整个播放Future塞进串行链','playbackConfirmationId','P1最小持久快照适配','RecoverySnapshotStore','前进程实际保存','内存fake/同进程重建不能替代','P2由正式Repository']), 'contract clauses missing')
check(all(x in architecture for x in ['| accepted |','| applied |','| playing |','| released |','后端事件归一化交付合同','本章started/completed']), 'signal/mapping contract missing')
phase0 = texts[root/'tasks/phase-0.md']
prep = phase0.split('## PREP-01：',1)[1].split('## PREP-02：',1)[0]
check(all(x in prep for x in ['TC-56','TC-57','TC-05','新进程','不扩P1']), 'PREP first three not covered')
phase1 = texts[root/'tasks/phase-1a.md']
for key in ['A03','A05']:
    section = phase1.split('## '+key+'：',1)[1].split('\n## ',1)[0]
    check('映射' in section and 'TC-57' in section and 'API' in section, 'platform mapping missing: '+key)
tc58 = next(r for r in rows('10-testing-release.md') if r[0]=='TC-58')
check('不作为P1前置' in tc58[2] and not re.search(r'\b(?:A\d+|B\d+[ab]?)\b',tc58[2]), 'lock test assigned to P1')
data = texts[root/'08-data-migration.md']
check('## O：文件操作锁序与等待' in data and '数据库事务不跨网络' in data and '不预设mutex' in data, 'lock policy missing')
for key in ['WP-P2-DATA','WP-P2-LOCAL','WP-P2-PLAY','WP-P5-DOWNLOAD','WP-P5-MIG','WP-P6-ASSET']:
    row = next(r for r in wp_rows if r[0]==key)
    check('TC-58' in row[3] or '/58' in row[3], 'lock test not assigned: '+key)
errors = ns['errors']
result = dict(markdown_files=len(ns['files']), local_links=ns['links'], detailed_tasks=len(graph), future_work_packages=len(ns['wp']), test_specs=len(ns['tests']), requirements=len(ns['requirements']), task_dag_acyclic=not ns['pending'], risk_gates=len(gates), history_route_direction_protected=True, tracked_changes=bool(ns['tracked']), untracked_markdown_files=len(ns['untracked']), errors=errors)
print(json.dumps(result,ensure_ascii=False))
raise SystemExit(bool(errors))
```

静态检查只覆盖文件链接/编号/基本追踪/字段/DAG、指定关键句及保护摘要；不能证明自然语言或未来代码全正确、锚点渲染、API时序、进程恢复或无死锁。人工语义对照与初始39文件哈希范围比较另记下节，不能只凭未跟踪状态证明保留。

## 实际结果与语义核查

实际校验退出0；补充快照保存的修订顺序后再次核对，预期字段不变：

```json
{"markdown_files":40,"local_links":141,"detailed_tasks":27,"future_work_packages":23,"test_specs":63,"requirements":35,"task_dag_acyclic":true,"risk_gates":7,"history_route_direction_protected":true,"tracked_changes":false,"untracked_markdown_files":40,"errors":[]}
```

63是58个产品/原型TC规格及5个文档检查ID，不是运行通过63项产品测试。PowerShell/Python还输出InitializeDefaultDrives及Python位置提示；正文实际执行、产生JSON且退出0，不把环境提示当产品失败或成功。

人工语义复核：

1. C-02、A02与TC-56均限制为短接收/提交；旧Future一直pending不阻控制，且有效通道上的取消/控制派发也不挂在旧Future后，不能只改UI。底层取消/释放另确认；通道/物理释放前置只可有界pending并说明。四类信号含义只在05维护，04/任务消费，不用applied冒充物理停止/落盘/出声。
2. C-01确认凭据、C-04项目交接、C-05映射表与A03/A05/TC-57一致；原始同名playing/started不作为项目确认，重复/恢复不重记，历史与交接分别核验。只给交付维度/反例，未写未经原型的具体API判定表达式。
3. C-03快照范围、A02唯一文件归属、A07显式A02前置与TC-05一致；自有fixture/隔离文件/保存修订→旧进程终止→新进程实际读回/默认暂停及缺损退路，不依赖P2。P2明确替换装配/正式存储复验，不双写。
4. PREP-01明确计划前三项而未开始；第四项权威规则只有08 O，P2/P5/P6相应WP标TC-58，未新增P1任务或全局门。清理预约不阻释放、事务/相关独占锁不跨长等待、超时不等于可抢写，均与C-04/D合同相容。
5. 文档版本/变更/状态/交接及R-32—35/任务/TC已同步；新任务只是DOCSET-04，A/B仍18项、远期WP仍23、门仍7。保留原有视觉/源/发布授权边界，产品/原型仍未运行。

与初始39文件快照比较：18份相关既有文档修改、21份原文档字节不变，新增仅EV-DOC-004。修改范围为04-playback-interaction.md、05-architecture-contracts.md、06-audio-backends.md、08-data-migration.md、10-testing-release.md、11-risks-experiments.md、12-requirements-traceability.md、CHANGELOG.md、handoff.md、README.md、review.md、status.md、decisions/ADR-0002-runtime.md、decisions/ADR-0004-data.md、tasks/phase-0.md、tasks/phase-1a.md、tasks/phase-backlog.md、tasks/README.md。旧EV-DOC-001—003、AGENTS、03产品规则、09路线、ADR-0001与B任务原字节保留；无删除/产品/依赖变更。Git仍仅本目录未跟踪，不能将这些已有未跟踪文件当作可覆盖内容。

## 索引与未运行项

增量index实际返回indexedFiles=14、indexedSymbols=148、indexedReferences=0；vectorBackfill missing=274、refreshed=236（预算/截止限制，不能宣称全目录向量完整回填）。随后对18份修改与1份新增逐文件index，13次indexedFiles=1/skipped=false，6次skipped=true/reason=unchanged；这些是当次工具结果。最后针对“控制派发也不得等待旧Future”的相关澄清及本记录再定点index，不递归倒改历史计数，不外推为产品能力。

未运行npm/Flutter/原生构建测试、受控/真实脚本、播放/缓冲原型、文件快照或进程终止、锁交错、设备/听感。已核实的是文档原文及本轮文本契约一致性；实际API映射表达式/文件完成与恢复/死锁与数据一致性仍须后续授权原型和实平台验证。本轮交付后停止，不自动进PREP或开发。
