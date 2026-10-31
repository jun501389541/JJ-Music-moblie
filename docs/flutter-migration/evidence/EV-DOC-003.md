# EV-DOC-003：R3.2横向事项补充审阅证据

日期2026-10-30；任务DOCSET-03；需求R-02/17/19/22/24/26—31；等级L0；DOC-01—05。仅文档/静态源码与公开资料证据，新增TC-47—55只有规格，全部产品TC未运行。

## 基线、输入与授权

cwd为实际仓库根`<repo>`；Windows/PowerShell、Git、Python 3.14.7。实际只读核对`git status --short`、`git branch --show-current`、`git rev-parse HEAD`、`git log -1 --format=%cI`、`git ls-remote origin HEAD refs/heads/main`与package版本：main，完整SHA `4f47d10cd4d8deb0118e35198105f11bee754246`，提交时间2026-10-30T09:02:44+08:00，远程HEAD/main同SHA，package0.7.1。开始已有38份未跟踪Markdown，status仅`?? docs/flutter-migration/`，无tracked差异。未将整个目录当作本轮新增后覆盖。

AUTH-DOC-R32-20261030仅本次六项覆盖核查/相关文档及校验；不改产品/AGENTS，不安装、不执行脚本/音源或私人数据、不提交推送发布。开始保存38文件及AGENTS的SHA-256快照；旧EV-DOC-001/002及P1 A/B详细任务保持原字节，固定输入摘要在下方脚本中。保留原架构/风险门，未在P1新增任务或验收项。

GraphFlow context先行，实际rootDir、recordDialogue=false，返回15条summary/15 anchors、compressedTokens1024/tokenBudget1500；结果多为.cache编译产物且与六项不够相关，未读取那些产物或私人数据，改为已知文档/源码路径定点读取。plan返回agent-delegated（无服务商LLM密钥），已提交intent与inspect→revise→verify三步串行DAG并merge，complete=true、missing=[]；未把启发式建议当最终计划，未安装或配置密钥。变更后index响应在末节登记。

## 实际资料读取与限制

定点读03/04/08/10/11、任务/状态/交接及相关审计；读`src/main/library/music-library.ts`扫描/身份/元数据、renderer local-search/LibraryView/SearchView/use-search-suggest实际调用、App.onDrop→preload→main IPC.filesDropped与second-instance、data-location/electron-builder、download-manager.remove、cache-budget/resource-cache/online-diagnostics及导出IPC。追加代码事实在01，语义判断在review RV-16—21，未把注释、类型或仅存在模块当运行证明。

只读查看`src/test/local-search.test.mts`作为后续golden依据，**没有执行**。初始定位中不存在的test/tests路径、未展开的PowerShell通配路径与假定SearchBox文件产生检索错误；改用`rg --files`定位到src/test与实际组件，未把定位失败当产品问题或测试结果。

