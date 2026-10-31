# Windows事件归一化：系统WinRT MediaPlayer

2026-10-31；Windows11/VS18/MSVC14.51/Windows SDK10.0.26100，C++20，x64。使用系统MediaPlayer与编解码器，本工程没有下载mpv/FFmpeg/Rust DLL。仅自编译薄桥，无原生业务队列。

来源：[MediaPlayer/PlaybackSession](https://learn.microsoft.com/en-us/uwp/api/windows.media.playback.mediaplayer)、[手动SMTC](https://learn.microsoft.com/en-us/windows/apps/develop/media-playback/system-media-transport-controls)。原生MediaOpened/Ended/Failed回调仅保存原子标记；Dart平台线程以100ms轮询取样，后台回调不触碰Flutter事件sink。样本state是桥的简化码，nativeState保留原始WinRT枚举；旧早期日志无nativeState，不能混称全回调日志。

| 维度 | 本端真实API与项目归一化 | 实际结果/限制 |
| --- | --- | --- |
| ready | MediaOpened标记及对应MediaPlayer，不代表播放 | 实际opened/ready、nativePlaying=false、position0 |
| 项目playing | 同handle已MediaOpened，PlaybackSession.PlaybackState为Playing；当前播放派发资格仍有效；两次直接Position采样推进，非Dart插值；共享层再校验身份/代次 | windows-local-final.log原生推进序列与共享确认通过；不是套用Android同名布尔 |
| 缓冲/暂停恢复 | WinRT Buffering→样本state2，不确认；Paused/Opening不确认；pause/seek重置推进窗口；同handle恢复不重记 | 实际pause/seek/resume通过；本地短WAV未稳定诱发长buffering/加载卡住，真实缓冲暂停反例未验 |
| progress/结束/错误 | 直接Position/NaturalDuration；MediaEnded原子标记且仍有播放资格才自然结束；MediaFailed与调用异常绑定handle | 自然结束/坏文件/快速停止、切歌失败恢复旧轨通过；未知时长/真实旧回调迟到并未逐项诱发 |
| 释放 | 主线程先撤回调并显式MediaPlayer.Close，再移除handle/返回receipt；不等析构延迟，不把Cancel当release | 消费者归零，Windows自有文件在释放后rename成功；重复关闭Future红绿测试 |
| 系统/业务 | 每轨CommandManager及自动SMTC禁用；窗口唯一SMTC仅镜像共享确认状态；Button/Seek回调进有界线程安全队列，再在Dart共同入口提交 | 独立OS探针只查本进程标记会话，pause/play/seek/next及12秒timeline实际通过，下一次镜像先等就绪；不复制队列/随机/重试 |
| 去重/交接 | 同一共享确认凭据；P1确认后立即提交硬切并关闭旧轨，非P8渐变 | 两端共用断言、共享测试、真实回滚测试；完整产品队列/历史仍不属于诊断原型 |

证据：[本地3项](windows-local-final.log)、[OS系统控制](windows-media-final.log)、[组件/权威恢复](windows-runtime-final.log)、[真实诊断按钮](windows-ui.log)。实际听感尚无人确认；API播放确认不等于扬声器必然出声。

未验证：拔出/失效输出设备、物理键盘媒体键、完整格式矩阵、连续缓冲反例及跨fade。系统probe只读取本诊断AppID/标题PID，不读取其他应用媒体属性。独立probe位于build/windows/x64/diagnostic_tools，不作为普通Release包内容；薄适配原型须P2前重新裁定保留范围。
