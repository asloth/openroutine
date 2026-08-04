import 'package:drift/drift.dart';

import '../drift/app_database.dart' as db;

/// What still needs to reach Drive, and when it is worth trying again.
///
/// Deliberately not a queue of edits. Every push uploads the whole
/// `routines.json` (docs/SPEC.md §5), so recording *which* routine changed
/// would be extra state that collapses to the same upload. One dirty flag says
/// everything the push needs to know.
///
/// Completions are the exception, because they are sharded per month into
/// `completions/YYYY-MM.ndjson`. There we do track which shards are stale, so
/// a run in August never drags July's file through a round trip.
///
/// The dirty flags are persisted; the backoff is not. On a cold start it is
/// right to try once immediately — whatever made the last attempt fail was
/// most likely the network, and the app has just been reopened.
class SyncQueue {
  SyncQueue(this._db);

  final db.AppDatabase _db;

  /// One row, always. Sync state is a property of the install, not a list.
  static const _rowId = 0;

  /// Caps at ~5 minutes. Long enough to stop hammering a failing endpoint,
  /// short enough that a user who regains signal does not sit and wait.
  static const _backoffCeiling = Duration(minutes: 5);

  int _consecutiveFailures = 0;

  Future<db.SyncStateData> _read() async {
    final existing = await (_db.select(
      _db.syncState,
    )..where((r) => r.id.equals(_rowId))).getSingleOrNull();
    if (existing != null) return existing;

    await _db
        .into(_db.syncState)
        .insert(db.SyncStateCompanion.insert(id: const Value(_rowId)));
    return (_db.select(
      _db.syncState,
    )..where((r) => r.id.equals(_rowId))).getSingle();
  }

  Future<void> _write(db.SyncStateCompanion values) async {
    await _read();
    await (_db.update(_db.syncState)
          ..where((r) => r.id.equals(_rowId)))
        .write(values);
  }

  Future<bool> get routinesDirty async => (await _read()).routinesDirty;

  Future<Set<String>> get dirtyCompletionMonths async {
    final raw = (await _read()).dirtyCompletionMonths;
    if (raw.isEmpty) return const {};
    return raw.split(',').toSet();
  }

  Future<DateTime?> get lastSyncAt async => (await _read()).lastSyncAt;

  Future<String?> get lastError async => (await _read()).lastError;

  Future<bool> get hasWork async =>
      await routinesDirty || (await dirtyCompletionMonths).isNotEmpty;

  Future<void> markRoutinesDirty() =>
      _write(const db.SyncStateCompanion(routinesDirty: Value(true)));

  /// [month] is `YYYY-MM`, matching the shard filename.
  Future<void> markCompletionMonthDirty(String month) async {
    final months = {...await dirtyCompletionMonths, month};
    await _write(
      db.SyncStateCompanion(
        dirtyCompletionMonths: Value((months.toList()..sort()).join(',')),
      ),
    );
  }

  Future<void> clearRoutines() =>
      _write(const db.SyncStateCompanion(routinesDirty: Value(false)));

  Future<void> clearCompletionMonth(String month) async {
    final months = {...await dirtyCompletionMonths}..remove(month);
    await _write(
      db.SyncStateCompanion(
        dirtyCompletionMonths: Value((months.toList()..sort()).join(',')),
      ),
    );
  }

  Future<void> recordSuccess(DateTime at) async {
    _consecutiveFailures = 0;
    await _write(
      db.SyncStateCompanion(
        lastSyncAt: Value(at),
        lastError: const Value(null),
      ),
    );
  }

  /// Records a failure worth retrying. Auth expiry must NOT come through here:
  /// no amount of waiting fixes a revoked grant, and retrying it on a timer
  /// would spend battery to keep rediscovering the same answer. That path
  /// parks in `needsReauth` and waits for the user instead.
  Future<void> recordRetryableFailure(String message) async {
    _consecutiveFailures++;
    await _write(db.SyncStateCompanion(lastError: Value(message)));
  }

  Future<void> recordAuthExpired(String message) async {
    _consecutiveFailures = 0;
    await _write(db.SyncStateCompanion(lastError: Value(message)));
  }

  /// How long to wait before the next attempt: 2s, 4s, 8s … capped.
  Duration get backoff {
    if (_consecutiveFailures == 0) return Duration.zero;
    final seconds = 1 << _consecutiveFailures.clamp(1, 8);
    final candidate = Duration(seconds: seconds);
    return candidate > _backoffCeiling ? _backoffCeiling : candidate;
  }

  /// Exposed so a test can assert that auth expiry does not accumulate
  /// backoff the way a retryable failure does.
  int get consecutiveFailures => _consecutiveFailures;
}
