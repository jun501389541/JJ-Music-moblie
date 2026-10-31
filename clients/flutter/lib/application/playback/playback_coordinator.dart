import 'dart:async';
import 'dart:convert';

import '../../domain/playback/contracts.dart';
import '../../domain/playback/recovery_snapshot.dart';

class _Track {
  _Track(this.request, this.resource);
  final PrepareRequest request;
  final PreparedTrack resource;
  TrackRole role = TrackRole.prepared;
  int sequence = -1;
  bool revoked = false;
  String? confirmation;
  String? transitionId;
  Timer? releaseTimer;
  TrackSnapshot get snapshot => TrackSnapshot(
    trackHandleId: resource.trackHandleId,
    entry: request.entry,
    consumerId: resource.consumerId,
    resourceRevision: resource.resourceRevision,
    role: role,
    backendEpoch: request.backendEpoch,
    generation: request.generation,
    revoked: revoked,
    playbackConfirmationId: confirmation,
  );
}

/// In-isolate authority only. Cross-engine host survival is explicitly A04/A07.
/// Every command commits synchronously; no backend Future enters a command chain.
class PlaybackCoordinator {
  PlaybackCoordinator(
    this.backend, {
    this.sessionId = 'fixture-session',
    this.releaseTimeout = const Duration(seconds: 3),
    int initialEpoch = 1,
  }) {
    _epoch = initialEpoch;
    _subscription = backend.events.listen(
      _onEvent,
      onError: (Object error) => _fail('backend-stream', 'events'),
    );
  }
  final PlaybackBackend backend;
  final String sessionId;
  final Duration releaseTimeout;
  late final StreamSubscription<BackendEvent> _subscription;
  String _owner = 'owner-1';
  int _epoch = 1, _generation = 0, _revision = 0, _cursor = 0;
  int _backendEpoch = 1;
  int _confirmationCounter = 0;
  String? _ui, _active, _currentRequest, _requested;
  String? _restoredEntry;
  int _position = 0;
  int? _duration;
  bool _preview = false, _disposed = false;
  PlaybackMode _mode = PlaybackMode.sequence;
  DesiredTransport _desired = DesiredTransport.stopped;
  List<QueueEntry> _entries = [];
  final _tracks = <String, _Track>{};
  final _pending = <String, PrepareRequest>{};
  final _preparing = <String>{};
  PrepareRequest? _waitingPrepare;
  Timer? _capacityTimer;
  final _acks = <String, (String, CommandAck)>{};
  final _confirmations = <String>[];
  final _failures = <PlaybackFailure>[];
  List<PlaybackFailure> get failures => List.unmodifiable(_failures);
  ControllerClaim get claim => ControllerClaim(_owner, _epoch, sessionId);
  CommandAck? acknowledgement(String requestId) => _acks[requestId]?.$2;
  PlaybackSnapshot get snapshot => PlaybackSnapshot(
    playbackSessionId: sessionId,
    coordinatorEpoch: _epoch,
    backendEpoch: _backendEpoch,
    brokerEpoch: 1,
    playbackGeneration: _generation,
    queueRevision: _revision,
    eventCursor: _cursor,
    desired: _desired,
    entries: _entries,
    tracks: _tracks.values.map((t) => t.snapshot).toList(),
    confirmations: _confirmations,
    currentEntryId: _active == null
        ? _restoredEntry
        : _tracks[_active]?.request.entry.entryId,
    requestedEntryId: _requested,
    uiConnectionId: _ui,
    positionMs: _position,
    durationMs: _duration,
    preview: _preview,
    mode: _mode,
  );

  PlaybackSnapshot attachUi(String connectionId) {
    _ui = connectionId;
    return snapshot;
  }

