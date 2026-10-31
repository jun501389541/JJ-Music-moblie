# EV-DOC-005：R4全阶段通用任务手册文档证据

日期2026-10-30；任务DOCSET-05；L0，DOC-01—05。本记录只证明已实际执行的文档检查；TC-01—58、原型、真机、源、听感、安装/发行均未运行。

## 基线、范围和方法

输入实际R3.3（40份已有未跟踪Markdown），main，完整SHA `4f47d10cd4d8deb0118e35198105f11bee754246`，package0.7.1，提交2026-10-30T09:02:44+08:00。开始及收尾只读核Git；远程HEAD/main同SHA；tracked/staged无差异。初始status只含本目录，未将已有文件视为空白可覆盖。授权只细化本目录文档，未修改AGENTS/产品、安装、创建Flutter或执行音源，未提交推送合并发布。

本轮按实际根调用GraphFlow context：15 summary/15 anchors，compressedTokens861/tokenBudget1500；压缩不足部分定点读取规则、最新review/CHANGELOG/status/handoff、ADR、任务和测试。plan返回agent-delegated，提交intent与五步DAG并merge，complete=true。变更后索引实际结果追加末节，不能将压缩上下文或历史记忆当当前运行。

架构/业务权威原文保持；只把任务手册、条件/文件角色、入口、追踪、路线引用/ADR-0005、审阅/交接等对齐。官方[Flutter CLI](https://docs.flutter.dev/reference/flutter-cli)和[集成测试](https://docs.flutter.dev/testing/integration-tests)仅核未来命令入口；未调用SDK/后端API。现有源路径仅存在性检查，不执行旧产品套件。

编辑过程遇到工具侧配置语法错误、PowerShell通配符/花括号及输出截断，相关失败未当作产品结果；随后改定点读取并使用ASCII转义传输中文，清除临时占位和中间文件。PowerShell报InitializeDefaultDrives及Python定位提示时，仍核实际JSON/退出码；不以提示替代检查结果。历史证据不覆写。

## 可复现检查入口

cwd为实际仓库根；Windows/PowerShell，前置Git和Python 3，无需网络/产品依赖。以下入口从本证据读取固定检查代码后只读执行，不写脚本文件、不索引或运行产品。预期退出0、errors为空。字节断言针对本轮交付快照；未来授权修改后失败应另存新证据，不改本记录的历史基线或降低检查。

```powershell
@'
from pathlib import Path
s=Path('docs/flutter-migration/evidence/EV-DOC-005.md').read_text(encoding='utf-8')
start=s.index('<!-- CHECKER -->')
code=s[start:].split('```python\n',1)[1].split('\n```',1)[0]
exec(compile(code,'EV-DOC-005-checker','exec'))
'@ | python -
```

<!-- CHECKER -->
```python
from pathlib import Path
import re,json,hashlib,subprocess,sys
from urllib.parse import unquote
root=Path.cwd()
base=root/'docs/flutter-migration'
ev=base/'evidence/EV-DOC-005.md'
text=ev.read_text(encoding='utf-8')
initial=json.loads(re.search(r'<!-- BASELINE -->\s*\x60\x60\x60json\n(.*?)\n\x60\x60\x60',text,re.S).group(1))
errors=[]
def need(ok,msg):
    if not ok: errors.append(msg)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def refs(s,prefix):
    found=set()
    pattern=rf'(?<![A-Z]){prefix}-(\d{{2}})((?:[—–-]\d{{2}})?(?:/\d{{2}}(?:[—–-]\d{{2}})?)*)(?!\d)'
    for m in re.finditer(pattern,s):
        for token in (m.group(1)+m.group(2)).split('/'):
            ends=re.split('[—–-]',token)
            start=int(ends[0]);end=int(ends[-1])
            need(end>=start,f'reversed {prefix} range: {m.group(0)}')
            found.update(f'{prefix}-{i:02}' for i in range(start,end+1))
    return found
def task_rows(s):
    rows={}
    for line in s.splitlines():
        cols=[x.strip() for x in line.strip().strip('|').split('|')]
        if line.startswith('| ') and cols and re.fullmatch(taskid,cols[0]):
            need(cols[0] not in rows,'duplicate row '+cols[0])
            rows[cols[0]]=cols
    return rows
taskid=r'(?:DOCSET-\d{2}|PREP-\d{2}|[ABV]\d{2}[ab]?|P[2-9]-\d{2}|REL-\d{2})'
files=sorted(base.rglob('*.md'));contents={}
links=0
for p in files:
    try: s=p.read_text(encoding='utf-8')
    except UnicodeError as e: errors.append(str(e));continue
    contents[p]=s
    need('\ufffd' not in s,'replacement char '+str(p.relative_to(root)))
    if p!=ev:
        for bad in ['undefined','对应注册TC','P1A-00','P1B-00','REL-00']:
            need(bad not in s,'unresolved '+bad+' '+str(p.relative_to(root)))
    fence=None;prose=[]
    for line in s.splitlines():
        m=re.match(r'^\s*(\x60{3,}|~{3,})',line)
        if m:
            run=m.group(1)
            if fence is None:fence=(run[0],len(run))
            elif run[0]==fence[0] and len(run)>=fence[1]:fence=None
        elif fence is None:prose.append(line)
    plain='\n'.join(prose)
    need(fence is None,'unclosed fence '+str(p.relative_to(root)))
    if p==ev:continue
    for target in re.findall(r'(?<!!)\[[^\]\n]+\]\(([^)\n]+)\)',plain):
        target=target.strip().split(' "',1)[0].strip('<>')
        if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target) or target.startswith('#'):continue
        path=unquote(target.split('#',1)[0]);path=re.sub(r':\d+$','',path)
        if any(x in path for x in ['<','>','*']):errors.append('placeholder link '+target);continue
        need((p.parent/path).exists(),'missing link '+str(p.relative_to(root))+' -> '+target);links+=1
    need(not re.search(r'[A-Z]:[\\/](?:Users|Workspace)|/Users/|/home/\w+',plain),'personal absolute path '+str(p.relative_to(root)))
idx=contents[base/'tasks/README.md'];registry=task_rows(idx);status=task_rows(contents[base/'status.md'])
need(len(registry)==100,'expected 100 tasks')
need(set(registry)==set(status),'status/index task mismatch')
deps={}
for tid,cols in registry.items():
    need(len(cols)==5,'index columns '+tid)
    ds=[] if cols[2]=='-' else cols[2].split(',');deps[tid]=ds
    for d in ds:need(d in registry,'missing prerequisite '+tid+' -> '+d)
seen=set();active=set();order=[]
def walk(t):
    if t in active:errors.append('dependency cycle '+t);return
    if t in seen:return
    active.add(t)
    for d in deps[t]:
        if d in registry:walk(d)
    active.remove(t);seen.add(t);order.append(t)
for t in registry:walk(t)
definitions={};bodymap={}
for p,s in contents.items():
    if p.parent!=base/'tasks' or not (p.name.startswith('phase-') or p.name=='releases.md'):continue
    starts=list(re.finditer(r'^## ('+taskid+r')[：:]',s,re.M))
    for i,m in enumerate(starts):
        tid=m.group(1);need(tid not in definitions,'duplicate definition '+tid)
        definitions[tid]=p
        bodymap[tid]=s[m.start():starts[i+1].start() if i+1<len(starts) else len(s)]
need(set(definitions)==set(registry),'definitions/index mismatch')
for tid,p in definitions.items():need(p.name in registry[tid][4],'wrong index file '+tid)
historic={f'DOCSET-{i:02}' for i in range(1,5)}
labels=['目标与用户可见结果','依据与产品规则','范围与非目标','前置与授权','环境与自有数据','输入输出契约','允许文件与负责人','正常/异常/取消/并发场景','验证方法','完成标准与证据','条件与待定项','失败出口与回退','独立可继续工作','下一任务']
step_count=0
for tid,body in bodymap.items():
    if tid in historic:continue
    for label in labels:need('- '+label+'：' in body,'missing task field '+tid+' '+label)
    need('| 步骤 | 目的 | 动作 | 预期结果 | 失败处理 |' in body,'missing step table '+tid)
    rows=[line for line in body.splitlines() if re.match(r'^\| \d+ ',line)]
    need(len(rows)>=5,'too few task steps '+tid)
    for line in rows:
        cols=[x.strip() for x in line.strip('|').split('|')]
        need(len(cols)==5 and all(cols),'empty/broken task step '+tid)
    step_count+=len(rows)
tests=contents[base/'10-testing-release.md']
registered=set(re.findall(r'^\| ((?:TC|DOC)-\d{2}) \|',tests,re.M))
need(registered=={f'TC-{i:02}' for i in range(1,59)}|{f'DOC-{i:02}' for i in range(1,6)},'test registry')
products=set(re.findall(r'^\| (PR-\d{2}) \|',contents[base/'03-product-rules.md'],re.M))
requirements={}
for line in contents[base/'12-requirements-traceability.md'].splitlines():
    if not re.match(r'^\| R-\d{2} \|',line):continue
    cols=[x.strip() for x in line.strip('|').split('|')]
    rid=cols[0];requirements[rid]=cols
    tids=set(re.findall(taskid,cols[3]));need(bool(tids) and tids<=set(registry),'bad requirement tasks '+rid)
    tcs=refs(cols[4],'TC')|refs(cols[4],'DOC');need(bool(tcs) and tcs<=registered,'bad requirement tests '+rid)
    for tid in tids:need(rid in refs(bodymap.get(tid,''),'R'),'nonreciprocal requirement '+rid+' '+tid)
need(set(requirements)=={f'R-{i:02}' for i in range(1,37)},'requirement registry')
for tid,body in bodymap.items():
    rs=refs(body,'R');need(rs<=set(requirements),'unknown requirement '+tid)
    for rid in rs:need(tid in set(re.findall(taskid,requirements[rid][3])),'missing reverse trace '+tid+' '+rid)
    need((refs(body,'TC')|refs(body,'DOC'))<=registered,'unknown test '+tid)
    need(refs(body,'PR')<=products,'unknown product rule '+tid)
for rel,digest in initial.items():need((root/rel).is_file(),'lost initial file '+rel)
protected=[p for p in initial if p.startswith('docs/flutter-migration/evidence/')] + [
'AGENTS.md','docs/flutter-migration/03-product-rules.md',
'docs/flutter-migration/04-playback-interaction.md','docs/flutter-migration/04-visual-review.md',
'docs/flutter-migration/05-architecture-contracts.md','docs/flutter-migration/06-audio-backends.md',
'docs/flutter-migration/07-background-downloads.md','docs/flutter-migration/07-media-broker.md',
'docs/flutter-migration/07-source-runtime.md','docs/flutter-migration/08-data-migration.md']
for rel in protected:need(sha(root/rel)==initial[rel],'protected bytes changed '+rel)
need(not (root/'clients/flutter').exists(),'unexpected Flutter tree')
need(all(p.suffix=='.md' for p in base.rglob('*') if p.is_file()),'non-Markdown docs file')
tracked=subprocess.check_output(['git','diff','--name-only'],text=True).strip()
staged=subprocess.check_output(['git','diff','--cached','--name-only'],text=True).strip()
need(not tracked and not staged,'tracked or staged changes')
untracked=subprocess.check_output(['git','ls-files','--others','--exclude-standard'],text=True).splitlines()
need(all(p.startswith('docs/flutter-migration/') and p.endswith('.md') for p in untracked),'outside documentation untracked file')
gates=set(re.findall(r'^\| (G-[A-Z0-9]+) \|',contents[base/'status.md'],re.M))
need(gates=={'G-L','G-V','G-N','G-B','G-S0','G-S1','G-D'},'gate set changed')
aliases=re.findall(r'^\| (WP-[A-Z0-9-]+) \|',contents[base/'tasks/phase-backlog.md'],re.M)
need(len(aliases)==23 and len(set(aliases))==23,'legacy WP mapping')
for rel in ['tools/build-test.mjs','tools/run-tests.mjs','src/test/local-search.test.mts','src/test/playlist-backup.test.mts','src/test/playlist-restore.test.mts']:
    need((root/rel).exists(),'existing source reference '+rel)
def ancestors(t,visiting=None):
    visiting=set() if visiting is None else visiting
    if t in visiting:return set()
    out=set();visiting=visiting|{t}
    for d in deps[t]:out.add(d);out.update(ancestors(d,visiting))
    return out
need(not any(t.startswith(('P4-','P6-','B')) for t in ancestors('A08')),'local gate waits online')
need(not any(t.startswith(('P4-','P6-')) for t in ancestors('B02')),'G-N backwards dependency')
need('A02' in deps['A07'] and not any(t.startswith('P2-') for t in ancestors('A07')),'P1 recovery prerequisite')
need(deps['A03']==['A02'] and deps['A05']==['A02'],'platform entry prerequisite')
need(not any(t.startswith('P8-') for t in ancestors('REL-01')),'first Android release waits advanced')
ownership=contents[base/'tasks/contracts-ownership.md']
for token in ['A02唯一维护','android_local_playback_test.dart','windows_local_playback_test.dart','SchemaMaintainer','ConfigIntegrator','P2-08']:
    need(token in ownership,'ownership obligation '+token)
for tid,tokens in {
'PREP-01':['TC-56','TC-57','TC-05'],'A02':['pending','文件','释放'],
'A03':['TC-57','映射'],'A05':['TC-57','映射'],'A07':['新进程','快照'],
'P2-00':['锁','改造'],'P5-00':['锁'],'P6-00':['锁']}.items():
    for token in tokens:need(token in bodymap[tid],'semantic obligation '+tid+' '+token)
changed=[rel for rel,h in initial.items() if (root/rel).is_file() and sha(root/rel)!=h]
added=sorted(p.relative_to(root).as_posix() for p in files if p.relative_to(root).as_posix() not in initial)
result={'docs_version':'R4','git_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
'markdown_files':len(files),'local_links_checked':links,'registered_tasks':len(registry),
'historic_tasks':len(historic),'expanded_tasks':len(bodymap)-len(historic),'step_rows':step_count,
'test_specs':len(registered),'requirements':len(requirements),'legacy_wp_mappings':len(aliases),
'gates':sorted(gates),'dag':'acyclic' if len(order)==len(registry) and not errors else 'inspect errors',
'initial_documents_preserved':len(initial)-1,'protected_hashes_checked':len(protected),
'modified_initial_docs':changed,'added_docs':added,'errors':errors}
print(json.dumps(result,ensure_ascii=True,indent=2))
sys.exit(1 if errors else 0)
```

## 本轮开始摘要

初始40份文档及AGENTS的SHA-256；只用于保留/差异核验，不含私人资料。核验器不要求被授权编辑的文档仍与初始一致；单独保护历史证据/AGENTS及未改动的权威业务章。

<!-- BASELINE -->
```json
{
  "docs/flutter-migration/01-current-repository.md": "bdf26b87f14dff238dda5f92d891bd5ad8bf48828a4b9a2bb86f3d7caf351e2e",
  "docs/flutter-migration/02-reference-research.md": "095281656cebe4d17da0eb91f4301e84acb7d81cbe48e5ce22c3fcb6a2679ae2",
  "docs/flutter-migration/03-product-rules.md": "b585a18b6cfbf3e01031697f4090bcfe210b64e8f70df1b697c4cd0f41ffb23a",
  "docs/flutter-migration/04-playback-interaction.md": "9407c5929a6f5a38b5a62f1f0d65573acc531d29fe92726e2b3d9ccec898ab9a",
  "docs/flutter-migration/04-visual-review.md": "bda660d4f2bf1903d130182b297208c3d62cdbb384b754f7972ec608af29e5de",
  "docs/flutter-migration/05-architecture-contracts.md": "4ceb24ee1a16c8b1c37dc6deef431ee14679857613ebcb828bc3c5c0283dae17",
  "docs/flutter-migration/06-audio-backends.md": "9ecff140bf7bcb6eee83536e0114ca08e54fb1e69681695997de0cc5ecb7e518",
  "docs/flutter-migration/07-background-downloads.md": "afc3cfa1f26727f2bb20a4a0d76b4fe523348e12df882a9c10202906a3652e4c",
  "docs/flutter-migration/07-media-broker.md": "a7fad49085d668344207c5369f6fde42bc5bcc38ff6117c2925f98042bbc2c07",
  "docs/flutter-migration/07-source-runtime.md": "48b7f9b818696fc5b505996933dd5ca00363d829bdf37c6784b3daef840e9b12",
  "docs/flutter-migration/08-data-migration.md": "6e000f0fba921e63564a9ae399382886ea7938e212ce253ac2502786718a9a73",
  "docs/flutter-migration/09-roadmap.md": "98b465b6134fa3262efdbfe5e95f59e21def79d86aa2fb8639eaa37617decf3e",
  "docs/flutter-migration/10-testing-release.md": "9cb6ba7f2955877145f5c0a1b75ec01963bb6d37c729eeec1ca2c2fb2edae79f",
  "docs/flutter-migration/11-risks-experiments.md": "1d23b31c4b724c922aaabaa01f65fc2720d8cccece5ae522ab8bd61f3d7d88f3",
  "docs/flutter-migration/12-requirements-traceability.md": "172d48ddddfd5b31eb1ff655a187f3c61f4ac42a21c10ddb325d867bd5612693",
  "docs/flutter-migration/agent-workflow.md": "b64b2789336e3d94413512963d4ae4ee89a296f80395dc5fa3d25231d72586bc",
  "docs/flutter-migration/CHANGELOG.md": "b2f1c36d3970f31a3d4fb6861dc68f30bcf79d14eda518c6a9bda8e19740894a",
  "docs/flutter-migration/handoff.md": "ff19d82c7e19460b3c71cd74339d3605c769d103ddbf84f76ffc3da41a202931",
  "docs/flutter-migration/README.md": "d13091cd76cd34e86eb5cc9fa344dd69f1b67fb6df469e52c45fa7898f362499",
  "docs/flutter-migration/review.md": "1f6a1c021526e341cd4701730bdc3269a00942c7da4db91b640482ab6e4449dc",
  "docs/flutter-migration/start-prompt.md": "6e9eec059d28eaed9dc80b1cf05f01c50043b3724ea1d5f30436a76a5844e222",
  "docs/flutter-migration/status.md": "e017cd762fef7c7d3deb2f7c83969b6c20e4a5db7356684ea918c0354e0edc2d",
  "docs/flutter-migration/decisions/ADR-0001-direction.md": "6e0412c35cf89f17760137a54d42d7f5d9c4cf8f5f25370289872e412eed68b2",
  "docs/flutter-migration/decisions/ADR-0002-runtime.md": "119ff28a89811103ef425fc3578ecbf0d75a97f9629a74f4339516c607a5ce27",
  "docs/flutter-migration/decisions/ADR-0003-backends.md": "d3d30bacbbffdb7d540b863c9ba8efef7b8f8a15d53d001706b9df18de90313b",
  "docs/flutter-migration/decisions/ADR-0004-data.md": "3b7ca422a92da96d33e0a5e3cfb9339f8af3d20eeca640188dcb10ddd23f14c3",
  "docs/flutter-migration/decisions/ADR-0005-gates.md": "a6adeeb787e2912a2a73d9f111aec70f398e273f9f292e2be8380c8d3dece9f3",
  "docs/flutter-migration/decisions/ADR-0006-ui-state.md": "a4e8cd13b0ba5d72b31b78b9bfefb7376e710d8a34ec7614ed9e9f6fa2064114",
  "docs/flutter-migration/decisions/README.md": "1edb525d747c06ebc2437f9e2c95c94abef35b704bb68cb154a1503e252e4327",
  "docs/flutter-migration/evidence/EV-DOC-001.md": "859ba231a53843f7509a72d79d09bf677e0d9ee7798bbc0b8531b0c767b51c2f",
  "docs/flutter-migration/evidence/EV-DOC-002.md": "75d5ea8510e189c944d0c5aad1e9c92e82963a881625140cdf91804a50321d26",
  "docs/flutter-migration/evidence/EV-DOC-003.md": "7db09c8ffab5de9e454ae59a644ae582ff008856046bfac67352638dd9c05c96",
  "docs/flutter-migration/evidence/EV-DOC-004.md": "1f08c36170e6ab9c810e36065a7c1600ba521a88c072e8a3170e64967b355c29",
  "docs/flutter-migration/evidence/README.md": "62d004366298dfe61752af487bb6e65f63dd0cb4e5b697076ecb74e5360ac1ab",
  "docs/flutter-migration/tasks/phase-0.md": "7090d17a9c27f86b373cda9dae7836f9f793ab2458f19ea98d15aa5c8e0e63a9",
  "docs/flutter-migration/tasks/phase-1a.md": "80a1d3ad8df348b6f97bcaed70eca30bf7d6099d4c3c232003ac88fa8ff75cc3",
  "docs/flutter-migration/tasks/phase-1b.md": "3f748d4861dbed2d4ce84e143ee3616f93ff3e30a181bfa4a584f8af9f5ba5cf",
  "docs/flutter-migration/tasks/phase-backlog.md": "4a11860cbd593a8efb1ddec241ca579019461695407707b0d61e00384ce66881",
  "docs/flutter-migration/tasks/README.md": "9240b3a51428b4840f93849d575da645594cd9611a6dc974504ac270a883ed67",
  "docs/flutter-migration/tasks/task-template.md": "117e4fabf0dff7ef4867870eab36e71daf6808e4d90e042f53b1bdb979ae9038",
  "AGENTS.md": "09cc1c8ccc0bb0c2d15a42450cab0628bb13321d327c7df6f4497c93421b0068"
}
```

## 实际结果

实际执行：2026-10-30，Windows/PowerShell，Git与Python 3；上述入口退出0。检查55份Markdown、921处正文相对链接、100个登记任务（4个历史DOCSET，96个实填任务）、694行操作步骤、36项需求、63个测试规格、23个旧WP映射；依赖无环，errors为空。15个保护摘要全部相同，40份既有文档保留；18份既有文档被授权修订，新增15份Markdown。登记数量不是已完成产品任务或测试通过数量。

首轮检查退出1，共366条报告：353条是任务正文缺显式需求引用（同一缺口按需求/任务分别报告），8条是旧证据围栏代码被误认链接/个人路径，5条是检查器将EV-DOC-005等前缀截成DOC-00。修复方法：给96个实填任务添加指向12的需求ID引用；检查器只解析正文链接并完整匹配两位ID，不改旧证据、不跳过任务覆盖检查。重新运行上述固定入口退出0。失败不是产品缺陷或产品测试失败；本记录保留其分类和处理，不以最终通过抹去过程。

```json
{
  "docs_version": "R4",
  "git_head": "4f47d10cd4d8deb0118e35198105f11bee754246",
  "markdown_files": 55,
  "local_links_checked": 921,
  "registered_tasks": 100,
  "historic_tasks": 4,
  "expanded_tasks": 96,
  "step_rows": 694,
  "test_specs": 63,
  "requirements": 36,
  "legacy_wp_mappings": 23,
  "gates": [
    "G-B",
    "G-D",
    "G-L",
    "G-N",
    "G-S0",
    "G-S1",
    "G-V"
  ],
  "dag": "acyclic",
  "initial_documents_preserved": 40,
  "protected_hashes_checked": 15,
  "modified_initial_docs": [
    "docs/flutter-migration/09-roadmap.md",
    "docs/flutter-migration/10-testing-release.md",
    "docs/flutter-migration/11-risks-experiments.md",
    "docs/flutter-migration/12-requirements-traceability.md",
    "docs/flutter-migration/agent-workflow.md",
    "docs/flutter-migration/CHANGELOG.md",
    "docs/flutter-migration/handoff.md",
    "docs/flutter-migration/README.md",
    "docs/flutter-migration/review.md",
    "docs/flutter-migration/start-prompt.md",
    "docs/flutter-migration/status.md",
    "docs/flutter-migration/decisions/ADR-0005-gates.md",
    "docs/flutter-migration/tasks/phase-0.md",
    "docs/flutter-migration/tasks/phase-1a.md",
    "docs/flutter-migration/tasks/phase-1b.md",
    "docs/flutter-migration/tasks/phase-backlog.md",
    "docs/flutter-migration/tasks/README.md",
    "docs/flutter-migration/tasks/task-template.md"
  ],
  "added_docs": [
    "docs/flutter-migration/beginner-guide.md",
    "docs/flutter-migration/evidence/EV-DOC-005.md",
    "docs/flutter-migration/task-map.md",
    "docs/flutter-migration/tasks/batch-record.md",
    "docs/flutter-migration/tasks/conditional-branches.md",
    "docs/flutter-migration/tasks/contracts-ownership.md",
    "docs/flutter-migration/tasks/phase-2.md",
    "docs/flutter-migration/tasks/phase-3.md",
    "docs/flutter-migration/tasks/phase-4.md",
    "docs/flutter-migration/tasks/phase-5.md",
    "docs/flutter-migration/tasks/phase-6.md",
    "docs/flutter-migration/tasks/phase-7.md",
    "docs/flutter-migration/tasks/phase-8.md",
    "docs/flutter-migration/tasks/phase-9.md",
    "docs/flutter-migration/tasks/releases.md"
  ],
  "errors": []
}
```

## 人工语义复核

收尾复验：更新status完成记录、handoff和review后再次运行同一入口，退出0、errors=[]；正文相对链接增为922，其余注册/字段/依赖/保护统计与上次一致。增加的链接是status到本证据的引用，不是新增产品验证。

自动检查只查结构/有针对性的义务词和依赖，不证明实现正确。逐项复读确认：C-02短串行控制派发、A03/A05真实归一化交付、A02磁盘快照到A07实际重启、P2/P5/P6锁等待均落实到任务步骤；G-N早期资料与TC-33后期平台不混记；公共夹具唯一A02维护，两端分入口；正式UI引用V02具体稿；未知字段/组件/原型处置有负责任务；两端、分支与集成、原型与生产证据分别记。后续任务均未运行/未授权，文档完成不表示用户批准架构或开发。

## 索引结果

GraphFlow增量索引已调用，rootDir为实际项目根。实际返回indexedFiles=25、indexedSymbols=296、indexedReferences=0；vectorBackfill missing=138、stale=0、refreshed=137，fingerprint=Xenova/bge-base-zh-v1.5@q8，budget limit=256/deadlineMs=2000。这是该次工具响应，不声称55份文档或全部向量均已索引；向量回填并未全完成。随后收尾状态/本证据定点索引响应另附。文档静态检查仍可独立复现；后续产品批次仍须按规则刷新context/plan/index。交付后停止，不进入PREP或产品开发。

收尾定点调用（同一rootDir、incremental；路径相对仓库）：

| 文件 | indexedFiles / symbols / references | 响应 |
| --- | --- | --- |
| docs/flutter-migration/status.md | 1 / 12 / 7 | skipped=false |
| docs/flutter-migration/handoff.md | 1 / 14 / 15 | skipped=false |
| docs/flutter-migration/review.md | 0 / 0 / 0 | skipped=true，reason=unchanged |
| docs/flutter-migration/evidence/EV-DOC-005.md | 1 / 14 / 93 | skipped=false |

上述是调用时点的结果；定点响应未给向量回填总量，不能据此声称先前剩余向量已补齐。本记录保存索引回执后会再定点提交本证据，不为记录自身的回执无限循环改写证据。

