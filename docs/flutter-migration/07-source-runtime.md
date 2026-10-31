# JS音源兼容与隔离

分类F/D/P/H分别标明。任务B03/B04/B05a/B05b；G-S0为合成，G-S1为授权范围内真实兼容；不默认全部音源可用。

## 当前事实与支持清单

F：JJ生产LX API2.0.0/env desktop；jj-source API1.0.0库存未接入主链。上游两端均LX2.0.0，但mobile/desktop分支、请求和宿主能力不同。[Mobile固定preload](https://github.com/lyswhut/lx-music-mobile/blob/fb8480728d875fa5e0da25eebd3a26bb71723aae/android/app/src/main/assets/script/user-api-preload.js)、[Desktop固定preload](https://github.com/lyswhut/lx-music-desktop/blob/ad95d5091c9ed689fa72b5e5c849df65f5a679ce/src/main/modules/userApi/renderer/preload.js)。

| 项 | 当前/迁移合同 |
| --- | --- |
| 事件 | request/inited/updateAlert；初始化和更新提示次数约束 |
| 请求 | `{source, action, info}`；musicUrl的info含type与扁平musicInfo |
| 身份 | 原平台ID、songmid/hash/copyrightId/albumId/strMediaMid等必要字段，不能只传简化Song |
| 音质 | 仅声明且允许档位；平台/音源私有字段不盲传另一源 |
| 回调 | error/response/body、状态/headers/编码/二进制必须有向量 |
| 取消 | 返回取消函数+宿主cancel；Future超时不等于终止同步JS |
| Buffer/编码 | 必要Buffer.from/转换与iconv兼容子集 |
| 加密/压缩 | MD5/random/AES/RSA/inflate/deflate等固定向量，不凭同名验收 |
| fetch/timer/browser | 受控网络/定时器、window/self等最小子集；禁止绕过 |
| CommonJS/Node | 当前真实loader+黑名单不是完整沙箱；新默认不提供任意模块/文件/进程 |

当前Object.assign(cancel,promise)不能自然继承Promise.then，列探针而非已复现bug。Android不能仅换env就宣称兼容；按真实平台声明，必要兼容profile需独立依据，不默认伪装。

## 引擎候选与过渡

P：优先QuickJS薄独立宿主；flutter_js等绑定可作探针但版本、限制接口、维护和ABI需审计；进程内FFI不隔离崩溃。WebView不作默认后台宿主，重型V8无证据不引入。

QuickJS C API有内存和中断机制，绑定必须实际暴露。[官方](https://bellard.org/quickjs/quickjs.html)。Windows可暂用自带、版本/摘要可验的独立Node sidecar，明确更新与许可；不能依赖用户Node/Electron或直接运行现有ELECTRON_RUN_AS_NODE宿主。

共享：兼容shim规范、参数映射、超时取消、版本/更新/回退策略、测试向量。平台：ABI、独立进程/服务、权限、崩溃和终止。Android普通`:process`同UID不等于隔离，需验证isolatedProcess/受控IPC等；Windows SAFER/Job是收敛与故障隔离，非完整沙箱。

## 生命周期与资源

导入单脚本（明文JS或gz_，不恢复批量JSON导入）→校验→停用安装→初始化→能力→可用→更新预览/验证→切换或回退。稳定ID、内容摘要、实例代次分别记录。脚本初始化不证明解析，解析不证明完整播放。

初始沿旧初始化15秒、单解析20秒、播放共用60秒预算；响应8MiB级、日志有界轮换；JS堆/进程/并发/timer分别设限并实测，不能把Node512MB old-space当全部进程上限。忙循环中断失败则终止宿主。连续失败隔离，不无限自动重启。

音源停用/更新/崩溃按合同使对应请求与授权失效；共享来源有播放/下载持有，停止播放不统一stopAll。raw媒体地址不进入UI，网络必须收敛；不支持依赖显示具体原因。Windows过渡模式不能被标成和Android同等安全。

## 真实源早期实验

G-S0先完成自有脚本/网络与隔离探针。B05a在单独授权下做少量初始化/解析；B05b另需G-B，做指定曲目播放/seek/取消/URL恢复。默认建议1—2脚本、有限曲目和平台，精确范围先登记，不能从设计批准推导权限。

记录脚本来源/摘要/许可、env、支持子集、平台/版本、行为及失败，不保存私人脚本文本、令牌或账号。不扩展访问范围、不自动降低安全限制。某端不兼容如实记录；G-S1范围至少包含要公开声明支持的平台和profile，不能只测Windows就放行Android。

授权未取得：标待验，可继续本地/无源资料/自有夹具；不能宣称真实兼容。原型通过后生产源管理、下载/后台、供应链更新仍需对应验收。