  /// Fresh authority only. R3 never restores native handles or auto-plays.
  void restoreSnapshot(RecoverySnapshot saved) {
    if (!_disposed &&
        _generation == 0 &&
        _entries.isEmpty &&
        saved.entries.isEmpty &&
        saved.currentIndex == -1 &&
        saved.playbackSessionId == sessionId) {
      _desired = DesiredTransport.paused;
      _cursor++;
      return;
    }
    if (_disposed ||
        _generation != 0 ||
        _entries.isNotEmpty ||
        saved.playbackSessionId != sessionId ||
        !_validEntries(saved.entries) ||
        saved.currentIndex < 0 ||
        saved.currentIndex >= saved.entries.length ||
        saved.positionMs < 0) {
      throw StateError('invalid-restore');
    }
    _entries = List.of(saved.entries);
    _restoredEntry = saved.entries[saved.currentIndex].entryId;
    _requested = _restoredEntry;
    _position = saved.positionMs;
    _mode = saved.mode;
    _preview = saved.preview;
    _confirmations.addAll(saved.confirmations);
    for (final id in saved.confirmations) {
      final value = int.tryParse(id.split(':').last) ?? 0;
      if (value > _confirmationCounter) {
        _confirmationCounter = value;
      }
    }
    _desired = DesiredTransport.paused;
    _revision++;
    _cursor++;
  }

  /// Trusted host destruction receipts, never infer physical death from timeout.
  CommandAck backendReleased(CommandContext c, List<ReleaseReceipt> receipts) {
    final signature = jsonEncode([
      'backend-released',
      receipts
          .map((r) => [r.trackHandleId, r.consumerId, r.backendEpoch])
          .toList(),
    ]);
    final old = _existing(c, signature);
    if (old != null) {
      return old;
    }
    final live = _tracks.values
        .where((t) => t.role != TrackRole.released)
        .toList();
    if (live.any(
      (t) => !receipts.any(
        (r) =>
            r.trackHandleId == t.resource.trackHandleId &&
            r.consumerId == t.resource.consumerId &&
            r.backendEpoch == t.request.backendEpoch,
      ),
    )) {
      return _reject(c, 'missing-destruction-receipt');
    }
    _restoredEntry = _active == null
        ? _requested
        : _tracks[_active]?.request.entry.entryId;
    _invalidatePrepare();
    _generation++;
    _currentRequest = null;
    for (final t in live) {
      t.releaseTimer?.cancel();
      t.role = TrackRole.released;
    }
    _tracks.clear();
    _active = null;
    _backendEpoch++;
    _desired = DesiredTransport.paused;
    return _applied(c, signature);
  }

  ControllerClaim? acquireController({
    required String expectedOwner,
    required String newOwner,
  }) {
    if (_disposed || expectedOwner != _owner || newOwner.isEmpty) {
      return null;
    }
    _invalidatePrepare();
    _generation++;
    _currentRequest = null;
    _owner = newOwner;
    _epoch++;
    _cursor++;
    return claim;
  }

  CommandAck? _existing(CommandContext c, String signature) {
    if (_disposed ||
        c.protocolVersion != playbackProtocolVersion ||
        c.requestId.isEmpty ||
        c.claim.ownerId != _owner ||
        c.claim.coordinatorEpoch != _epoch ||
        c.claim.playbackSessionId != sessionId) {
      return _reject(c, 'stale-controller');
    }
    final old = _acks[c.requestId];
    if (old != null) {
      return old.$1 == signature ? old.$2 : _reject(c, 'request-id-conflict');
    }
    if (_acks.length >= 256) {
      return _reject(c, 'diagnostic-command-limit');
    }
    return null;
  }

  CommandAck _reject(CommandContext c, String code) =>
      CommandAck(c.requestId, failure: PlaybackFailure(code, 'accept'));
  CommandAck _applied(CommandContext c, String signature) {
    final ack = CommandAck(c.requestId, accepted: true, applied: true);
    _acks[c.requestId] = (signature, ack);
    _cursor++;
    return ack;
  }

  void _fail(String code, String stage) {
    if (_disposed) {
      return;
    }
    if (_failures.length == 32) {
      _failures.removeAt(0);
    }
    _failures.add(PlaybackFailure(code, stage));
    _cursor++;
  }

  void _dispatch(Future<void> Function() operation, String stage) {
    try {
      unawaited(
        operation().catchError((Object error) {
          _fail('backend-failure', stage);
        }),
      );
    } catch (_) {
      _fail('backend-failure', stage);
    }
  }

