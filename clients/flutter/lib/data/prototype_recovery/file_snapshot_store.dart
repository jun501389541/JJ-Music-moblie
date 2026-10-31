import 'dart:convert';
import 'dart:io';

import '../../domain/playback/recovery_snapshot.dart';

class _WriteQueue {
  Future<void> tail = Future.value();
  int pending = 0;
}

/// P1 fixture-only two-slot journal. Not a production DB or a power-loss guarantee.
class FileSnapshotStore implements RecoverySnapshotStore {
  FileSnapshotStore({
    required Directory root,
    required this.runId,
    required Set<String> allowedFixtureIds,
  }) : allowedFixtureIds = Set.unmodifiable(allowedFixtureIds),
       directory = Directory(
         '${root.absolute.path}${Platform.pathSeparator}$runId',
       ) {
    if (!_id.hasMatch(runId)) {
      throw const FormatException('invalid-run-id');
    }
  }
  static const maxBytes = 256 * 1024;
  static final _id = RegExp(r'^[A-Za-z0-9_-]{1,80}$');
  static final _queues = <String, _WriteQueue>{};
  final String runId;
  final Directory directory;
  final Set<String> allowedFixtureIds;

  void _validate(RecoverySnapshot s) {
    if (s.runId != runId ||
        !_id.hasMatch(s.playbackSessionId) ||
        s.revision < 0 ||
        s.positionMs < 0 ||
        s.entries.length > 16 ||
        s.confirmations.length > 64 ||
        s.entries.map((e) => e.entryId).toSet().length != s.entries.length ||
        (s.entries.isEmpty
            ? s.currentIndex != -1
            : s.currentIndex < 0 || s.currentIndex >= s.entries.length)) {
      throw const FormatException('invalid-snapshot');
    }
    for (final e in s.entries) {
      if (!_id.hasMatch(e.entryId) ||
          !_id.hasMatch(e.trackKey) ||
          !allowedFixtureIds.contains(e.fixtureId)) {
        throw const FormatException('fixture-unavailable');
      }
    }
    if (s.confirmations.any(
      (id) => !RegExp(r'^[A-Za-z0-9_:.-]{1,128}$').hasMatch(id),
    )) {
      throw const FormatException('invalid-confirmation');
    }
  }

  @override
  Future<SnapshotSaveReceipt> save(RecoverySnapshot snapshot) {
    final key = directory.absolute.path.toLowerCase();
    final queue = _queues.putIfAbsent(key, _WriteQueue.new);
    if (queue.pending >= 8) {
      return Future.error(StateError('snapshot-write-capacity'));
    }
    queue.pending++;
    final result = queue.tail.then((_) => _write(snapshot));
    void finished() {
      queue.pending--;
      if (queue.pending == 0 && identical(_queues[key], queue)) {
        _queues.remove(key);
      }
    }

    queue.tail = result.then<void>(
      (_) {
        finished();
      },
      onError: (Object error, StackTrace stack) {
        finished();
      },
    );
    return result;
  }

  Future<SnapshotSaveReceipt> _write(RecoverySnapshot snapshot) async {
    _validate(snapshot);
    final encoded = utf8.encode(jsonEncode(snapshot.toJson()));
    if (encoded.length > maxBytes) {
      throw const FormatException('snapshot-too-large');
    }
    final previous = (await load()).snapshot;
    if (previous != null && snapshot.revision <= previous.revision) {
      if (snapshot.revision == previous.revision &&
          jsonEncode(snapshot.toJson()) == jsonEncode(previous.toJson())) {
        return SnapshotSaveReceipt(runId, snapshot.revision);
      }
      throw StateError('stale-snapshot-revision');
    }
    await directory.create(recursive: true);
    final name = snapshot.revision.isEven
        ? 'snapshot-a.json'
        : 'snapshot-b.json';
    final target = File('${directory.path}${Platform.pathSeparator}$name');
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsBytes(encoded, flush: true);
    await temporary.rename(target.path);
    return SnapshotSaveReceipt(runId, snapshot.revision);
  }

  @override
  Future<SnapshotReadResult> load() async {
    RecoverySnapshot? latest;
    final issues = <String>[];
    for (final name in ['snapshot-a.json', 'snapshot-b.json']) {
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      if (!await file.exists()) {
        continue;
      }
      try {
        // Bound the actual read as well as metadata: external replacement cannot allocate an arbitrary file.
        final data = await file
            .openRead(0, maxBytes + 1)
            .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
        if (data.length > maxBytes) {
          issues.add('snapshot-too-large');
          continue;
        }
        final value = jsonDecode(utf8.decode(data));
        if (value is! Map<String, dynamic>) {
          throw const FormatException('invalid-snapshot');
        }
        final candidate = RecoverySnapshot.decode(value);
        _validate(candidate);
        if (latest == null || candidate.revision > latest.revision) {
          latest = candidate;
        }
      } catch (_) {
        issues.add('snapshot-invalid-or-unreadable');
      }
    }
    return SnapshotReadResult(latest, issues);
  }
}