2026-10-30实际核阅[Android备份官方说明](https://developer.android.com/identity/data/autobackup)及[Windows包装官方说明](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/packaging/)。只支持08/10的配置/时点建议，不证明任何包或厂商恢复已通过；实施时按实际SDK/系统/包装/渠道复核。没有访问账号/个人云盘/音乐/脚本。Windows页面包含授权导航提示但正文可读，只采用可读正文，不绕过访问控制。

## 可复现文档校验

复用不可变EV-DOC-002的只读Python正文作为固定输入，不覆盖或重写旧结果；仅在本次运行内调整版本集合，再加R3.2语义/范围断言。工作目录`<repo>`，工具Python 3和Git。提取本记录唯一python围栏经`python -`标准输入执行即可，不创建工程或脚本文件、不安装依赖；预期errors=[]且退出0。历史EV中的计数是当时快照，不要求与本次相同。

实际执行入口（PowerShell，cwd `<repo>`；其他shell可等价提取后送标准输入）：

```powershell
@'
from pathlib import Path
s = Path('docs/flutter-migration/evidence/EV-DOC-003.md').read_text(encoding='utf-8')
f = chr(96) * 3
code = s.split(f + 'python\n', 1)[1].split('\n' + f, 1)[0]
exec(compile(code, 'EV-DOC-003.md:python', 'exec'))
'@ | python -
```

```python
from pathlib import Path
import re, json, hashlib

legacy_path = Path('docs/flutter-migration/evidence/EV-DOC-002.md')
legacy_hash = '75d5ea8510e189c944d0c5aad1e9c92e82963a881625140cdf91804a50321d26'
assert hashlib.sha256(legacy_path.read_bytes()).hexdigest() == legacy_hash, 'historical EV-DOC-002 changed'
fence = chr(96) * 3
legacy = legacy_path.read_text(encoding='utf-8')
code = legacy.split(fence + 'python\n', 1)[1].split('\n' + fence, 1)[0]
updates = {
    'range(1,47)': 'range(1,56)',
    'range(1,26)': 'range(1,32)',
    "['DOCSET-02']": "['DOCSET-03']",
    "{'DOCSET-01','DOCSET-02'}": "{'DOCSET-01','DOCSET-02','DOCSET-03'}",
}
for old, new in updates.items():
    assert old in code, 'unexpected legacy checker: ' + old
    code = code.replace(old, new)
namespace = {}
exec(compile(code.split('result = dict', 1)[0], 'EV-DOC-002-adapted', 'exec'), namespace)
check = namespace['check']
rows = namespace['rows']
texts = namespace['texts']
root = namespace['root']
protected = {
    'docs/flutter-migration/evidence/EV-DOC-002.md': legacy_hash,
    'docs/flutter-migration/tasks/phase-1a.md': '3944813090af6a55bc7682b2a88afa2c1f94293b09e5db67a147d3e2ffcad474',
    'docs/flutter-migration/tasks/phase-1b.md': '3f748d4861dbed2d4ce84e143ee3616f93ff3e30a181bfa4a584f8af9f5ba5cf',
}
for name, digest in protected.items():
    check(hashlib.sha256(Path(name).read_bytes()).hexdigest() == digest, 'protected changed: ' + name)
gates = [r[0] for r in rows('09-roadmap.md') if re.fullmatch(r'G-[A-Z0-9]+', r[0])]
check(len(gates) == 7 and set(gates) == {'G-L','G-V','G-N','G-B','G-S0','G-S1','G-D'}, 'risk gates changed')
check(len([k for k in namespace['graph'] if re.fullmatch(r'A\d+|B\d+[ab]?', k)]) == 18, 'P1 task count changed')
for row in rows('10-testing-release.md'):
    if re.fullmatch(r'TC-(?:4[7-9]|5[0-5])', row[0]):
        check(not re.search(r'\b(?:A\d+|B\d+[ab]?)\b', row[2]), 'new test assigned to P1: ' + row[0])
backlog_rows = [r for r in rows('tasks/phase-backlog.md') if re.fullmatch(r'WP-[A-Z0-9-]+', r[0])]
check(len(backlog_rows) == len(namespace['wp']) and {r[0] for r in backlog_rows} == namespace['wp'], 'WP index mismatch')
for row in backlog_rows:
    check((namespace['refs'](row[3], 'TC') | namespace['refs'](row[3], 'DOC')) <= namespace['tests'], 'unknown WP test: ' + row[0])
trace_tests = set()
for row in namespace['requirements']:
    trace_tests |= namespace['refs'](row[4], 'TC')
check({f'TC-{n:02}' for n in range(47,56)} <= trace_tests, 'new tests untraced')
for name in ['03-product-rules.md','08-data-migration.md','10-testing-release.md']:
    check('提案' in texts[root/name] or '分类P' in texts[root/name], 'proposal not marked: ' + name)
review = texts[root/'review.md']
check(all(x in review for x in ['RV-16','RV-17','RV-18','RV-19','RV-20','RV-21','已充分覆盖','不适用本期']), 'review coverage')
check('不增加A/B任务或风险门' in texts[root/'tasks/README.md'], 'P1 scope statement missing')
errors = namespace['errors']
result = dict(markdown_files=len(namespace['files']), local_links=namespace['links'], detailed_tasks=len(namespace['graph']), future_work_packages=len(namespace['wp']), test_specs=len(namespace['tests']), requirements=len(namespace['requirements']), task_dag_acyclic=not namespace['pending'], p1_detailed_tasks_unchanged=True if not any('protected changed' in e for e in errors) else False, risk_gates=len(gates), tracked_changes=bool(namespace['tracked']), untracked_markdown_files=len(namespace['untracked']), errors=errors)
print(json.dumps(result, ensure_ascii=False))
raise SystemExit(bool(errors))
```

该检查覆盖文件链接、注册编号/基本追踪、详细任务字段、DAG、P1文件/门与保护摘要；不能证明自然语言全部正确、图像/锚点渲染、未来代码、IME/厂商备份等运行能力。初始38文件完整哈希比对另在本轮会话执行，确认无未授权文件变化；不能只凭Git未跟踪状态证明保留。

## 实际结果与人工语义核查

首轮退出0：39份Markdown/134本地链接/26详细任务/23远期工作包/60测试规格/31需求、DAG无环、P1任务未变、7门、无tracked变更、errors=[]。随后补上review到新证据的链接并核对行为提案，复验退出0，实际JSON：

```json
{"markdown_files":39,"local_links":135,"detailed_tasks":26,"future_work_packages":23,"test_specs":60,"requirements":31,"task_dag_acyclic":true,"p1_detailed_tasks_unchanged":true,"risk_gates":7,"tracked_changes":false,"untracked_markdown_files":39,"errors":[]}
```

60是55项产品TC规格+5项文档检查，不是60个产品测试通过。Python/PowerShell环境还输出InitializeDefaultDrives及Python位置提示；实际正文产生上述JSON且退出0，提示不作产品成功/失败证明。

人工定点语义核对：

1. 六项判断均为部分覆盖（其中系统备份分类有实际文档缺口），已有资源/下载/升级/脱敏/证据规则只引用；01补证不称产品缺陷复现。
2. 03保留两种搜索算法、mtime排序、拖放导入及二次聚焦；可选关联/分享、IME时机、保旧标签策略、存储期限、支持范围与诊断预览均单独标提案，非静默“修复”。
3. 08清理保护活跃旧轨/预载/part/导入/待写入及用户确认资料；满盘有限处理，不能承诺最后一次检查点写入必成功；扫描不可访问不等于删除，不做内容合并。
4. 新TC-47—55无P1任务归属，新增3个WP仍待阶段前细化；G-N TC-46/13、后期TC-23/33与A02冻结/双端入口规则保留，无新全局门。
5. 首个Android对外包的适用安全验收不等P8，但不要求本地MVP增加多渠道、完整更新器/备份、Android分享或诊断导出UI。Windows包装/备份/可选入口留P7/P8，各自范围展开。
6. 系统备份和Windows外部复制不承诺自动脱敏/授权有效；秘密不写交接，默认不上传、不建遥测；诊断测试/开发证据复用原规范，无第二份接口/任务状态。

初始38文件哈希比对：16份相关既有文档修改，22份原文档字节不变，新增仅本证据。改变列表为01-current-repository.md、03-product-rules.md、04-playback-interaction.md、08-data-migration.md、09-roadmap.md、10-testing-release.md、11-risks-experiments.md、12-requirements-traceability.md、CHANGELOG.md、handoff.md、README.md、review.md、status.md、tasks/phase-0.md、tasks/phase-backlog.md、tasks/README.md。未删除文件；EV-DOC-001/002、AGENTS、phase-1a/1b摘要均保持；未变的架构/音频/Broker/音源/下载合同不另写一份。

## 索引及未运行项

本次增量index实际返回indexedFiles=9、indexedSymbols=98、indexedReferences=0；vectorBackfill missing=107、refreshed=107，证明该次预算内回填完成，不外推为39文件逐份完整索引或任何产品能力。随后对16份修改及1份新增逐文件index：03-product-rules.md与review.md各indexedFiles=1、skipped=false；其余15次返回skipped=true、reason=unchanged。最后保存本记录后再定点index本文件，不递归倒改本节历史计数。

未运行产品套件、Flutter/Android/Windows构建、源/受控脚本、系统备份恢复、文件关联/设备/听感。所有产品TC与门保留未通过；预算、日志期限、支持范围、外部动作与发行政策仍是待审提案。本轮完成后停止，等待用户审核。
