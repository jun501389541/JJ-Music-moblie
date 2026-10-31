# 参考研究与复用边界

日期：2026-10-30，固定提交研究。F为上游代码路径，D为官方描述；本次没有成功获得可直接观察的Salt官方图像/运行交互，**不登记任何Salt O证据**。截图不可达/浏览器连接限制只影响观察，不是产品缺陷。后续视觉任务重新记录来源。

## 快照与许可

| 项目 | 固定快照 | 许可及使用范围 |
| --- | --- | --- |
| LX Mobile | `fb8480728d875fa5e0da25eebd3a26bb71723aae`；v1.9.1 | 根Apache-2.0，README另有补充协议与非商业性质说明；不按“仅Apache”推断任意复制可用 |
| LX Desktop | `ad95d5091c9ed689fa72b5e5c849df65f5a679ce`；v2.12.6 | 同上；协议学习与源码/素材复制分别判断 |
| SaltPlayerSource | `48b2fde247d6b5529fee14ebf0d4198c9436cd3d`；Android发布12.5.2 | 发布反馈仓库；根MIT不能概括未公开应用二进制/完整源码 |
| Salt Windows | 官方更新日志1.19.0（2026-10-17）；无应用源码SHA | 只研究公开文档；旧入口与首页版本卡不作为最高版本证明 |
| Harmonoid | `2b021f7b0b5dbcbe027aec010580977a2939a28d`；HEAD pubspec 0.3.34+9045，正式release另为v0.3.32 | 当前PolyForm Strict 1.0.0；不能直接复制修改分发；独立实现行为与边界思想 |

固定依据：[LX Mobile README](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/README.md)、[LX Desktop README](https://github.com/lyswhut/lx-music-desktop/blob/ad95d5091c9ed689fa72b5e5c849df65f5a679ce/README.md)、[Salt README](https://github.com/Moriafly/SaltPlayerSource/blob/48b2fde247d6b5529fee14ebf0d4198c9436cd3d/README.md)、[Harmonoid LICENSE](https://github.com/harmonoid/harmonoid/blob/2b021f7b0b5dbcbe027aec010580977a2939a28d/LICENSE)。

不复制受限代码、图标、截图或品牌素材到新产品。引用官方链接用于研究不等于再分发素材许可。候选依赖独立审计其许可及原生二进制。

## 研究矩阵

链接均对应上述提交或官方页面；建议列为P，不是已观察运行。

| 对象/证据 | 可确认行为 | 问题及JJ当前对应 | 建议/取舍 | 验收 |
| --- | --- | --- | --- | --- |
| [Mobile导航](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/src/screens/Home/Vertical/Main.tsx) | F：PagerView主内容与抽屉同步，不是已确认底部五栏 | 页面与状态保留；JJ现桌面侧栏 | 采用状态一致，独立选移动主导航 | TC-38/39 |
| [Mobile播放条](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/src/components/player/PlayerBar/index.tsx) | F：常驻信息控制、封面进入详情、键盘时策略 | 浏览中控制；JJ常驻PlayerBar | 采用；上滑/收起是JJ设计待验，不称观察所得 | TC-38 |
| [Mobile列表](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/src/components/OnlineList/List.tsx) | F：FlatList、长按多选、更多、错误页脚重试 | 触摸/大列表；JJ桌面选择菜单 | 采用基础动作，不搬全部菜单 | TC-31/38 |
| [Mobile调度](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/src/core/player/player.ts) | F：临时稍后列表和播放记录 | JJ当前队列+2历史 | 借鉴插播，保留JJ唯一队列模型 | TC-31/32 |
| [Mobile歌词](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/src/screens/PlayDetail/Vertical/Lyric.tsx) | F：封面/歌词分页、手动停止跟随及延时恢复 | 自动跟随与阅读冲突 | JJ建议明确恢复按钮，自动恢复可选；不照搬计时 | TC-34/38 |
| [Mobile搜索](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/src/screens/Home/Views/Search/index.tsx) | F：来源、建议、历史、分页/错误状态 | JJ本地/在线独立范围 | 采用流程，不把热词/同步全纳MVP | TC-33/38 |
| [Desktop壳](https://github.com/lyswhut/lx-music-desktop/blob/ad95d5091c9ed689fa72b5e5c849df65f5a679ce/src/renderer/App.vue) | F：侧栏/内容/播放条/详情，浏览器音频 | JJ相近Electron布局 | 保留桌面预期，不当Flutter/原生WASAPI模板 | TC-39 |
| [Salt曲库](https://moriafly.com/program/spw/doc/music-library) | D：导入、分类、多选与文件管理说明 | JJ已有目录与分类 | 借鉴输入，保留JJ目录/移除语义 | TC-35/39 |
| [Salt外观](https://moriafly.com/program/spw/doc/appearance.html)、[更新](https://moriafly.com/program/spw/changelog) | D：歌词/封面收起、迷你条、材质及降级说明 | JJ歌词与外观偏好 | 作为候选；尺寸/颜色/动效独立出稿，不能虚构观察 | V01/TC-38/39 |
| [Salt音频](https://moriafly.com/program/spw/doc/audio-engine.html) | D：SMTC、输出与专业选项 | JJ输出/EQ/频谱 | SMTC需求采用；ASIO/独占非首版 | TC-40/41 |
| [Harmonoid播放条](https://github.com/harmonoid/harmonoid/blob/2b021f7b0b5dbcbe027aec010580977a2939a28d/lib/features/now_playing/now_playing_bar.dart) | F：分端布局；部分平板分支未实现 | 不机械缩小桌面UI | 采用共享状态+分端壳，独立实现 | TC-38/39 |
| [Harmonoid播放核心](https://github.com/harmonoid/harmonoid/blob/2b021f7b0b5dbcbe027aec010580977a2939a28d/lib/core/media_player/media_player.dart) | F：media_kit/libmpv；系统控制分平台，含私有子模块依赖 | JJ AudioEngine与系统媒体 | 作为候选证据，不证明全部可复现/音源后台兼容 | A03—A07、B01—B08 |

LX Mobile是React Native，不是Flutter模板；Mobile/Desktop当前注入API均2.0.0，但env分别mobile/desktop，请求与宿主不等价。只考虑已合并固定提交；未合并PR与计划不登记为能力。

## 未采用与待观察

- 账号同步、创意工坊、全部专业输出、SPL光效等不转成首版要求。
- Salt官网 [Android](https://saltplayer.com/)、[官方Play](https://play.google.com/store/apps/details?id=com.salt.music)、[官方Windows商店截图入口](https://store.steampowered.com/app/3009140/Salt_Player_for_Windows/)保留供视觉阶段观察。图像只证明外观，不能证明手势、动画、异常处理。
- 新观察记录日期、版本、来源与可见范围；资料不足仍可独立设计，但必须标P/H。不为研究安装或执行不明软件。
