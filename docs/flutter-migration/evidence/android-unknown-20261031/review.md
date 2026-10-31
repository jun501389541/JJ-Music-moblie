# 限定独立审阅

2026-10-31，按executing-plans/requesting-code-review一次只读android_pcm_review。核OwnedPcmStream.kt、LocalHost相对本批before副本、新android_unknown_duration_test.dart；未改文件、执行测试或派生实现代理，未动上一批Windows未提交工作。

未发现Critical/Important。只接受自有/tone-pcm及position0/length unset；剥离WAV头后真实返回未知长度；100ms PCM帧按字节累计计算时间，短读积累、偶数尾帧；读取门控在loader，release先取消；历史有界，native seek先查能力。普通WAV媒体源保留。

Minor按明确证据边界处理：测试的<500ms只计同步c.stop接受意图，不包含等待消费者/nativePCM/gate关闭；文档不得据此说资源释放<500ms。实际资源另等观测归零，未给更紧时限承诺。final-android.log为14/14。

EOF前实际nativeDuration为TIME_UNSET，EOF后Media3推导为11910ms；本批只称读到末尾前未知，不声称永远未知或末尾时长精度通过。诊断关闭计数不等同独立OS句柄检查，真实运行不等于听感/正式UI验收。
