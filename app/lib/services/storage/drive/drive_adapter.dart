import '../../../models/completion_log.dart';
import '../../../models/export_bundle.dart';
import '../../../models/import_preview.dart';
import '../../../models/routine.dart';
import '../../../models/step.dart';
import '../../../models/trigger.dart';
import '../local_adapter.dart';
import '../storage_adapter.dart';
import 'drive_layout.dart';
import 'sync_queue.dart';

/// StorageAdapter for Drive-backed installs.
///
/// It is a decorator, not a replacement. docs/SPEC.md §5 makes the local drift
/// database the source of truth for reads and gives Drive a sync worker that
/// reconciles in the background — so Drive is a layer above local storage, not
/// an alternative to it. Concretely:
///
/// - **Reads never touch the network.** Every read is [LocalAdapter]'s.
/// - **Writes commit locally and return.** They then mark the queue dirty and
///   poke [onLocalChange], which the sync provider debounces. The user's edit
///   is never waiting on a round trip; §1 calls the app offline-first and an
///   edit that blocks on connectivity would not be.
///
/// This also means switching storage mode cannot lose data: the same rows back
/// both modes, and disconnecting simply stops the syncing.
class DriveAdapter implements StorageAdapter {
  DriveAdapter({
    required LocalAdapter local,
    required SyncQueue queue,
    required void Function() onLocalChange,
  }) : _local = local,
       _queue = queue,
       _onLocalChange = onLocalChange;

  final LocalAdapter _local;
  final SyncQueue _queue;
  final void Function() _onLocalChange;

  // ---- Reads: straight through to local. ----

  @override
  Stream<List<Routine>> watchRoutines() => _local.watchRoutines();

  @override
  Future<Routine?> getRoutine(String id) => _local.getRoutine(id);

  @override
  Future<List<RoutineStep>> getSteps(String routineId) =>
      _local.getSteps(routineId);

  @override
  Future<List<Trigger>> getTriggers() => _local.getTriggers();

  @override
  Future<List<CompletionLog>> getCompletions(
    String routineId, {
    DateTime? since,
  }) => _local.getCompletions(routineId, since: since);

  @override
  Future<ExportBundle> exportAll() => _local.exportAll();

  @override
  Future<ExportBundle> exportRoutine(String id) => _local.exportRoutine(id);

  @override
  Future<ImportPreview> previewImport(ExportBundle bundle) =>
      _local.previewImport(bundle);

  // ---- Writes: local first, then mark dirty. ----

  @override
  Future<void> saveRoutine(Routine routine) =>
      _mutate(() => _local.saveRoutine(routine));

  @override
  Future<void> saveStep(RoutineStep step) =>
      _mutate(() => _local.saveStep(step));

  @override
  Future<void> saveTrigger(Trigger trigger) =>
      _mutate(() => _local.saveTrigger(trigger));

  @override
  Future<void> deleteRoutine(String id) =>
      _mutate(() => _local.deleteRoutine(id));

  @override
  Future<void> deleteStep(String id) => _mutate(() => _local.deleteStep(id));

  @override
  Future<void> confirmImport(ExportBundle bundle) =>
      _mutate(() => _local.confirmImport(bundle));

  /// Completions land in a monthly shard, so this marks that shard rather than
  /// the routines file — a run in August must not drag July's ndjson through a
  /// round trip (docs/SPEC.md §5).
  @override
  Future<void> appendCompletion(CompletionLog log) async {
    await _local.appendCompletion(log);
    await _queue.markCompletionMonthDirty(
      DriveLayout.monthKeyFor(log.startedAt),
    );
    _onLocalChange();
  }

  Future<void> _mutate(Future<void> Function() write) async {
    await write();
    await _queue.markRoutinesDirty();
    _onLocalChange();
  }
}
