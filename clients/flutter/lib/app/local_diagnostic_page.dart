import 'package:flutter/material.dart';

import 'runtime/local_runtime.dart';

class LocalDiagnosticPage extends StatefulWidget {
  const LocalDiagnosticPage({super.key});
  @override
  State<LocalDiagnosticPage> createState() => _LocalDiagnosticPageState();
}

class _LocalDiagnosticPageState extends State<LocalDiagnosticPage> {
  LocalRuntime? runtime;
  String? error;
  @override
  void initState() {
    super.initState();
    LocalRuntime.instance()
        .then((r) {
          if (!mounted) {
            return;
          }
          runtime = r;
          r.reconnect();
          r.addListener(refresh);
          setState(() {});
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() => error = e.runtimeType.toString());
          }
        });
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    runtime?.removeListener(refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = runtime, s = r?.snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('P1 自有样本播放诊断')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('仅12秒自有音调；不是正式产品UI。系统按钮与此界面使用同一共享入口。'),
          if (r == null)
            Text(error ?? '初始化中…')
          else ...[
            Text(
              '会话 ${s!.playbackSessionId}\nUI ${s.uiConnectionId}\n意图 ${s.desired.name}  当前 ${s.currentEntryId}\n位置 ${s.positionMs} / ${s.durationMs ?? 0} ms\n确认数 ${s.confirmations.length}  资源 ${r.backend.consumers}\n${r.message}',
              key: const Key('local-state'),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final item in [
                  ('a', '播放样本A'),
                  ('b', '切换样本B'),
                  ('pause', '暂停'),
                  ('play', '继续'),
                  ('seek', '定位3秒'),
                  ('stop', '停止'),
                ])
                  FilledButton(
                    onPressed: () => r.command(item.$1),
                    child: Text(item.$2),
                  ),
                OutlinedButton(
                  onPressed: r.reconnect,
                  child: const Text('UI重新连接'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await r.save();
                    } catch (e) {
                      r.message = '保存失败：${e.runtimeType}';
                      refresh();
                    }
                  },
                  child: const Text('保存恢复快照'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LocalDiagnosticPage(),
                      ),
                    );
                  },
                  child: const Text('重建组件'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
