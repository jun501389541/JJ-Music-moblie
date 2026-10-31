import 'package:flutter/material.dart';

import 'app/diagnostic_checks.dart';
import 'app/local_diagnostic_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JJ-Music 技术诊断',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const RepaintBoundary(
      key: Key('diagnostic-frame'),
      child: DiagnosticPage(),
    ),
  );
}

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});
  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  String result = '等待检查';
  bool busy = false;
  Future<void> runCheck(Future<DiagnosticReport> Function() check) async {
    setState(() {
      busy = true;
      result = '检查中…';
    });
    try {
      final report = await check();
      if (mounted) {
        setState(() => result = report.details);
      }
    } catch (_) {
      if (mounted) {
        setState(() => result = '检查失败：文件或合同操作未完成，请保留证据。');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('JJ-Music 技术诊断')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('A01 / A02 检查不播放音频；本地样本入口仅用于P1技术验证，不是正式播放器。'),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LocalDiagnosticPage(),
            ),
          ),
          child: const Text('打开自有样本播放诊断'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() => result = '入口检查通过：界面可响应'),
          child: const Text('运行入口检查'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : () => runCheck(DiagnosticChecks.control),
          child: const Text('运行共享合同自检'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy ? null : () => runCheck(DiagnosticChecks.recovery),
          child: const Text('保存并读回测试快照'),
        ),
        const SizedBox(height: 16),
        SelectableText(result, key: const Key('diagnostic-result')),
      ],
    ),
  );
}
