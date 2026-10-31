# EV-DOC-002：R3.1定点修订复验

日期：2026-10-30；任务DOCSET-02；需求R-17/20/21/22/24/25；DOC-01—05；等级L0。仅文档证据，TC-01—46全部未运行，不能提升任何产品风险门。

## 基线、授权与保护

cwd：实际仓库根`<repo>`；Windows/PowerShell、Git、Python 3.14.7。分支main，完整SHA `4f47d10cd4d8deb0118e35198105f11bee754246`；提交日期2026-10-30T09:02:44+08:00，package 0.7.1。实际只读执行`git status --short`、`git branch --show-current`、`git rev-parse HEAD`、`git log -1 --format=%cI`、`git ls-remote origin HEAD refs/heads/main`、`git rev-parse v0.7.1`及package版本读取：远程HEAD/main同SHA，标签`0e56c2f3150f257ed7fee45d5b2b797b1898c856`。本次开始已有36份未跟踪Markdown，status为`?? docs/flutter-migration/`，不是干净目录。

授权AUTH-DOC-R31-20261030仅本次两项意见与环境前提的相关文档/校验。没有修改AGENTS、产品、依赖或现有功能，没有创建Flutter工程、安装、执行音源、提交推送发布。修改前保存本目录36文件及AGENTS的SHA-256快照；下方保护哈希为实际输入，旧记录保留原字节：

- EV-DOC-001：`859ba231a53843f7509a72d79d09bf677e0d9ee7798bbc0b8531b0c767b51c2f`。
- AGENTS.md：`09cc1c8ccc0bb0c2d15a42450cab0628bb13321d327c7df6f4497c93421b0068`。

## GraphFlow

实际先调用context，rootDir使用实际项目绝对路径、recordDialogue=false：返回15条summary/15 anchors，compressedTokens429、tokenBudget1500；相关锚点不足以判断两项细节，随后定点读取目标文档，未扫描私人目录或执行产品。plan返回agent-delegated（无服务商LLM密钥），已由当前agent提交intent及串行verify→revise→validate三步DAG并merge，complete=true、missing=[]。这不是服务不可用，未读取/补配密钥，未假用启发式草案代最终计划。

变更后增量索引实际结果见本记录末节；不把索引计数解释为全目录向量完整性。

## 可复现静态检查

以下为本次实际使用的只读Python检查正文。工作目录`<repo>`，前置Python 3和Git；从本记录提取唯一python围栏，在标准输入执行，不创建脚本文件、不安装包。PowerShell外层示例：将提取的文本通过`python -`执行；也可在其他shell采用等价标准输入。预期JSON的errors为空、退出0；不存在的未来Flutter文件不当作已存在链接验证。

