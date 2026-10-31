import 'contracts.dart';

class RecoverySnapshot {
  RecoverySnapshot({
    required this.runId,
    required this.revision,
    required this.playbackSessionId,
    required List<QueueEntry> entries,
    required this.currentIndex,
    this.positionMs = 0,
    this.mode = PlaybackMode.sequence,
    this.preview = false,
    List<String> confirmations = const [],
  }) : entries = List.unmodifiable(entries),
       confirmations = List.unmodifiable(confirmations);
  final String runId, playbackSessionId;
  final int revision, currentIndex, positionMs;
  final List<QueueEntry> entries;
  final List<String> confirmations;
  final PlaybackMode mode;
  final bool preview;
  Map<String, Object?> toJson() => {
    'formatVersion': 1,
    'runId': runId,
    'revision': revision,
    'playbackSessionId': playbackSessionId,
    'entries': entries
        .map(
          (e) => {
            'entryId': e.entryId,
            'trackKey': e.trackKey,
            'fixtureId': e.fixtureId,
          },
        )
        .toList(),
    'currentIndex': currentIndex,
    'positionMs': positionMs,
    'mode': mode.name,
    'preview': preview,
    'confirmations': confirmations,
  };
  static RecoverySnapshot decode(Map<String, dynamic> json) {
    const fields = {
      'formatVersion',
      'runId',
      'revision',
      'playbackSessionId',
      'entries',
      'currentIndex',
      'positionMs',
      'mode',
      'preview',
      'confirmations',
    };
    if (json['formatVersion'] != 1 ||
        json.keys.toSet().difference(fields).isNotEmpty ||
        fields.difference(json.keys.toSet()).isNotEmpty) {
      throw const FormatException('unsupported-snapshot');
    }
    final rawEntries = json['entries'] as List<dynamic>;
    final entries = rawEntries.map((value) {
      final e = value as Map<String, dynamic>;
      if (e.keys.toSet().difference({
            'entryId',
            'trackKey',
            'fixtureId',
          }).isNotEmpty ||
          e.length != 3) {
        throw const FormatException('invalid-entry');
      }
      return QueueEntry(
        entryId: e['entryId'] as String,
        trackKey: e['trackKey'] as String,
        fixtureId: e['fixtureId'] as String,
      );
    }).toList();
    return RecoverySnapshot(
      runId: json['runId'] as String,
      revision: json['revision'] as int,
      playbackSessionId: json['playbackSessionId'] as String,
      entries: entries,
      currentIndex: json['currentIndex'] as int,
      positionMs: json['positionMs'] as int,
      mode: PlaybackMode.values.byName(json['mode'] as String),
      preview: json['preview'] as bool,
      confirmations: (json['confirmations'] as List<dynamic>).cast<String>(),
    );
  }
}

class SnapshotSaveReceipt {
  const SnapshotSaveReceipt(this.runId, this.revision);
  final String runId;
  final int revision;
}

class SnapshotReadResult {
  SnapshotReadResult(this.snapshot, List<String> issues)
    : issues = List.unmodifiable(issues);
  final RecoverySnapshot? snapshot;
  final List<String> issues;
  DesiredTransport get restoredTransport => DesiredTransport.paused;
}

abstract interface class RecoverySnapshotStore {
  Future<SnapshotSaveReceipt> save(RecoverySnapshot snapshot);
  Future<SnapshotReadResult> load();
}
