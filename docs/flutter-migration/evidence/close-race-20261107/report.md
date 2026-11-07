# close与在途save/destroy汇合修复（2026-11-07）

最终接续：用户解锁后Android正常关闭/恢复回归1项通过，普通APK已恢复安装COLD启动成功。下方待解锁文字为历史，当前结果以末尾最终接续为准。

用户继续开发，实际基线e57079d、codex/seek-boundaries，开工Git干净。owner Codex串行A07/A02/ConfigIntegrator。既有提交已包含上一批修复，本批不自动提交推送。

三项红例均失败（red.log）：实际隔离save尚在写入，close先dispose通知器/释放writer；destroy release在途时close先dispose协调器导致回执拒绝；失败交错遗留消费者。已修runtime先发布操作Future，再执行私有async逻辑，close捕调用时仍在途的save/destroy并在权威、writer/notifier收尾前汇合；closed后success/catch不晚通知，busy拒绝不覆盖在途Future。错误交由既有CloseActions保留原对象/stack并继续独立清理，不把物理不可信资源伪称released。

green.log原3项通过。独立[审阅](review.md)无阻断，后补save/destroy通知listener内重入close两项，并在原gate用例验证busy拒绝不覆盖pending；review-tests五项通过。初轮Quality仅4处大括号lint失败（quality/），修正未放宽规则；quality-final原94共同通过，最终quality-reviewed增至96共同，准确格式/分析/31冻结+05/锁结果见其日志。新v2.8保留旧v2.7，协议/快照仍1，初版与补测前清单另存。

宿主使用真实Dart runtime/backend/coordinator、真实自有隔离文件，native MethodChannel受控；不是系统release失败或断电证明。Windows真实coordinator_restart_test退出0/1项（windows.log），PID33040、新epoch1794016646531009、修订1/位置2345、同目录新对象默认暂停/旧claim拒绝、显式播放停止及原生空。这是正常路径回归，不是宿主竞争的Windows物理故障复现。

Android设备在线但Dozing，已请求解锁，本批尚未执行Android回归；旧普通手机包未被本批测试替换。普通产物备份在graphflow-out/close-race-20261107/ordinary-before。新普通main构建及后续手机结果另记，不拿历史真机结果代替本批。

仍不保证永不完成Future、暂停外部流订阅或所有跨组件竞争；mirror先等待期间调用者仍须正常观察原操作错误Future。A07/G-L保持review，不自动P2/正式UI，不改原生/依赖/全局或旧库。无提交推送。

## 可执行部分收尾
最终quality-reviewed96共同/格式63文件0变化/analyze/31冻结+05/锁通过。双端普通main Release构建成功，Windows入口有限启动后关闭，PID见windows-ordinary-start.log，双端摘要ordinary-final.json。手机仍待解锁，本批未安装/启动或运行该端测试；新APK单独备份ordinary-final，哈希android-ordinary-hash.json。保持partial/review而非双端通过，不提交推送。

## Android最终接续
预检35a63609/2211133C/Awake且非锁屏，31冻结及普通APK摘要一致。android-final.log exit0，coordinator_restart真实1项通过；PID29736，epoch1794017524314437→1794017525694897，修订1/位置2345、同目录快照默认暂停、旧claim拒绝/显式继续停止，releasedSamples/finalSamples均空。源码未变，不重复已通过的Windows及96共同检查。正常平台回归不替代受控竞态或真实故障注入。
测试进程退出后恢复本批普通APK，SHA256 c8a9a4e7d172691ef510a2850358ca313b2c674774023fb4cf572ef8f9ad21d4，install Success/COLD启动Status ok/PID30184/Awake；见android-ordinary-*日志。未重建普通Release或额外听感验收。双端限定回归现已完成，A07/G-L仍review；未提交推送，全部本批修改保留。