  bool _validEntries(List<QueueEntry> entries) =>
      entries.isNotEmpty &&
      entries.length <= 16 &&
      entries.map((e) => e.entryId).toSet().length == entries.length &&
      entries.every(
        (e) =>
            e.entryId.isNotEmpty &&
            e.trackKey.isNotEmpty &&
            e.fixtureId.isNotEmpty,
      );
  Object _queueSignature(List<QueueEntry> entries) =>
      entries.map((e) => [e.entryId, e.trackKey, e.fixtureId]).toList();
  String _intentSignature(PlayIntent intent) => jsonEncode([
    'play',
    intent.entryId,
    intent.mode.name,
    intent.preview,
    intent.startPositionMs,
    _queueSignature(intent.entries),
  ]);

  CommandAck play(CommandContext c, PlayIntent intent) {
    final signature = _intentSignature(intent);
    final old = _existing(c, signature);
    if (old != null) {
      return old;
    }
    if (intent.startPositionMs < 0 ||
        !_validEntries(intent.entries) ||
        !intent.entries.any((e) => e.entryId == intent.entryId)) {
      return _reject(c, 'invalid-intent');
    }
    final live = _tracks.values
        .where((t) => t.role != TrackRole.released)
        .length;
    final cancellable = _tracks.values.any(
      (t) => t.role == TrackRole.prepared || t.role == TrackRole.incoming,
    );
    if ((live >= 2 && !cancellable) || _pending.length >= 8) {
      return _reject(c, 'resource-capacity');
    }
    _invalidatePrepare();
    _generation++;
    _entries = intent.entries;
    _revision++;
    _requested = intent.entryId;
    _restoredEntry = null;
    _preview = intent.preview;
    _mode = intent.mode;
    _desired = DesiredTransport.playing;
    _currentRequest = c.requestId;
    final request = PrepareRequest(
      requestId: c.requestId,
      entry: intent.entries.firstWhere((e) => e.entryId == intent.entryId),
      generation: _generation,
      backendEpoch: _backendEpoch,
      transitionId: _active == null ? null : 'transition-$_generation',
      startPositionMs: intent.startPositionMs,
    );
    _pending[c.requestId] = request;
    final ack = _applied(c, signature);
    _schedulePrepare(request);
    return ack;
  }

  int get _reservedSlots =>
      _preparing.length +
      _tracks.values.where((t) => t.role != TrackRole.released).length;

  void _schedulePrepare(PrepareRequest request) {
    if (_reservedSlots >= 2) {
      _waitingPrepare = request;
      _capacityTimer?.cancel();
      _capacityTimer = Timer(releaseTimeout, () {
        if (_waitingPrepare?.requestId != request.requestId) {
          return;
        }
        _waitingPrepare = null;
        _pending.remove(request.requestId);
        _currentRequest = null;
        _requested = null;
        _desired = _active == null ? DesiredTransport.paused : _desired;
        _fail('resource-capacity-timeout', 'prepare');
      });
      return;
    }
    _preparing.add(request.requestId);
    try {
      unawaited(
        backend
            .prepare(request)
            .then(
              (resource) => _prepared(request, resource),
              onError: (Object error) {
                _pending.remove(request.requestId);
                _preparing.remove(request.requestId);
                if (!_disposed &&
                    request.requestId == _currentRequest &&
                    request.generation == _generation) {
                  _fail('prepare-failure', 'prepare');
                  _desired = _active == null
                      ? DesiredTransport.stopped
                      : DesiredTransport.playing;
                }
                _drainWaiting();
              },
            ),
      );
    } catch (_) {
      _pending.remove(request.requestId);
      _preparing.remove(request.requestId);
      _fail('prepare-failure', 'prepare');
      _drainWaiting();
    }
  }

  void _drainWaiting() {
    final next = _waitingPrepare;
    if (_disposed || next == null || _reservedSlots >= 2) {
      return;
    }
    _waitingPrepare = null;
    _capacityTimer?.cancel();
    if (next.generation == _generation && next.requestId == _currentRequest) {
      _schedulePrepare(next);
    } else {
      _pending.remove(next.requestId);
    }
  }

