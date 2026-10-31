# EV-DOC-001：通用文档交付证据

日期：2026-10-30；任务DOCSET-01；等级L0。仅支持文档交付结论，不支持任何Flutter产品能力通过。

## 基线与范围

cwd为实际仓库根，文档使用相对路径。Git main，完整SHA `4f47d10cd4d8deb0118e35198105f11bee754246`；package0.7.1；远程HEAD/main同SHA，标签v0.7.1为`0e56c2f3150f257ed7fee45d5b2b797b1898c856`。开始status空，目标目录不存在。只新增本目录Markdown。

执行只读命令：`git status --short`、`git branch --show-current`、`git rev-parse HEAD`、`git log -1 --format=fuller`、`git ls-remote origin HEAD refs/heads/main refs/tags/v0.7.1`、目录存在检查和定点文件读取；均取得上述结果。规则AGENTS.md未改。

## GraphFlow

context实际使用本次仓库绝对rootDir，recordDialogue=false，返回9 anchors、compressedTokens1402、估计节省97%；未提供accountedTokens，不能报告完整交付token成本。上下文仅作索引线索，历史决策不作当前功能证明。

plan返回agent-delegated而非最终计划；已提交intent和串行6步DAG并merge，complete=true；未出现必须解答的challenges。没有把本地启发式列表当完成计划，也未依赖外部agent私有聊天。

增量索引实际成功返回：indexedFiles=28、indexedSymbols=222、indexedReferences=0。vectorBackfill报告missing=280、refreshed=243，存在预算/截止限制；不能据此宣称全部文档都完成向量回填。工具未给逐文件清单，所以也不把28解释为36份交付文档全部索引证明。后续以仓库文件为权威，按需定点读取/补索引。

补充复验：更新状态/证据后再次增量索引，返回indexedFiles=27、indexedSymbols=212、indexedReferences=0；当次vectorBackfill missing=53、refreshed=53。它证明该次回填工作成功，不将文件计数外推为整个文档集逐文件完整性。最后本记录更新后再定点索引本文件。

## 实际文档检查

cwd：仓库根；环境：PowerShell、Git、Python3.14.7；没有安装依赖。用PowerShell here-string经标准输入运行Python只读检查；读取全部Markdown，解析本地链接/任务表/依赖/字段/测试/需求，并调用Git列修改范围；任何errors非空退出1。实际退出0，结果如下：

```json
{"markdown_files":36,"local_links":84,"detailed_tasks":24,"future_work_packages":20,"test_specs":50,"requirements":24,"task_dag_acyclic":true,"changed_files":36,"errors":[]}
```

50是45个产品TC规格和5个文档检查ID，**不是50项产品测试通过**。脚本检查所有详细任务定义都有12项字段，任务和status条目集合相同，任务图无环，24条需求都有任务/工作包和测试引用。

| 检查 | 实际结果与限制 |
| --- | --- |
| DOC-01 | 36文件UTF-8、围栏、84本地链接/代码文件及个人绝对路径检查无错误；外部网页可用性不由此证明 |
| DOC-02 | 24详细任务、20远期工作包、定义/状态集合、依赖解析/DAG和字段检查通过；不替代后续阶段具体技术拆分 |
| DOC-03 | 人工逐条比对：仅方向已确定，ADR候选待审，产品门全未通过，真实源/视觉独立；补明B09非G-B签发前置，避免隐性互等；无独立审阅者背书 |
| DOC-04 | 需求R-01—24覆盖、测试注册、任务/工作包引用检查通过；验收规格不是执行结果 |
| DOC-05 | `git diff --exit-code -- AGENTS.md src package.json package-lock.json .github electron-builder.yml`退出0；Git仅36个本目录新文件，原规则/产品未改；索引结果如上 |

环境输出有PowerShell驱动初始化和Python定位提示；检查程序仍实际运行、输出上述JSON并退出0。它们是环境提示，不判作产品回归或把未执行误作成功。

复验步骤（任意具备等价文本能力的工具可替换Python）：读取本目录所有md→检查相对链接/围栏/绝对路径→从tasks/README的详细任务表构建图并拓扑检查→比对任务定义12字段和status集合→检查45TC/5DOC与24R覆盖→Git范围断言。对后续修改应重新执行，不直接沿用这份旧结果。

最终复核：相同结构校验再次退出0、统计未变；`git diff --check`和受保护路径diff退出0；未留下待追加占位记录；36个新增文件均Markdown，tracked changes=0。只有DOCSET-01为done，其他产品任务无完成声明。用户在文档收尾时要求继续执行，未据此新增产品开发授权。

## 明确未执行

产品类型检查/构建/离线套件、Flutter工程或依赖安装、JS执行、真实源、个人资料、真机/投放/听感、安装升级、提交推送发布。未执行不是通过；本记录不能支持任何产品门为passed。
