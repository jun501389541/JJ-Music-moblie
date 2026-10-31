import 'dart:async';
import 'dart:io';

import '../application/playback/playback_coordinator.dart';
import '../data/prototype_recovery/file_snapshot_store.dart';
import '../domain/playback/contracts.dart';
import '../domain/playback/recovery_snapshot.dart';

class DiagnosticReport {
  const DiagnosticReport(this.passed, this.details);
  final bool passed;
  final String details;
}

class DiagnosticChecks {
  static final _runId = 'diag-$pid-${DateTime.now().microsecondsSinceEpoch}';
  static const _entry = QueueEntry(
    entryId: 'diagnostic-a',
    trackKey: 'tone',
    fixtureId: 'tone-a',
  );
  static Future<DiagnosticReport> control() async {
    final backend = _PendingDiagnosticBackend();
    final coordinator = PlaybackCoordinator(backend);
    try {
      coordinator.play(
        CommandContext('prepare', coordinator.claim),
        PlayIntent(entries: [_entry], entryId: _entry.entryId),
      );
      final pending = !backend.preparation.isCompleted;
      final ack = coordinator.stop(CommandContext('stop', coordinator.claim));
      final dispatched = backend.actions.contains('stop');
      backend.preparation.complete(
        const PreparedTrack(
          'late-diagnostic',
          consumerId: 'diagnostic-reader',
          resourceRevision: 'tone-v1',
          canSeek: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final passed =
          pending &&
          ack.accepted &&
          ack.applied &&
          dispatched &&
          backend.actions.contains('released') &&
          !backend.actions.contains('play') &&
          coordinator.snapshot.confirmations.isEmpty;
      return DiagnosticReport(
        passed,
        passed
            ? '共享合同检查通过：准备仍pending时停止已派发，迟到资源已释放；没有产生播放确认。'
            : '共享合同检查失败，请保留日志',
      );
    } finally {
      await coordinator.dispose();
      await backend.close();
    }
  }

  static Future<DiagnosticReport> recovery() async {
    final root = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}jj-music-diagnostics${Platform.pathSeparator}prototype-recovery',
    );
    FileSnapshotStore store() => FileSnapshotStore(
      root: root,
      runId: _runId,
      allowedFixtureIds: {'tone-a'},
    );
    final s = store();
    final before = await s.load();
    final revision = (before.snapshot?.revision ?? 0) + 1;
    final input = RecoverySnapshot(
      runId: _runId,
      revision: revision,
      playbackSessionId: 'diagnostic-session',
      entries: [_entry],
      currentIndex: 0,
      positionMs: 1234,
    );
    final receipt = await s.save(input);
    final loaded = await store().load();
    final passed =
        receipt.revision == revision &&
        loaded.snapshot?.revision == revision &&
        loaded.snapshot?.positionMs == 1234 &&
        loaded.restoredTransport == DesiredTransport.paused;
    return DiagnosticReport(
      passed,
      passed
          ? '快照写读检查通过：已落盘修订 $revision，新适配器读回1234ms，恢复意图为暂停。\n隔离目录：${s.directory.path}\n这不是跨进程或强杀恢复验收。'
          : '快照检查失败，请保留诊断目录',
    );
  }
}

/// Diagnostic-only I/O boundary; deliberately produces no audio or platform events.
class _PendingDiagnosticBackend implements PlaybackBackend {
  final preparation = Completer<PreparedTrack>();
  final actions = <String>[];
  final _events = StreamController<BackendEvent>.broadcast();
  @override
  Stream<BackendEvent> get events => _events.stream;
  @override
  Future<PreparedTrack> prepare(PrepareRequest request) => preparation.future;
  @override
  Future<void> cancelPrepare(String requestId) async {
    actions.add('cancel');
  }

  @override
  Future<void> pause() async {
    actions.add('pause');
  }

  @override
  Future<void> stop() async {
    actions.add('stop');
  }

  @override
  Future<void> play(String handle) async {
    actions.add('play');
  }

  @override
  Future<void> seek(String handle, int positionMs) async {}
  @override
  Future<ReleaseReceipt> release(
    String handle,
    String consumer,
    int epoch,
  ) async {
    actions.add('released');
    return ReleaseReceipt(handle, consumer, epoch);
  }

  Future<void> close() => _events.close();
}
