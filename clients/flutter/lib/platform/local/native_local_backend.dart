import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/playback/contracts.dart';
import 'native_evidence.dart';

class _Handle {
  _Handle(this.request, this.id);
  final PrepareRequest request;
  final String id;
  final prepared = Completer<PreparedTrack>();
  final evidence = NativeEvidence();
  bool intended = false, ready = false, confirmed = false, retiring = false;
  int sequence = 0;
  Future<void>? closing;
}

/// Thin transport only. The coordinator owns identities, queue and policies.
class NativeLocalBackend implements PlaybackBackend {
  NativeLocalBackend(this.files, {this.logFile}) {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _poll());
  }
  static const channel = MethodChannel('jj_music/local');
  final Map<String, String> files;
  final File? logFile;
  final _stream = StreamController<BackendEvent>.broadcast(sync: true);
  final _handles = <String, _Handle>{};
  final _system = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  Stream<Map<String, dynamic>> get systemCommands => _system.stream;
  final raw = <Map<String, dynamic>>[];
  Timer? _timer;
  int _next = 0;
  int _transportRevision = 0;
  bool _polling = false, _closed = false;
  Map<String, dynamic> lastHost = {};
  int get consumers => _handles.length;
  @override
  Stream<BackendEvent> get events => _stream.stream;
  void _record(Map<String, dynamic> value) {
    raw.add(value);
    if (raw.length > 400) {
      raw.removeAt(0);
    }
    // Bounded in-memory samples; explicit flush only, never log private sources.
  }

  Future<void> flushLog() async {
    if (logFile != null) {
      await logFile!.parent.create(recursive: true);
      await logFile!.writeAsString(raw.map(jsonEncode).join('\n'), flush: true);
    }
  }

  void _emit(_Handle h, BackendEventKind kind, Map<String, dynamic> s) {
    _stream.add(
      BackendEvent(
        kind: kind,
        trackHandleId: h.id,
        backendEpoch: h.request.backendEpoch,
        generation: h.request.generation,
        requestId: h.request.requestId,
        eventSequence: ++h.sequence,
        positionMs: s['position'] as int? ?? 0,
        durationMs: s['duration'] as int?,
        transitionId: h.request.transitionId,
        confirmationEvidence: kind == BackendEventKind.playing
            ? '${s['platform']}:native-ready-running-advancing:${h.sequence}'
            : null,
      ),
    );
  }

  Future<void> _poll() async {
    if (_polling || _closed) {
      return;
    }
    _polling = true;
    try {
      final reply = Map<String, dynamic>.from(
        await channel.invokeMapMethod<String, dynamic>('poll') ?? {},
      );
      lastHost = reply;
      for (final action in reply['commands'] as List? ?? []) {
        final command = Map<String, dynamic>.from(action as Map);
        // The reply can have left native before a newer Dart intent arrived.
        // Validate the revision stamped by native at the focus request, rather
        // than poll start time (which could discard a genuinely NEW loss).
        if (command.containsKey('focusEpoch') &&
            command['transportRevision'] != _transportRevision) {
          _record({'ignoredStaleFocus': command});
          continue;
        }
        _record({'systemCommand': action});
        _system.add(command);
      }
      for (final value in reply['samples'] as List? ?? []) {
        final s = Map<String, dynamic>.from(value as Map);
        _record(s);
        final h = _handles[s['id']];
        if (h == null || h.retiring) {
          continue;
        }
        if (s['error'] == true) {
          if (!h.prepared.isCompleted) {
            h.prepared.completeError(StateError('native-load-failed'));
          } else {
            _emit(h, BackendEventKind.error, s);
          }
          continue;
        }
        if (s['ready'] == true && !h.ready) {
          h.ready = true;
          h.prepared.complete(
            PreparedTrack(
              h.id,
              consumerId: 'consumer-${h.id}',
              resourceRevision: 'owned-fixture-v2',
              canSeek: s['canSeek'] as bool?,
            ),
          );
          _emit(h, BackendEventKind.ready, s);
        }
        if (h.evidence.observe(s, intended: h.intended) && !h.confirmed) {
          h.confirmed = true;
          _emit(h, BackendEventKind.playing, s);
        }
        if (s['state'] == 2) {
          _emit(h, BackendEventKind.buffering, s);
        }
        _emit(h, BackendEventKind.progress, s);
        if (s['ended'] == true && h.intended) {
          h.intended = false;
          _emit(h, BackendEventKind.ended, s);
        }
      }
    } catch (e) {
      _record({'bridgeError': e.runtimeType.toString()});
    } finally {
      _polling = false;
    }
  }

  @override
  Future<PreparedTrack> prepare(PrepareRequest request) async {
    if (_closed || _handles.length >= 2) {
      throw StateError('native-capacity');
    }
    final path = files[request.entry.fixtureId];
    if (path == null) {
      throw StateError('fixture-not-authorized');
    }
    ++_transportRevision;
    final h = _Handle(request, 'native-${++_next}');
    _handles[h.id] = h;
    // Attach error handler before cancellation can complete the future.
    final result = h.prepared.future.timeout(const Duration(seconds: 8));
    // A stop can finish this before the allocation method-channel reply arrives.
    // Observe immediately, then propagate the same failure to the caller below.
    unawaited(
      result.then<void>((_) {}, onError: (Object _, StackTrace trace) {}),
    );
    try {
      await channel.invokeMethod<void>('prepare', {'id': h.id, 'path': path});
      final resource = await result;
      if (request.startPositionMs > 0 && !h.retiring) {
        await channel.invokeMethod<void>('seek', {
          'id': h.id,
          'position': request.startPositionMs,
        });
        h.evidence.reset();
      }
      return resource;
    } catch (_) {
      await _closeHandle(h);
      rethrow;
    }
  }

  Future<void> _closeHandle(_Handle h) {
    if (h.closing != null) {
      return h.closing!;
    }
    h.retiring = true;
    return h.closing = () async {
      await channel.invokeMethod<void>('release', {'id': h.id});
      _handles.remove(h.id);
    }();
  }

  @override
  Future<void> cancelPrepare(String requestId) async {
    for (final h in _handles.values.toList()) {
      if (h.request.requestId == requestId && !h.prepared.isCompleted) {
        h.prepared.completeError(StateError('prepare-cancelled'));
        await _closeHandle(h);
      }
    }
  }

  @override
  Future<void> play(String trackHandleId) async {
    final revision = ++_transportRevision;
    final h = _handles[trackHandleId]!;
    for (final other in _handles.values.where((v) => v != h)) {
      other.intended = false;
      other.evidence.reset();
    }
    h.intended = true;
    h.evidence.reset();
    try {
      await channel.invokeMethod<void>('play', {
        'id': h.id,
        'transportRevision': revision,
      });
    } catch (_) {
      if (!h.retiring) {
        h.intended = false;
        _emit(h, BackendEventKind.error, {'position': 0});
      }
      rethrow;
    }
  }

  Future<void> _all(String method) async {
    ++_transportRevision;
    for (final h in _handles.values.toList()) {
      h.intended = false;
      h.evidence.reset();
    }
    await channel.invokeMethod<void>(method);
  }

  @override
  Future<void> pause() => _all('pause');
  @override
  Future<void> stop() => _all('stop');
  @override
  Future<void> seek(String trackHandleId, int positionMs) async {
    _handles[trackHandleId]?.evidence.reset();
    await channel.invokeMethod<void>('seek', {
      'id': trackHandleId,
      'position': positionMs,
    });
  }

  @override
  Future<ReleaseReceipt> release(
    String trackHandleId,
    String consumerId,
    int backendEpoch,
  ) async {
    final h = _handles[trackHandleId];
    if (h != null) {
      await _closeHandle(h);
    }
    return ReleaseReceipt(trackHandleId, consumerId, backendEpoch);
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    for (final h in _handles.values.toList()) {
      await _closeHandle(h);
    }
    await flushLog();
    await _stream.close();
    await _system.close();
  }

  Future<List<ReleaseReceipt>> destroyNativeResources() async {
    final all = _handles.values.toList();
    final receipts = <ReleaseReceipt>[];
    for (final h in all) {
      if (!h.prepared.isCompleted) {
        h.prepared.completeError(StateError('backend-destroyed'));
      }
      await _closeHandle(h);
      receipts.add(
        ReleaseReceipt(h.id, 'consumer-${h.id}', h.request.backendEpoch),
      );
    }
    return receipts;
  }
}