  void _invalidatePrepare() {
    final id = _currentRequest;
    if (_waitingPrepare != null) {
      _pending.remove(_waitingPrepare!.requestId);
      _waitingPrepare = null;
      _capacityTimer?.cancel();
    }
    if (id != null && _preparing.contains(id)) {
      _dispatch(() => backend.cancelPrepare(id), 'cancel');
    }
    for (final t
        in _tracks.values
            .where(
              (t) =>
                  (t.role == TrackRole.prepared ||
                  t.role == TrackRole.incoming),
            )
            .toList()) {
      _release(t);
    }
  }

  void _prepared(PrepareRequest request, PreparedTrack resource) {
    _pending.remove(request.requestId);
    _preparing.remove(request.requestId);
    if (resource.trackHandleId.isEmpty ||
        resource.consumerId.isEmpty ||
        resource.resourceRevision.isEmpty ||
        _tracks.containsKey(resource.trackHandleId)) {
      _fail('invalid-handle', 'prepare');
      _drainWaiting();
      return;
    }
    final track = _Track(request, resource);
    _tracks.removeWhere((key, value) => value.role == TrackRole.released);
    _tracks[resource.trackHandleId] = track;
    if (_disposed ||
        request.generation != _generation ||
        request.requestId != _currentRequest ||
        request.backendEpoch != _backendEpoch) {
      // Even obsolete success owns an allocated consumer and must be cleaned up.
      _release(track);
      _drainWaiting();
      return;
    }
    if (_desired == DesiredTransport.playing) {
      track.role = TrackRole.incoming;
      _dispatch(() => backend.play(resource.trackHandleId), 'play');
    }
    _cursor++;
    _drainWaiting();
  }

  CommandAck pause(CommandContext c) {
    final old = _existing(c, 'pause');
    if (old != null) {
      return old;
    }
    _desired = DesiredTransport.paused;
    _dispatch(backend.pause, 'pause');
    return _applied(c, 'pause');
  }

  CommandAck resume(CommandContext c) {
    final old = _existing(c, 'resume');
    if (old != null) {
      return old;
    }
    if (_restoredEntry != null && _active == null) {
      final ack = play(
        c,
        PlayIntent(
          entries: _entries,
          entryId: _restoredEntry!,
          preview: _preview,
          mode: _mode,
          startPositionMs: _position,
        ),
      );
      if (ack.applied) {
        _acks[c.requestId] = ('resume', ack);
      }
      return ack;
    }
    final track = _active == null
        ? _tracks.values
              .where(
                (t) =>
                    (t.role == TrackRole.prepared ||
                        t.role == TrackRole.incoming) &&
                    t.request.requestId == _currentRequest,
              )
              .firstOrNull
        : _tracks[_active];
    if (track == null && !_pending.containsKey(_currentRequest)) {
      return _reject(c, 'no-prepared-resource');
    }
    _desired = DesiredTransport.playing;
    if (track != null) {
      if (track.role == TrackRole.prepared) {
        track.role = TrackRole.incoming;
      }
      _dispatch(() => backend.play(track.resource.trackHandleId), 'resume');
    }
    return _applied(c, 'resume');
  }

  CommandAck stop(CommandContext c) {
    final old = _existing(c, 'stop');
    if (old != null) {
      return old;
    }
    _invalidatePrepare();
    _generation++;
    _currentRequest = null;
    _requested = null;
    _restoredEntry = null;
    _desired = DesiredTransport.stopped;
    _active = null;
    _position = 0;
    _dispatch(backend.stop, 'stop');
    for (final t in _tracks.values.toList()) {
      _release(t);
    }
    return _applied(c, 'stop');
  }

  CommandAck cancel(CommandContext c, String targetRequestId) {
    final signature = 'cancel:$targetRequestId';
    final old = _existing(c, signature);
    if (old != null) {
      return old;
    }
    final prepared = _tracks.values
        .where(
          (t) =>
              t.request.requestId == targetRequestId &&
              (t.role == TrackRole.prepared || t.role == TrackRole.incoming),
        )
        .toList();
    if (_pending.containsKey(targetRequestId) || prepared.isNotEmpty) {
      if (_preparing.contains(targetRequestId)) {
        _dispatch(() => backend.cancelPrepare(targetRequestId), 'cancel');
      }
      if (_waitingPrepare?.requestId == targetRequestId) {
        _waitingPrepare = null;
        _capacityTimer?.cancel();
        _pending.remove(targetRequestId);
      }
      for (final t in prepared) {
        _release(t);
      }
      if (_currentRequest == targetRequestId) {
        _generation++;
        _currentRequest = null;
        _requested = null;
        _desired = _active == null ? DesiredTransport.stopped : _desired;
        _resumeValidActive();
      }
    }
    return _applied(c, signature);
  }