```python
from pathlib import Path
import re, json, hashlib, subprocess

root = Path('docs/flutter-migration')
files = sorted(root.rglob('*.md'))
texts = {p: p.read_text(encoding='utf-8') for p in files}
errors = []
def check(ok, msg):
    if not ok:
        errors.append(msg)
def rows(name):
    return [tuple(c.strip() for c in line.strip().strip('|').split('|'))
            for line in texts[root / name].splitlines() if line.startswith('|')]
def refs(body, prefix):
    found = set()
    for match in re.finditer(r'(?<![A-Za-z0-9-])' + re.escape(prefix) + r'-(\d+(?:[—–-]\d+)?(?:/\d+(?:[—–-]\d+)?)*)', body):
        for part in match[1].split('/'):
            bounds = [int(x) for x in re.split('[—–-]', part)]
            for n in range(bounds[0], bounds[-1] + 1):
                found.add(f'{prefix}-{n:02}')
    return found
links = 0
for p, body in texts.items():
    fence = chr(96) * 3
    check(body.count(fence) % 2 == 0, f'fence: {p}')
    prose = re.sub(fence + r'[\s\S]*?' + fence, '', body)
    check(not re.search(r'[A-Za-z]:[\\/](Users|Workspace)|/Users/|/home/[^ >]+', prose), f'personal path: {p}')
    for target in re.findall(r'\]\(([^)]+)\)', prose):
        target = target.strip('<>').split('#')[0]
        if not target or re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', target):
            continue
        links += 1
        check((p.parent / target).exists(), f'link: {p}: {target}')

id_pattern = r'(?:DOCSET-\d+|PREP-\d+|V\d+|A\d+|B\d+[ab]?)'
task_rows = [r for r in rows('tasks/README.md') if re.fullmatch(id_pattern, r[0])]
graph = {r[0]: [] if r[2] == '-' else r[2].split(',') for r in task_rows}
check(len(graph) == len(task_rows), 'duplicate task ID')
for key, deps in graph.items():
    check(all(d in graph for d in deps), f'unknown dependency: {key}')
pending, visited = dict(graph), set()
while pending:
    ready = [k for k, deps in pending.items() if set(deps) <= visited]
    if not ready:
        break
    for k in ready:
        visited.add(k)
        del pending[k]
check(not pending, 'task cycle')
check(graph.get('A03') == ['A02'] and graph.get('A05') == ['A02'], 'shared freeze dependencies')
check(graph.get('PREP-01') == ['DOCSET-02'] and graph.get('PREP-02') == ['DOCSET-02'], 'revision dependency')
definitions = set()
fields = ['目标', '范围与非目标', '前置任务', '相关需求', '接口', '文件范围', '实施步骤', '验收标准', '验证方法', '交付证据', '风险/回退', '停止条件']
for name in ['tasks/phase-0.md', 'tasks/phase-1a.md', 'tasks/phase-1b.md']:
    body = texts[root / name]
    matches = list(re.finditer(r'^## (' + id_pattern + r')：', body, re.M))
    for i, m in enumerate(matches):
        key = m[1]
        check(key not in definitions, f'duplicate definition: {key}')
        definitions.add(key)
        section = body[m.end():matches[i+1].start() if i+1 < len(matches) else len(body)]
        for field in fields:
            check('- ' + field + '：' in section, f'missing {field}: {key}')
check(definitions == set(graph), 'definition/index mismatch')
status_rows = [r for r in rows('status.md') if re.fullmatch(id_pattern, r[0])]
check({r[0] for r in status_rows} == set(graph), 'status/index mismatch')
check({r[0] for r in status_rows if r[1] == 'done'} == {'DOCSET-01','DOCSET-02'}, 'unproved completion')

tests = {r[0] for r in rows('10-testing-release.md') if re.fullmatch(r'(TC|DOC)-\d+', r[0])}
check(tests == {f'TC-{n:02}' for n in range(1,47)} | {f'DOC-{n:02}' for n in range(1,6)}, 'test registry')
for p, body in texts.items():
    check((refs(body, 'TC') | refs(body, 'DOC')) <= tests, f'unregistered test: {p}')
wp = {r[0] for r in rows('tasks/README.md') if re.fullmatch(r'WP-[A-Z0-9-]+', r[0])}
requirements = [r for r in rows('12-requirements-traceability.md') if re.fullmatch(r'R-\d+', r[0])]
check({r[0] for r in requirements} == {f'R-{n:02}' for n in range(1,26)}, 'requirement IDs')
for r in requirements:
    check(bool(r[2]) and bool(r[3]) and bool(r[4]), f'missing trace: {r[0]}')
    check(bool(refs(r[4], 'TC') | refs(r[4], 'DOC')), f'no registered test: {r[0]}')
    for name in re.findall(r'WP-[A-Z0-9-]+|' + id_pattern, r[3]):
        check(name in graph or name in wp, f'unknown traced task: {name}')
for p in [root / 'tasks/phase-0.md', root / 'tasks/phase-1a.md', root / 'tasks/phase-1b.md']:
    check(refs(texts[p], 'R') <= {r[0] for r in requirements}, f'unknown requirement: {p}')

gate = next(r for r in rows('09-roadmap.md') if r[0] == 'G-N')
check(refs(gate[1], 'TC') == {'TC-13','TC-46'}, 'G-N evidence boundary')
tc46 = next(r for r in rows('10-testing-release.md') if r[0] == 'TC-46')
check('B02' in tc46[2] and 'P4' not in tc46[2] and 'P6' not in tc46[2], 'TC-46 stage boundary')
tc33 = next(r for r in rows('10-testing-release.md') if r[0] == 'TC-33')
check('P4' in tc33[2] and 'P6' in tc33[2] and '不作为G-N前置' in tc33[2], 'TC-33 late coverage')
for path in ['tasks/phase-1a.md','10-testing-release.md']:
    body = texts[root / path]
    check('integration_test/local_playback_test.dart' not in body, 'ambiguous shared entry')
    for platform in ['android', 'windows']:
        check(f'flutter test integration_test/{platform}_local_playback_test.dart -d ' in body, f'missing platform command: {path}/{platform}')
ownership = texts[root / 'tasks/README.md']
check('唯一修改负责人' in ownership and 'local_playback_contract.dart' in ownership and 'A02负责人' in ownership, 'shared ownership')
workflow = texts[root / 'agent-workflow.md']
check(all(s in workflow for s in ['产品修改及需要GraphFlow前置的实施不可开始','多步产品实施阻塞','停止后续产品修改批次','不新增一层审批']), 'GraphFlow boundaries')

protected = {'AGENTS.md':'09cc1c8ccc0bb0c2d15a42450cab0628bb13321d327c7df6f4497c93421b0068', str(root/'evidence/EV-DOC-001.md'):'859ba231a53843f7509a72d79d09bf677e0d9ee7798bbc0b8531b0c767b51c2f'}
for name, expected in protected.items():
    check(hashlib.sha256(Path(name).read_bytes()).hexdigest() == expected, f'protected changed: {name}')
def git(*args):
    return subprocess.check_output(['git', *args], text=True, encoding='utf-8').strip()
tracked = git('diff', '--name-only', 'HEAD')
untracked = git('ls-files', '--others', '--exclude-standard').splitlines()
check(not tracked, 'tracked changes outside documentation snapshot')
check(all(x.startswith('docs/flutter-migration/') and x.endswith('.md') for x in untracked), 'untracked scope')
check(not Path('clients/flutter').exists(), 'unexpected Flutter project')
result = dict(markdown_files=len(files), local_links=links, detailed_tasks=len(graph), future_work_packages=len(wp), test_specs=len(tests), requirements=len(requirements), task_dag_acyclic=not pending, protected_hashes_unchanged=True if not any('protected changed' in e for e in errors) else False, tracked_changes=bool(tracked), untracked_markdown_files=len(untracked), errors=errors)
print(json.dumps(result, ensure_ascii=False))
raise SystemExit(bool(errors))
```

