# 当前仓库审计快照

分类：F（静态代码事实）与 D（发布记录）分别标识；日期 2026-10-30。后续执行者必须刷新实际状态，不修改本快照来掩盖差异。

## 基线

| 项目 | 结果 |
| --- | --- |
| 分支 | main |
| HEAD／远程 HEAD／远程 main | `4f47d10cd4d8deb0118e35198105f11bee754246` |
| 提交时间 | 2026-10-30 09:02:44 +08:00 |
| 版本 | package.json 0.7.1 |
| v0.7.1 标签 | `0e56c2f3150f257ed7fee45d5b2b797b1898c856` |
| 开始工作区 | 干净；目标文档目录不存在 |
| 本轮运行验证 | 只读 Git/文件/官方资料及文档一致性检查；未运行产品测试/构建/音源 |

HEAD 比发行标签多一次发布记录文档提交，不得混写。固定浏览入口：[代码基线](https://github.com/jun501389541/JJ-Music/tree/4f47d10cd4d8deb0118e35198105f11bee754246)。

## 构建、依赖与真实装配

F：Electron/Vue3/TypeScript/Pinia/Vue Router；`src/main/index.ts:createServices` 装配 SettingsStore、PlaylistStore、MusicLibrary、PendingAssetStore、SourceEngine、资料服务、DownloadManager；`registerIpc` 注册特权调用，应用 ready 后创建主窗口。preload 的 `invoke` 通过有限 `window.jj` API，renderer 无通用 Node 入口。

关键资料：[package](../../package.json)、[main](../../src/main/index.ts)、[preload](../../src/preload/index.ts)、[shared IPC](../../src/shared/ipc.ts)、[router](../../src/renderer/src/router/index.ts)。

构建：`build` 先原生启动器再 electron-vite；`verify` 为类型检查、生产构建、测试、门禁；`test:online`、E2E、真实设备另行。打包 NSIS/ZIP，source-host 及依赖按规则解包，不能以开发目录运行代替成品。

离线测试通过 [build-test](../../tools/build-test.mjs) 打包生产源，由 [run-tests](../../tools/run-tests.mjs) 使用自有音乐夹具；JJ provider 库存测试被 runner 明确退役。CI 包含 Windows/native/成品合成与打包；安装升级需显式选择一次性环境。[CI](../../.github/workflows/ci.yml)、[builder](../../electron-builder.yml)。

D：[v0.7.1 发布记录](../development/2026-10-30-v0.7.1-release.md)报告 141/141 套件、5/5 门禁等通过；本轮未重跑。真实源、物理网络、设备、听感仍有边界。历史通过数不是 Flutter 证据。

## 功能—调用—数据—迁移矩阵

下列现存测试是可查覆盖意图，**未在本轮运行**。阶段定义见路线图；详细任务和远期工作包见任务索引。

| 功能／入口 | 实际链路／关键文件符号 | 数据 | 平台依赖 | 证据 | 迁移方式／阶段 |
| --- | --- | --- | --- | --- | --- |
| 曲库扫描／添加目录 | `main/index → MusicLibrary.scanFolders/readTrack`，`main/library/music-library.ts` | index v5、路径、标签、assets | Node fs、music-metadata | library、scan-concurrency | Dart 扫描策略＋文件/元数据适配；P2 |
| 本地搜索／搜索页 | `createLocalSearchIndex`，`renderer/src/utils/local-search.ts` | NFKC、标题/歌手/专辑、全拼/首字母 | pinyin-pro | local-search | 保留排序/分词 golden；P2 |
| 缺失／重新定位 | `MissingFiles`、RelinkCandidates、commit/recoverLocalRelink、BatchRelink | 库/歌单/最近/会话引用与日志 | 路径、文件选择、权限 | missing-files、local-file-relink、batch-file-relink | 共享事务＋URI/路径适配；P5/P7 |
| 本地播放／列表 | 页面 `playQueue → playTrackAt → toMediaUrl → WebAudioEngine` | 原条目、队列、会话 | jjmedia、HTMLAudio、WebAudio | player-regression、playback | 共享意图/模式＋Backend；P1-A/P2 |
| 搜索试听 | `SearchView.playAt` 只传单曲＋singleTrackAudition | 单曲队列、试听标记 | 输入/UI | search-view-playback、player-regression | 平台输入映射同一意图；P2 |
| 列表全部 | 搜索仅已加载结果；普通歌单筛选选曲映射完整歌单 | 有序快照 | 页面状态 | playlist-track-filter、search-view-playback | 页面明确范围，不统一改成筛选队列；P2/P4 |
| 队列/历史/模式 | `player.playQueue/rememberQueue/playQueueSnapshot/handleEnded` | 当前＋2历史，list/repeat/single/random | 无核心平台依赖 | player-regression | Dart 唯一所有权；P2 |
| 最近/恢复 | `recordAudibleTrack/writeSession`；playing 后记录，启动暂停恢复 | 最近100、LastSession位置 | 退出与定时持久化 | persistence/playback/player | 确认去重、R1/R2/R3；P1-A/P2 |
| EQ/频谱/速度/渐变 | `WebAudioEngine`、CrossfadeController、commit/rollbackCrossfadeHandoff | 双轨、独立增益、预留下一首 | WebAudio | audio-engine-crossfade、crossfade-controller | 能力接口/逐轨合同；P8；当前不承诺gapless/exclusive |
| 输出 | OutputDevicePicker、AudioEngine 设备接口 | 本机设备/远端选择 | Chromium/OS/设备 | output/dlna系列 | 平台能力；P1-A/P7/P8 |
| 歌词解析/切源 | `player.loadLyrics → lyric-service/parseLyrics` | LRC、tlyric、rlyric、LX增强 | fs/HTTP/脚本 | lyric-source、local-lyric-cache、format | Dart parser/来源/局部UI；P2/P6 |
| 封面 | `MusicLibrary.readTrack`、cover-fetch、online-asset-cache | 内嵌、sidecar、内容缓存、来源 | 图像/标签/HTTP | cover/provenance系列 | 内嵌封面优先；P2/P6 |
| 待写入/编辑 | stageFetchedLyric、PendingAssetStore、commitAssetWrite、asset-export | 选择快照、拒绝指纹、目标 | 文件句柄与标签 | pending-asset/asset-write系列 | CAS消费，原文件写入需明确；P6 |
| 资料浏览 | OnlinePlatformRegistry、SearchRouter、ChartsService、PlaylistSearchService | 原生ID、修订、partial/stale | HTTP/平台格式 | builtin-gate、search-router、charts | 目录与音源分开；G-N/P4/P6 |
| 歌单导入/刷新 | playlist-import/previews、LibraryRouter、PlaylistRefresh | token、顺序/子集、完整性、revision | HTTP | playlist-import/refresh系列 | 共享预览与CAS；P5/P6 |
| LX | SourceStore→SourceEngine→SourceRuntimeHost→source-host | 脚本、能力、摘要/代次 | Node/shims/native helper | source-* | 兼容层＋独立宿主；P1-B/P4 |
| jj-source | JjProviderEngine模块与shared声明存在，main未装配；旧路由返回unavailable | 库存类型/实现 | JS host | runner退役该套件 | 非生产能力，不作为替代现状；暂缓 |
| 在线播放 | player.resolveOnlinePlayback→music.url IPC→PlaybackRouter→LX→SourceMediaProxy→引擎 | 原条目/本次资源分离 | 解析/网络/解码 | resolver/media/player系列 | Dart策略＋Broker＋Backend；P4 |
| 下载 | UI→IPC→DownloadManager，strict解析→part→校验→stage/tag副本→publishExclusive→importCompleted | downloads.json、验证器、来源版本、入库状态 | HTTP/文件/标签 | downloads-import、download-library等 | 独立后台与单写入者先验；P1-B/P5 |
| JSON备份恢复 | PlaylistBackup/Restore→预览token→新增恢复歌单 | v1白名单，不含全部应用数据 | 文件选择 | playlist-backup/restore | 兼容导入，不覆盖系统歌单；P5 |
| 桌面歌词/托盘/键盘 | DesktopLyrics透明窗口；main托盘；App.onKeydown；media-session composable | 设置/歌词payload | Electron/Windows | desktop-lyric/原生记录 | 平台适配；P7；Android浮窗不默认加入 |
| 更新 | UpdateService、签名清单、显式下载安装 | 版本/摘要/签名 | Windows安装形态 | update系列 | Flutter独立通道；P7/P8 |
| DLNA | OutputDevicePicker→DlnaEngine→service/session→LAN lease | 设备/会话/代次 | SSDP/SOAP/LAN/设备解码 | dlna系列，仅模拟/合成 | 实验性MP3；自然到尾缺口见下；P8 |

关键文件均在 `src/main`、`src/preload`、`src/renderer`、`src/shared` 的真实装配链，不将未接入模块当功能。

## 重要边界

F：`online/platform-registry.ts:platforms/allows` 只查静态能力表，`eligiblePlatforms` 才按源判断播放能力。无源可以搜索/榜单/歌单资料浏览；播放/下载地址解析才需源。旧 consent 字段与部分注释已退役。

| 平台 | 搜索/歌单搜索/导入/封面/榜单 | 热词 | 平台歌词 | 艺人图 | 艺人/专辑详情 |
| --- | --- | --- | --- | --- | --- |
| tx | 有 | 有 | 有 | 有 | 无 |
| wy | 有 | 有 | 有 | 有 | 有 |
| kw | 有 | 有 | 有 | 无 | 无 |
| kg | 有 | 有 | 无 | 有 | 无 |
| mg | 有 | 无 | 有 | 有 | 无 |

F：本地歌词 sidecar→内嵌→持久待写入选择→在线；封面则内嵌优先sidecar，不能套同一顺序。写入仅成功消费对应快照；现有内嵌写入主要 MP3/FLAC。

F：脚本 API 2.0.0、env desktop；真实 CommonJS/Node与原生fetch存在，guard 不涵盖脚本所有网络。现有 SAFER/Job/helper 是故障隔离与部分收敛，不是完整沙箱。

F：下载在当前进程退出时取消，load将中断任务标失败可重试；`abortable(resolve(...))` 不等于已向底层解析传递取消。迁移必须补端到端取消合同，不能继承表面状态。

F：DLNA实际已接入，MP3和曲首重载，返回本机暂停。`session-manager.ts:naturalEnd` 为可选回调，service未提供；因此不能声明自然结束自动连播已接通。源/设备/网络/听感未验。

## 五条真实流程

```mermaid
flowchart LR
  A[本地列表意图] --> B[player.playQueue/playTrackAt]
  B --> C[原本地路径与jjmedia授权Range]
  C --> D[HTMLAudio解码与WebAudio输出]
  D --> E[当前代次playing确认与最近]
```

```mermaid
flowchart LR
  A[在线资料原条目] --> B[统一档位与同版本候选]
  B --> C[PlaybackRouter和LX脚本解析]
  C --> D[主进程签发jjstream不透明资源]
  D --> E[代理URL/DNS/Range验证与传输]
  E --> F[引擎解码与playing确认]
  F --> G[原条目最近及在线收集]
```

```mermaid
flowchart LR
  A[下载所选档位] --> B[strict解析与part验证]
  B --> C[有界下载和容器规格校验]
  C --> D[stage与标签副本]
  D --> E[独占发布不覆盖]
  E --> F[单独入库及可重试结果]
```

```mermaid
flowchart LR
  A[本地优先及在线歌词] --> B[显示与采用]
  B --> C[持久待写入快照]
  C --> D[用户明确写入目标]
  D --> E[释放文件占用和串行写入]
  E --> F[重读索引并消费对应快照]
```

```mermaid
flowchart LR
  A[主动发现DLNA] --> B[设备和MP3能力]
  B --> C[会话和设备绑定LAN租约]
  C --> D[设备取媒体并解码]
  C --> E[SOAP控制与URI/推进证据]
  E --> F[确认远端playing]
```

资料、播放地址解析、媒体传输、音频解码是四层；远端由设备解码。播放命令成功不等于已经确认播放，协议证据也不等于人耳验证出声。

## R3.2横向事项定点补证（2026-10-30）

基线仍为`4f47d10cd4d8deb0118e35198105f11bee754246`，本节追加源码事实，不改写前次运行证据。本次只读以下调用/配置，没有执行测试、源或私人资料。

| 事项 | F／实际文件与符号 | 能证明/不能证明 |
| --- | --- | --- |
| 缓存预算与用户资料 | [cache-budget.ts](../../src/main/online/cache-budget.ts)：总256MiB、coverBytes192MiB、lyrics16MiB、diagnostics2MiB；[resource-cache.ts](../../src/main/online/resource-cache.ts):ResourceCache只存派生资料；[index.ts](../../src/main/index.ts):IPC.onlineCacheClear实际清自动缓存 | 已有缓存边界，不等于Flutter已实施，也不证明所有part/临时目录有统一回收 |
| 删除下载 | [download-manager.ts](../../src/main/downloads/download-manager.ts):remove等待传输/入库settled（有界），deleteFile显式区分，已拥有sidecar与音频走trash，失败保记录 | 记录删除与音频删除已分开；非Android删除/回收站能力证明 |
| 扫描身份与失败 | [music-library.ts](../../src/main/library/music-library.ts):addFolders、scanFolders、walk、hashPath；根字符串去重，seen按路径去重；size/mtime增量；4解析并发按遍历次序提交；取消/不可读目录限制移除；hashPath对lowercase路径做SHA-1截16位，readTrack标签失败保文件名 | 无内容自动合并；不证明junction、Unicode等价、云占位或大小写敏感卷已全面支持。walk只处理Dirent.isDirectory/isFile，未跟随链接的实际平台差异仍待验 |
| 搜索与排序 | [local-search.ts](../../src/renderer/src/utils/local-search.ts):createLocalSearchIndex；[LibraryView.vue](../../src/renderer/src/views/LibraryView.vue):filtered；[SearchView.vue](../../src/renderer/src/views/SearchView.vue):runSearch/loadMore；[use-search-suggest.ts](../../src/renderer/src/composables/use-search-suggest.ts):onKey；[local-search.test.mts](../../src/test/local-search.test.mts) | 两入口算法不同；前者NFKC/拼音/分词/rank，后者小写整串、mtime排序。网络请求有abort/generation；本次未验证IME或跨ICU排序，注释不是输入法证明 |
| 外部输入与实例 | [App.vue](../../src/renderer/src/App.vue):onDrop→[preload/index.ts](../../src/preload/index.ts):importDroppedFiles→main IPC.filesDropped；main requestSingleInstanceLock/second-instance | 拖放只导入和刷新，目录需确认；第二实例只聚焦，不转交argv播放。所查配置未见fileAssociations，主入口未见open-file；不把新增关联当迁移保留 |
| 包装与数据位置 | [electron-builder.yml](../../electron-builder.yml)：com.jjmusic.desktop、NSIS/zip；[data-location.ts](../../src/main/data-location.ts):resolveDataDir、relocationProblem | 旧安装/便携及switch/pointer等数据位置须尊重；Flutter标识尚未确定，不等于可共库/共更新通道 |
| 诊断导出 | [online-diagnostics.ts](../../src/main/online/online-diagnostics.ts):safeEvent、record/export重建白名单，最多500条/约2MiB；main IPC.onlineDiagnosticsExport经保存对话框写JSON；[SettingsView.vue](../../src/renderer/src/views/SettingsView.vue):onlineDataAction | 现有在线诊断已集成且有限额，不能写成完全缺失；未见本次建议的完整构建/后端/资源摘要或导出预览，也未据此证明所有旧日志脱敏 |

本节链接为当前工作树定点入口，固定提交浏览根见本章开头；语义选择在03、数据与清理在08、诊断/分发在10，避免审计表变成另一份规则。