  CommandAck seek(CommandContext c, int positionMs) {
    final signature = 'seek:$positionMs';
    final old = _existing(c, signature);
    if (old != null) {
      return old;
    }
    if (positionMs < 0 || _active == null) {
      return _reject(c, 'invalid-seek');
    }
    final capability = _tracks[_active]?.resource.canSeek;
    if (capability != true) {
      return _reject(
        c,
        capability == false ? 'seek-unsupported' : 'seek-capability-unknown',
      );
    }
    _invalidatePrepare();
    _generation++;
    _currentRequest = null;
    for (final t
        in _tracks.values
            .where(
              (t) =>
                  (t.role == TrackRole.prepared ||
                      t.role == TrackRole.incoming) ||
                  t.role == TrackRole.outgoing,
            )
            .toList()) {
      _release(t);
    }
    _dispatch(() => backend.seek(_active!, positionMs), 'seek');
    _position = positionMs;
    return _applied(c, signature);
  }

  void _resumeValidActive() {
    final active = _tracks[_active];
    if (_desired == DesiredTransport.playing &&
        active != null &&
        active.role == TrackRole.active &&
        !active.revoked) {
      _dispatch(() => backend.play(active.resource.trackHandleId), 'rollback');
    }
  }

  CommandAck replaceQueue(
    CommandContext c,
    List<QueueEntry> entries,
    int expectedRevision,
  ) {
    final signature = jsonEncode([
      'queue',
      expectedRevision,
      _queueSignature(entries),
    ]);
    final old = _existing(c, signature);
    if (old != null) {
      return old;
    }
    if (expectedRevision != _revision || !_validEntries(entries)) {
      return _reject(c, 'queue-conflict');
    }
    final activeId = snapshot.currentEntryId;
    if (activeId != null && !entries.any((e) => e.entryId == activeId)) {
      return _reject(c, 'diagnostic-active-removal-unsupported');
    }
    if (_requested != null && !entries.any((e) => e.entryId == _requested)) {
      _invalidatePrepare();
      _generation++;
      _currentRequest = null;
      _requested = null;
      if (_active == null) {
        _desired = DesiredTransport.stopped;
      }
    }
    _entries = List.unmodifiable(entries);
    _revision++;
    return _applied(c, signature);
  }

