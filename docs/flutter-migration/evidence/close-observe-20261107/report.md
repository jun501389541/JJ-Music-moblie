# 关闭接管Future的即时错误观察（2026-11-07）

AUTH-CLOSE-OBSERVE-20261107；用户继续开发。基线6bb75bc7064e4d61e3a63daebb67e8caaab118db，codex/seek-boundaries，开工干净。Codex串行A07/A02维护；本批未自动提交推送。

## 复现与修复

此前close捕获在途save/destroy后先await镜像，直到镜像结束才观察操作Future。受控测试让mirror挂起、release挂起，close先接管销毁，再放行失败release，调用方延迟一个事件轮注册异常监听。red-zone-corrected.log退出1，Zone收集到未处理的owned-release-fault，确认观察窗口缺口。

初版red.log也记录同一产品断言失败，但其tearDown跨error zone等待失败close Future导致挂起，已中止且保留。修正测试让失败Future都在同error zone内完成观察，只让成功的done凭据回到测试zone；外部tearDown不再次跨zone等待失败Future。该修正未改变产品失败断言；corrected red再次失败后才改生产代码。

runtime.close现在接管时立即启动CloseActions.run观察saving/destroying错误，run收集原错误而不向外产生新的未处理错误；close仍等待mirror、这些操作，再依序释放订阅/权威/writer/notifier，最后按原有规则重抛。未提前关闭、未吞掉原操作失败；原调用者和close收到同一错误对象。只有在close调用时已接管的操作受此保证，不增加超时/取消或跨error-zone支持。

green.log退出0，新增1项通过；quality/及quality-run.log退出0，97共同测试、64文件格式0变化/analyze、新v2.9的32文件+05哈希/锁通过。原v2.8清单不改，协议/快照仍1。新测试文件摘要另存，不重写历史证据。

## 审阅与证据边界

独立close_observe_review无阻断，只读源码及红绿/Quality日志，未执行测试/设备/构建。新增注入仅覆盖destroy，save失败观察依同实现静态核查，不记为保存故障实测；mirror放行前close pending及原stack保留主要由代码路径佐证，测试直接断言错误对象相同和未处理错误集合为空。

本批没有原生、依赖、设备/安装或普通Release变化；前批ordinary-final.json的双端普通产物仅核对摘要保持，不冒称包含本次新源修复。后续打包应消费v2.9，当前手机仍前批已验证普通入口。暂停外部流订阅、永不完成Future、全部跨组件竞争/跨engine、真实系统故障或听感仍未齐，A07/G-L保持review。不自动进入P2/正式UI，不改旧库/全局，不提交推送。

下一批可先复核本次提交范围及需否做新普通构建/平台回归；不要把宿主观察窗口修复当成物理故障通过。实际差异/摘要及GraphFlow索引另存本目录。
