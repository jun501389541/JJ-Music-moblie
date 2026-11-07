# A07故障探针独立只读审阅

2026-11-01，/root/snapshot_fault_review按executing-plans要求读新Dart/PS与必要LocalRuntime/FileSnapshotStore/native语义和最终proof；未编辑、未执行测试或接触设备。

发现P2：只读700ms末端lastHost可能被后续空结果覆盖，也可能遗漏NativeLocalBackend.raw中的bridgeError。修复：25ms检查共享资源，识别新的lastHost，至少3次原生poll；检查所有采样点并扫描整个短窗raw，拒绝bridgeError或任意带id的播放器样本。最终Windows六组各6次poll，Android六组6次（partial-temp7次），均无桥接/资源异常。审阅者复核关闭P2，无新增阻断项。

重要边界：原生poll约100ms一次，25ms循环不提高原生采样频率。不证明采样间隙绝无瞬态资源，也不是实时硬件跟踪。

Android首次六项proof检查通过但控制器退出1：成功Stop-Probe后的pidof无进程本来返回1，被调用方当作脚本结果。最后加exit0，且它在完整try/finally之后；原有所有throw拒绝/超时/清理失败均不能到达该语句，不会吞失败。新runId a2完整重跑，检查及退出码均0。最终Android身份、runId、不同PID、输入逐字一致、正确修订、资源空态由reviewer只读复核通过。

遗留.tmp受控夹具的边界注释准确，不宣称真实save Future被中断或断电通过。共享冻结原型无需修改。