  void _onEvent(BackendEvent event) {
    if (_disposed || event.backendEpoch != _backendEpoch) {
      return;
    }
    final t = _tracks[event.trackHandleId];
    if (t == null ||
        event.backendEpoch != t.request.backendEpoch ||
        event.requestId != t.request.requestId ||
        event.generation != t.request.generation ||
        event.eventSequence <= t.sequence) {
      return;
    }
    t.sequence = event.eventSequence;
    if (event.kind == BackendEventKind.released) {
      _acceptRelease(
        t,
        ReleaseReceipt(
          t.resource.trackHandleId,
          t.resource.consumerId,
          event.backendEpoch,
        ),
      );
      return;
    }
    if (t.role == TrackRole.retiring ||
        t.role == TrackRole.released ||
        t.revoked) {
      return;
    }
    // Outgoing owns its resource despite having an earlier playback generation.
    if ((t.role == TrackRole.prepared || t.role == TrackRole.incoming) &&
        (t.request.generation != _generation ||
            t.request.requestId != _currentRequest)) {
      return;
    }
    switch (event.kind) {
      case BackendEventKind.playing:
        if (_desired != DesiredTransport.playing ||
            event.confirmationEvidence == null ||
            event.confirmationEvidence!.isEmpty) {
          return;
        }
        if (t.confirmation == null) {
          t.confirmation = '$sessionId:${++_confirmationCounter}';
          if (_confirmations.length == 64) {
            _confirmations.removeAt(0);
          }
          _confirmations.add(t.confirmation!);
        }
        if ((t.role == TrackRole.prepared || t.role == TrackRole.incoming) &&
            event.transitionId == t.request.transitionId) {
          final previous = _active == null ? null : _tracks[_active];
          if (previous != null && previous != t) {
            previous.role = TrackRole.outgoing;
          }
          t.transitionId = event.transitionId;
          t.role = TrackRole.active;
          _active = t.resource.trackHandleId;
          _position = event.positionMs;
          _duration = event.durationMs;
        }
      case BackendEventKind.error:
        _fail('backend-error', 'event');
        if (_active == t.resource.trackHandleId) {
          final fallback = _tracks.values
              .where((v) => v.role == TrackRole.outgoing && !v.revoked)
              .firstOrNull;
          if (fallback != null) {
            fallback.role = TrackRole.active;
            _active = fallback.resource.trackHandleId;
            _resumeValidActive();
          } else {
            _active = null;
            _desired = DesiredTransport.paused;
          }
        } else if (_active != null) {
          _resumeValidActive();
        } else {
          _desired = DesiredTransport.paused;
        }
        _release(t);
      case BackendEventKind.progress:
        if (_active == t.resource.trackHandleId && event.positionMs >= 0) {
          _position = event.positionMs;
          _duration = event.durationMs;
        }
      case BackendEventKind.ended:
        // Queue advancement is not delegated to a native callback in A02.
        if (_active == t.resource.trackHandleId) {
          _desired = _preview
              ? DesiredTransport.stopped
              : DesiredTransport.paused;
        }
        _release(t);
      case BackendEventKind.ready:
      case BackendEventKind.buffering:
      case BackendEventKind.released:
        break;
    }
    _cursor++;
  }

  void completeTransition(String incomingHandle, {String? transitionId}) {
    if (_disposed ||
        _active != incomingHandle ||
        _tracks[incomingHandle]?.request.transitionId != transitionId) {
      return;
    }
    for (final t
        in _tracks.values.where((t) => t.role == TrackRole.outgoing).toList()) {
      _release(t);
    }
  }

  void revokeResource(String handle) {
    final t = _tracks[handle];
    if (t == null || t.role == TrackRole.released) {
      return;
    }
    t.revoked = true;
    if (_active == handle) {
      _active = null;
      _desired = DesiredTransport.paused;
    }
    _release(t);
  }

  void _release(_Track t) {
    if (t.role == TrackRole.retiring || t.role == TrackRole.released) {
      return;
    }
    t.role = TrackRole.retiring;
    if (!_disposed) {
      t.releaseTimer = Timer(releaseTimeout, () {
        _fail('release-timeout', 'release');
      });
    }
    try {
      unawaited(
        backend
            .release(
              t.resource.trackHandleId,
              t.resource.consumerId,
              t.request.backendEpoch,
            )
            .then(
              (receipt) => _acceptRelease(t, receipt),
              onError: (Object error) {
                t.releaseTimer?.cancel();
                _fail('release-failure', 'release');
              },
            ),
      );
    } catch (_) {
      t.releaseTimer?.cancel();
      _fail('release-failure', 'release');
    }
  }

  void _acceptRelease(_Track t, ReleaseReceipt receipt) {
    if (receipt.trackHandleId != t.resource.trackHandleId ||
        receipt.consumerId != t.resource.consumerId ||
        receipt.backendEpoch != t.request.backendEpoch) {
      _fail('invalid-release-receipt', 'release');
      return;
    }
    t.releaseTimer?.cancel();
    t.role = TrackRole.released;
    if (_active == t.resource.trackHandleId) {
      _active = null;
    }
    if (!_disposed) {
      _cursor++;
      _drainWaiting();
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _invalidatePrepare();
    _disposed = true;
    _capacityTimer?.cancel();
    _generation++;
    _currentRequest = null;
    await _subscription.cancel();
    for (final t in _tracks.values) {
      _release(t);
      t.releaseTimer?.cancel();
    }
  }
}
