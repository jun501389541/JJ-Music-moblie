import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../application/playback/playback_coordinator.dart';
import '../../domain/playback/contracts.dart';
import '../../domain/playback/recovery_snapshot.dart';
import '../../data/prototype_recovery/file_snapshot_store.dart';
import '../../platform/local/native_local_backend.dart';

const ownedA = QueueEntry(
  entryId: 'owned-a',
  trackKey: 'owned-tone',
  fixtureId: 'tone-long',
);
const ownedB = QueueEntry(
  entryId: 'owned-b',
  trackKey: 'owned-tone',
  fixtureId: 'tone-long',
);

/// Process runtime retained independently of widget subscriptions and Activity.
class LocalRuntime extends ChangeNotifier {
  LocalRuntime._(
    this.backend,
    this.store,
    this._lock,
    SnapshotReadResult loaded,
  ) : coordinator = PlaybackCoordinator(
        backend,
        sessionId:
            loaded.snapshot?.playbackSessionId ??
            'local-$pid-${DateTime.now().millisecondsSinceEpoch}',
        initialEpoch: DateTime.now().microsecondsSinceEpoch,
      ) {
    if (loaded.snapshot != null) {
      coordinator.restoreSnapshot(loaded.snapshot!);
      savedRevision = loaded.snapshot!.revision;
      message = 'R3已读回修订$savedRevision，默认暂停，尚未分配播放资源';
    } else if (loaded.issues.isNotEmpty) {
      message = '快照不可用：安全空态/暂停退路；未自动播放';
    }
    _events = backend.events.listen((event) {
      final s = coordinator.snapshot;
      // P1 has a hard-switch policy, not crossfade. Commit and close outgoing
      // only after the coordinator accepted this incoming confirmation.
      if (event.kind == BackendEventKind.playing &&
          s.tracks.any(
            (t) =>
                t.trackHandleId == event.trackHandleId &&
                t.role == TrackRole.active,
          )) {
        coordinator.completeTransition(
          event.trackHandleId,
          transitionId: event.transitionId,
        );
      }
    });
    _commands = backend.systemCommands.listen((value) {
      command(
        value['command'] as String,
        position: value['position'] as int? ?? 0,
      );
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _mirrorFuture = _mirror();
    });
  }
  static Future<LocalRuntime>? _instance;
  static Future<LocalRuntime> instance() => _instance ??= create();
  static Future<LocalRuntime> create({String runId = 'owned-p1'}) async {
    final root = Directory('${Directory.systemTemp.path}/jj-owned-p1');
    await root.create(recursive: true);
    final store = FileSnapshotStore(
      root: Directory('${root.path}/recovery'),
      runId: runId,
      allowedFixtureIds: {'tone-long'},
    );
    await store.directory.create(recursive: true);
    final lock = await File('${store.directory.path}/writer.lock')
        .open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
    } catch (_) {
      await lock.close();
      rethrow;
    }
    try {
      final loaded = await store.load();
      final file = File('${root.path}/tone-long-$pid.wav');
      final bytes = await rootBundle.load(
        'fixtures/local_playback/tone-long.wav',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      final uri = Platform.isAndroid
          ? await NativeLocalBackend.channel.invokeMethod<String>('fixtureUri')
          : file.uri.toString();
      return LocalRuntime._(
        NativeLocalBackend({
          'tone-long': uri!,
        }, logFile: File('${root.path}/native-$pid.jsonl')),
        store,
        lock,
        loaded,
      );
    } catch (_) {
      await lock.close();
      rethrow;
    }
  }