该静态检查只证明可解析的文件链接/ID/基本追踪及指定断言。它不证明所有自然语言合同、Markdown锚点渲染、未来接口实现或平台能力；另需下方人工定点核对。工作区初始36文件摘要比较在本次会话内另行执行，不能仅以Git未跟踪状态证明已有内容保留。

## 实际结果、语义复核与范围

首轮（退出1）：38份Markdown、99个本地文件链接、25个详细任务、20个远期工作包、51项测试规格、25条需求，任务图无环、保护哈希未变化、tracked_changes=false；errors为`personal path: evidence/EV-DOC-002.md`、`unregistered test: status.md`、`G-N evidence boundary`（此处路径省略共同目录）。逐项复查为检查器误报：将围栏内的路径检测正则当实际路径；把AUTH-DOC-20261030当DOC测试；Unicode词边界漏识别紧邻中文的TC-13。修正为正文检测路径及编号前排除ASCII标识前缀，不改业务合同来迎合检查器。以下复验结果单列，保留本轮失败事实。

修正后实际复验（退出0）：

```json
{"markdown_files":38,"local_links":99,"detailed_tasks":25,"future_work_packages":20,"test_specs":51,"requirements":25,"task_dag_acyclic":true,"protected_hashes_unchanged":true,"tracked_changes":false,"untracked_markdown_files":38,"errors":[]}
```

51是46项产品TC规格与5项文档检查，不是产品测试通过数。25需求中R-25补登记原有资料分层要求，未新增产品范围。以上检查退出0；PowerShell/Python同时报告环境提示，但实际执行了检查正文并产生JSON，不能仅看提示判断命令未运行。

人工定点复核（均为文档语义检查）：

1. 09门表/图、B02/B09、ADR-0005、R-17/25一致：G-N仅TC-46/13；TC-23/33不回指早期门，P4/P6仍承担实际平台验证，TC-33编号未复用。
2. 任务索引明确A02共享文件唯一负责人及冻结证据；A03/A05只改不同入口/adapter，使用单份共享断言与样本；共享变更串行整合，公共配置归A01。
3. phase-1a与10命令分别指定Android入口和Windows入口，cwd均clients/flutter；不存在的未来工程/设备不算运行证明。
4. PREP-01/02依赖最新DOCSET-02但未因此获得授权；环境能力表区分context无足够锚点、工具失败、plan桥接和index失败；未取消AGENTS要求、未新增审批层。
5. review、版本、status、handoff、CHANGELOG与追踪同步；各产品TC/门仍未运行或未授权，当前无正在进行的产品任务。
6. 基于本次修改前36份文件SHA-256快照比对，15份相关文件改变、21份原文件字节未变；新增2份Markdown。未变的21份包括EV-DOC-001及不相关架构/交互/资料研究等正文，AGENTS摘要不变。

实际改变的既有文件（均相对本目录）：README.md、review.md、09-roadmap.md、10-testing-release.md、12-requirements-traceability.md、agent-workflow.md、start-prompt.md、status.md、handoff.md、decisions/ADR-0005-gates.md、tasks/README.md、tasks/phase-0.md、tasks/phase-1a.md、tasks/phase-1b.md、tasks/phase-backlog.md。新增CHANGELOG.md与本记录。没有删除文件；Git仍只显示本目录未跟踪，没有tracked差异。

## 索引与未运行项

增量索引实际返回：indexedFiles=11、indexedSymbols=108、indexedReferences=0；vectorBackfill missing=238、refreshed=175（预算/截止限制，非全目录完整回填）。不将这11份外推为38份全部索引。随后对本次15份修改及2份新增文档逐文件调用index，17次均返回skipped=true、reason=unchanged、indexedFiles=0；这是工具当时判定无需更新，不代表向量全部回填。本记录最终保存后再定点调用index，响应不用于倒改上述历史结果。

未运行npm verify、Flutter/原生构建测试、任何音源/设备/听感；本轮仅文档，无工程或对应实施授权。平台门保持原未通过状态。PowerShell出现InitializeDefaultDrives提示时需核对实际子命令退出码；该提示不代表产品验证失败或通过。
