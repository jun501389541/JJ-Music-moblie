import 'dart:async';

import 'package:jj_music_mobile/domain/playback/contracts.dart';

/// Test-only controllable I/O boundary: never decodes or outputs audio.
class ControlledBackend implements PlaybackBackend {
  final pending = <String, Completer<PreparedTrack>>{};
  final requests = <String, PrepareRequest>{};
  final actions = <String>[];
  final releases = <String, Completer<ReleaseReceipt>>{};
  final _events = StreamController<BackendEvent>.broadcast(sync: true);
  bool holdRelease = false;
  bool holdPlay = false;
  final playing = Completer<void>();
  @override
  Stream<BackendEvent> get events => _events.stream;
  @override
  Future<PreparedTrack> prepare(PrepareRequest request) {
    requests[request.requestId] = request;
    actions.add('prepare:${request.requestId}');
    return (pending[request.requestId] = Completer<PreparedTrack>()).future;
  }

  void ready(String id, String handle) => pending[id]!.complete(
    PreparedTrack(
      handle,
      consumerId: 'consumer-$handle',
      resourceRevision: 'fixture-v1',
    ),
  );
  void emit(
    String id,
    String handle,
    BackendEventKind kind,
    int sequence, {
    String? evidence = 'controlled-contract-v1',
    int? epoch,
    int? generation,
    String? transitionId,
  }) {
    final r = requests[id]!;
    _events.add(
      BackendEvent(
        kind: kind,
        trackHandleId: handle,
        requestId: id,
        backendEpoch: epoch ?? r.backendEpoch,
        generation: generation ?? r.generation,
        eventSequence: sequence,
        confirmationEvidence: evidence,
        transitionId: transitionId ?? r.transitionId,
      ),
    );
  }

  @override
  Future<void> cancelPrepare(String requestId) async {
    actions.add('cancel:$requestId');
  }

  @override
  Future<void> play(String handle) {
    actions.add('play:$handle');
    return holdPlay ? playing.future : Future.value();
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
  Future<void> seek(String handle, int positionMs) async {
    actions.add('seek:$handle:$positionMs');
  }

  @override
  Future<ReleaseReceipt> release(String handle, String consumer, int epoch) {
    actions.add('release:$handle');
    if (holdRelease) {
      return (releases[handle] = Completer<ReleaseReceipt>()).future;
    }
    return Future.value(ReleaseReceipt(handle, consumer, epoch));
  }

  Future<void> close() => _events.close();
}