  final NativeLocalBackend backend;
  final PlaybackCoordinator coordinator;
  final FileSnapshotStore store;
  final RandomAccessFile _lock;
  int savedRevision = 0;
  Future<void>? _mirrorFuture;
  bool _closed = false;
  Future<SnapshotSaveReceipt> save() async {
    final s = snapshot;
    final index = s.entries.indexWhere((e) => e.entryId == s.currentEntryId);
    if (index < 0) {
      throw StateError('no-confirmed-entry');
    }
    final receipt = await store.save(
      RecoverySnapshot(
        runId: store.runId,
        revision: savedRevision + 1,
        playbackSessionId: s.playbackSessionId,
        entries: s.entries,
        currentIndex: index,
        positionMs: s.positionMs,
        mode: s.mode,
        preview: s.preview,
        confirmations: s.confirmations,
      ),
    );
    savedRevision = receipt.revision;
    message = 'saved修订$savedRevision 已flush落盘；可停止进程后手动重开验证';
    notifyListeners();
    return receipt;
  }

  late final StreamSubscription<BackendEvent> _events;
  late final StreamSubscription<Map<String, dynamic>> _commands;
  Timer? _timer;
  int _request = 0, _ui = 0;
  bool _mirroring = false;
  String message = '就绪；仅播放自有12秒样本';
  PlaybackSnapshot get snapshot => coordinator.snapshot;
  Future<void> destroyBackend() async {
    final receipts = await backend.destroyNativeResources();
    final ack = coordinator.backendReleased(_cmd(), receipts);
    if (!ack.applied) {
      throw StateError('backend-loss-not-proven');
    }
    message = '底层播放器已销毁；backendEpoch递增，暂停等待恢复';
    notifyListeners();
  }

  void reconnect() {
    coordinator.attachUi('ui-${++_ui}');
    notifyListeners();
  }

  CommandContext _cmd() =>
      CommandContext('local-${++_request}', coordinator.claim);
  CommandAck? command(String name, {int position = 3000}) {
    final c = _cmd();
    final ack = switch (name) {
      'a' => coordinator.play(
        c,
        PlayIntent(entries: [ownedA, ownedB], entryId: ownedA.entryId),
      ),
      'b' || 'next' || 'previous' => coordinator.play(
        c,
        PlayIntent(
          entries: [ownedA, ownedB],
          entryId: snapshot.currentEntryId == ownedB.entryId
              ? ownedA.entryId
              : ownedB.entryId,
        ),
      ),
      'pause' => coordinator.pause(c),
      'play' => coordinator.resume(c),
      'stop' => coordinator.stop(c),
      'seek' => coordinator.seek(c, position),
      _ => null,
    };
    message =
        '$name: ${ack?.applied == true ? '已提交；等待后端确认' : ack?.failure?.code ?? '未执行'}';
    notifyListeners();
    return ack;
  }

  Future<void> _mirror() async {
    if (_mirroring || _closed) {
      return;
    }
    _mirroring = true;
    try {
      final s = snapshot;
      final running = (backend.lastHost['samples'] as List? ?? []).any(
        (v) =>
            v['nativePlaying'] == true &&
            s.tracks.any(
              (t) =>
                  t.trackHandleId == v['id'] &&
                  t.role == TrackRole.active &&
                  t.playbackConfirmationId != null,
            ),
      );
      await NativeLocalBackend.channel.invokeMethod<void>('mirror', {
        'title': s.currentEntryId == null
            ? 'JJ owned diagnostic pid-$pid'
            : 'JJ owned ${s.currentEntryId} pid-$pid',
        'status': s.desired == DesiredTransport.stopped
            ? 'stopped'
            : running && s.desired == DesiredTransport.playing
            ? 'playing'
            : 'paused',
        'position': s.positionMs,
        'duration': s.durationMs ?? 0,
      });
    } catch (e) {
      message = '系统镜像失败：${e.runtimeType}';
    } finally {
      _mirroring = false;
      if (!_closed) {
        notifyListeners();
      }
    }
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    await _mirrorFuture;
    await _events.cancel();
    await _commands.cancel();
    await coordinator.dispose();
    await backend.close();
    await _lock.close();
    super.dispose();
  }
}
