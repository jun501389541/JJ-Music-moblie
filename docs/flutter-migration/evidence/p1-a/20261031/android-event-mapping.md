# Android事件归一化：P1薄Media3 1.11.0

2026-10-31；设备由用户选定：35a63609，Xiaomi2211133C/fuxi，Android13/API33，arm64-v8a。不是模拟器，也未读取个人曲库。

来源：[官方固定依赖/版本](https://developer.android.com/jetpack/androidx/releases/media3)、[Player事件语义](https://developer.android.com/media/media3/exoplayer/listening-to-player-events)。实际代码LocalHost.kt按100ms轮询直接读取ExoPlayer；日志是有序原生采样，不冒充每一次回调完整记录。共享层再核handle/request/epoch/generation/sequence及desired，才接受项目确认。

| 维度 | 本端真实API与项目归一化 | 实际证据/限制 |
| --- | --- | --- |
| 准备/ready | Player.STATE_READY(3)仅证明可播放；complete prepare后不直接签确认 | android-local-final.log中ready=true、nativePlaying=false、position0样本 |
| 项目playing | 当前handle、原生STATE_READY、playWhenReady、isPlaying、suppression=0，且两次原生currentPosition采样推进；seek/暂停重置观察窗；不是Dart插值或按钮布尔 | 同日志首次position0/77/308序列，期间停滞采样不独立确认；误触发反例另有mapping-red/green与38项共享测试 |
| 缓冲/暂停恢复 | STATE_BUFFERING(2)映射buffering，不确认；暂停意图立即短提交，native.pause独立；resume同handle不重签 | 实际暂停/定位/继续且确认数不变通过；自有小WAV未稳定诱发长缓冲暂停/恢复，真实反例仍未验 |
| progress/seek | ExoPlayer.currentPosition/duration直接采样，非位置插值；未知duration当前保守0，不宣称未知时长定位支持 | 已验证12秒及0.5秒PCM WAV、定位3秒；未知时长/不可seek提供方未验 |
| 自然结束/失败/取消 | STATE_ENDED且本handle仍有播放资格才发ended；主动stop先撤资格；playerError及play调用异常按该handle错误归一化 | short.wav自然结束/坏文件/私有provider拒绝、快速停止通过；迟到/重复事件围栏为共享测试证据，不声称真实OS已诱发每种迟到 |
| 发布与资源 | 每轨独立ExoPlayer，最多2；release()返回成功后才出匹配receipt；取消中的分配也释放；同时关闭请求共用同一物理Future | 真实消费者归零；duplicate release红绿测试；读取权限只限本应用cache/code_cache或私有fixture provider，无外部存储许可 |
| 业务消费/交接 | 首次确认只签一次；P1硬切：新轨确认后共享层completeTransition，再释放outgoing；原生无队列/随机/重试 | 真实切歌前注入play失败后旧轨原生running且继续推进，确认不增；review修复和两端日志 |

日志：[最终3项原生测试](android-local-final.log)、[生命周期](android-lifecycle-final.log)、[独立资源恢复](android-runtime.log)。Android系统控制由平台MediaSession回调进入同一Dart入口；不是把本组合称作Media3 MediaSessionService。没有网络权限/源请求、真实曲库、账号或密钥。

可报告能力：本批自有PCM WAV、私有content/file URI、已知时长seek、单轨硬切、2个逐轨资源上限。未证明跨fade/无缝、所有格式/所有content提供方、长期休眠、完整焦点/蓝牙/路由、持续缓冲或服务/engine单独被回收。不得把这些改成passed/N/A。
