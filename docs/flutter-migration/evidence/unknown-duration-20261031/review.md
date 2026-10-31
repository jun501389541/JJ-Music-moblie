# 限定独立审阅

2026-10-31，按executing-plans/requesting-code-review调用一次只读unknown_review。基线86053e5，范围三个Windows源码文件及新增windows_unknown_duration_test.dart，未改文件/运行测试/派生实现代理。

未发现Critical/Important。显式unknown profile才省略MSS Duration，poll直接读取实际CanSeek，native seek在Position写入前拒绝；不改普通已知时长来源或共享冻结。final.log的2项真实通过与0/12000、canSeek=false、seek-unsupported原始证据相符。未扩大为Android/共享能力协商或命令ack验收。

Minor保留：测试目前匹配任意PlatformException，而非同时匹配winrt/seek-unsupported；当前原始日志另证实错误确为seek-unsupported，不是缺入口/无效id。后续加强拒绝测试时可缩紧matcher；本批没有产品重要缺陷或降低验收要求。

追加审阅：同一reviewer只读核smtc_probe.cpp，未见Critical/Important。仅属性ERROR_NOT_READY跳过，最多20扫描/100ms间隔，command不重试，其他错误保留，未输出他app元数据。API自身无超时、不能称严格2秒。stage残留Minor由执行者补enumerate/source-id/owned-timeline，编译及真实候选复验通过；该小诊断调整未再派审阅。windows-media-candidate.log四次都skippedNotReady1，命中本次PID会话并acceptedtrue，最终EXIT0。
