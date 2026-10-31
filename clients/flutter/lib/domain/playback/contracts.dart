import 'dart:async';

const playbackProtocolVersion = 1;

enum DesiredTransport { stopped, paused, playing }

enum PlaybackMode { sequence, repeatOne, repeatAll, shuffle }

enum TrackRole { prepared, active, incoming, outgoing, retiring, released }

enum BackendEventKind {
  ready,
  playing,
  buffering,
  progress,
  ended,
  error,
  released,
}

class QueueEntry {
  const QueueEntry({
    required this.entryId,
    required this.trackKey,
    required this.fixtureId,
  });
  final String entryId;
  final String trackKey;
  final String fixtureId;
}

class ControllerClaim {
  const ControllerClaim(
    this.ownerId,
    this.coordinatorEpoch,
    this.playbackSessionId,
  );
  final String ownerId;
  final int coordinatorEpoch;
  final String playbackSessionId;
}

class CommandContext {
  const CommandContext(
    this.requestId,
    this.claim, {
    this.protocolVersion = playbackProtocolVersion,
  });
  final String requestId;
  final ControllerClaim claim;
  final int protocolVersion;
}

class PlaybackFailure {
  const PlaybackFailure(
    this.code,
    this.stage, {
    this.retryable = false,
    this.userMessage = '诊断操作未完成',
    this.diagnosticId = 'playback-contract',
  });
  final String code, stage, userMessage, diagnosticId;
  final bool retryable;
}

class CommandAck {
  const CommandAck(
    this.requestId, {
    this.accepted = false,
    this.applied = false,
    this.failure,
  });
  final String requestId;
  final bool accepted, applied;
  final PlaybackFailure? failure;
}

class PlayIntent {
  PlayIntent({
    required List<QueueEntry> entries,
    required this.entryId,
    this.preview = false,
    this.mode = PlaybackMode.sequence,
    this.startPositionMs = 0,
  }) : entries = List.unmodifiable(entries);
  final List<QueueEntry> entries;
  final String entryId;
  final bool preview;
  final PlaybackMode mode;
  final int startPositionMs;
}

class PrepareRequest {
  const PrepareRequest({
    required this.requestId,
    required this.entry,
    required this.generation,
    required this.backendEpoch,
    this.transitionId,
    this.startPositionMs = 0,
  });
  final String requestId;
  final QueueEntry entry;
  final int generation, backendEpoch;
  final int startPositionMs;
  final String? transitionId;
}

class PreparedTrack {
  const PreparedTrack(
    this.trackHandleId, {
    required this.consumerId,
    required this.resourceRevision,
    required this.canSeek,
  });
  final String trackHandleId, consumerId, resourceRevision;

  /// Null means unknown, never permission to seek. Bound to this resource.
  final bool? canSeek;
}

class ReleaseReceipt {
  const ReleaseReceipt(this.trackHandleId, this.consumerId, this.backendEpoch);
  final String trackHandleId, consumerId;
  final int backendEpoch;
}

/// Adapter-normalized events, not raw plugin callbacks. Actual mapping is A03/A05.
class BackendEvent {
  const BackendEvent({
    required this.kind,
    required this.trackHandleId,
    required this.backendEpoch,
    required this.generation,
    required this.requestId,
    required this.eventSequence,
    this.positionMs = 0,
    this.durationMs,
    this.confirmationEvidence,
    this.transitionId,
  });
  final BackendEventKind kind;
  final String trackHandleId, requestId;
  final int backendEpoch, generation, eventSequence, positionMs;
  final int? durationMs;
  final String? confirmationEvidence, transitionId;
}

abstract interface class PlaybackBackend {
  Stream<BackendEvent> get events;
  Future<PreparedTrack> prepare(PrepareRequest request);
  Future<void> cancelPrepare(String requestId);
  Future<void> play(String trackHandleId);
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(String trackHandleId, int positionMs);

  /// Completes only when this consumer has actually stopped reading.
  Future<ReleaseReceipt> release(
    String trackHandleId,
    String consumerId,
    int backendEpoch,
  );
}

class TrackSnapshot {
  const TrackSnapshot({
    required this.trackHandleId,
    required this.entry,
    required this.consumerId,
    required this.resourceRevision,
    required this.role,
    required this.backendEpoch,
    required this.generation,
    required this.revoked,
    this.playbackConfirmationId,
  });
  final String trackHandleId, consumerId, resourceRevision;
  final QueueEntry entry;
  final TrackRole role;
  final int backendEpoch, generation;
  final bool revoked;
  final String? playbackConfirmationId;
}

class PlaybackSnapshot {
  PlaybackSnapshot({
    required this.playbackSessionId,
    required this.coordinatorEpoch,
    required this.backendEpoch,
    required this.brokerEpoch,
    required this.playbackGeneration,
    required this.queueRevision,
    required this.eventCursor,
    required this.desired,
    required List<QueueEntry> entries,
    required List<TrackSnapshot> tracks,
    required List<String> confirmations,
    this.currentEntryId,
    this.requestedEntryId,
    this.uiConnectionId,
    this.positionMs = 0,
    this.durationMs,
    this.preview = false,
    this.mode = PlaybackMode.sequence,
  }) : entries = List.unmodifiable(entries),
       tracks = List.unmodifiable(tracks),
       confirmations = List.unmodifiable(confirmations);
  final String playbackSessionId;
  final String? currentEntryId, requestedEntryId, uiConnectionId;
  final int coordinatorEpoch,
      backendEpoch,
      brokerEpoch,
      playbackGeneration,
      queueRevision,
      eventCursor,
      positionMs;
  final int? durationMs;
  final DesiredTransport desired;
  final PlaybackMode mode;
  final bool preview;
  final List<QueueEntry> entries;
  final List<TrackSnapshot> tracks;
  final List<String> confirmations;
}
