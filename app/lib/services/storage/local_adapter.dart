// `Trigger` is hidden: drift's core query_builder library exports its own
// `Trigger` class (for SQL triggers), which collides with our domain model
// of the same name — unrelated to the db.Trigger row-class collision below.
import 'package:drift/drift.dart' hide Trigger;

import '../../models/export_bundle.dart';
import '../../models/import_preview.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/step.dart';
import '../../models/trigger.dart';
import 'drift/app_database.dart' as db;
import 'storage_adapter.dart';

const _schemaVersion = '1.0.0';

/// Drift-backed StorageAdapter — the only adapter in M2. Drift's generated
/// row classes (`db.Routine`, `db.RoutineStep`, `db.Trigger`) collide by
/// name with our freezed domain models, so the drift import is aliased to
/// `db` and only used inside this file's private mapping helpers; the
/// public API surface exposes only the domain models.
class LocalAdapter implements StorageAdapter {
  LocalAdapter(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Routine>> watchRoutines() {
    final query = _db.select(_db.routines)..where((r) => r.deletedAt.isNull());
    return query.watch().asyncMap((rows) async {
      final routines = <Routine>[];
      for (final row in rows) {
        routines.add(_routineFromRow(row, await _orderedStepIds(row.id)));
      }
      return routines;
    });
  }

  @override
  Future<Routine?> getRoutine(String id) async {
    final row = await _rawRoutineRow(id);
    if (row == null || row.deletedAt != null) return null;
    return _routineFromRow(row, await _orderedStepIds(id));
  }

  @override
  Future<List<RoutineStep>> getSteps(String routineId) async {
    final rows =
        await (_db.select(_db.routineSteps)
              ..where(
                (s) => s.routineId.equals(routineId) & s.deletedAt.isNull(),
              )
              ..orderBy([(s) => OrderingTerm.asc(s.order)]))
            .get();
    return rows.map(_stepFromRow).toList();
  }

  @override
  Future<List<Trigger>> getTriggers() async {
    final rows = await _db.select(_db.triggers).get();
    return rows.map(_triggerFromRow).toList();
  }

  @override
  Future<void> saveRoutine(Routine routine) {
    return _db
        .into(_db.routines)
        .insertOnConflictUpdate(
          db.RoutinesCompanion.insert(
            id: routine.id,
            name: routine.name,
            triggerId: Value(routine.triggerId),
            scheduleMode: routine.schedule.mode,
            scheduleDays: Value(routine.schedule.days),
            scheduleStartTime: Value(routine.schedule.startTime),
            createdAt: routine.createdAt,
            updatedAt: routine.updatedAt,
            deletedAt: Value(routine.deletedAt),
          ),
        );
  }

  @override
  Future<void> saveStep(RoutineStep step) {
    return _db
        .into(_db.routineSteps)
        .insertOnConflictUpdate(
          db.RoutineStepsCompanion.insert(
            id: step.id,
            routineId: step.routineId,
            name: step.name,
            emoji: step.emoji,
            durationSeconds: Value(step.durationSeconds),
            order: step.order,
            noExplicitTime: step.noExplicitTime,
            createdAt: step.createdAt,
            updatedAt: step.updatedAt,
            deletedAt: Value(step.deletedAt),
          ),
        );
  }

  @override
  Future<void> saveTrigger(Trigger trigger) {
    return _db
        .into(_db.triggers)
        .insertOnConflictUpdate(
          db.TriggersCompanion.insert(
            id: trigger.id,
            name: trigger.name,
            kind: trigger.kind.name,
            createdAt: trigger.createdAt,
            updatedAt: trigger.updatedAt,
          ),
        );
  }

  @override
  Future<void> deleteRoutine(String id) async {
    final now = nowUtc();
    await (_db.update(_db.routines)..where((r) => r.id.equals(id))).write(
      db.RoutinesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> deleteStep(String id) async {
    final now = nowUtc();
    await (_db.update(_db.routineSteps)..where((s) => s.id.equals(id))).write(
      db.RoutineStepsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<ExportBundle> exportAll() async {
    final routines = await watchRoutines().first;
    final steps = <RoutineStep>[];
    for (final routine in routines) {
      steps.addAll(await getSteps(routine.id));
    }
    final triggers = await getTriggers();
    return ExportBundle(
      schemaVersion: _schemaVersion,
      exportedAt: nowUtc(),
      routines: routines,
      steps: steps,
      triggers: triggers,
    );
  }

  @override
  Future<ExportBundle> exportRoutine(String id) async {
    final routine = await getRoutine(id);
    if (routine == null) {
      return ExportBundle(
        schemaVersion: _schemaVersion,
        exportedAt: nowUtc(),
        routines: const [],
        steps: const [],
        triggers: const [],
      );
    }
    final steps = await getSteps(id);
    final triggers = <Trigger>[];
    if (routine.triggerId != null) {
      final row = await _rawTriggerRow(routine.triggerId!);
      if (row != null) triggers.add(_triggerFromRow(row));
    }
    return ExportBundle(
      schemaVersion: _schemaVersion,
      exportedAt: nowUtc(),
      routines: [routine],
      steps: steps,
      triggers: triggers,
    );
  }

  @override
  Future<ImportPreview> previewImport(ExportBundle bundle) async {
    final plan = await _planImport(bundle);
    return plan.preview;
  }

  @override
  Future<void> confirmImport(ExportBundle bundle) async {
    final plan = await _planImport(bundle);
    // Triggers and routines before steps, so steps' routine_id FK always
    // resolves; triggers before routines for the same reason.
    for (final trigger in plan.triggersToWrite) {
      await saveTrigger(trigger);
    }
    for (final routine in plan.routinesToWrite) {
      await saveRoutine(routine);
    }
    for (final step in plan.stepsToWrite) {
      await saveStep(step);
    }
  }

  /// Computes exactly what confirmImport will write, so the preview screen
  /// and the actual import can never disagree. Compares against the raw
  /// (soft-delete-inclusive) row so an older import can't resurrect
  /// something the user deleted locally — see docs/SPEC.md §5.
  Future<_ImportPlan> _planImport(ExportBundle bundle) async {
    final routinesToWrite = <Routine>[];
    var newRoutines = 0;
    var updatedRoutines = 0;
    for (final routine in bundle.routines) {
      final existing = await _rawRoutineRow(routine.id);
      if (existing == null) {
        routinesToWrite.add(routine);
        newRoutines++;
      } else if (routine.updatedAt.isAfter(existing.updatedAt)) {
        routinesToWrite.add(routine);
        updatedRoutines++;
      }
    }

    final stepsToWrite = <RoutineStep>[];
    var newSteps = 0;
    var updatedSteps = 0;
    for (final step in bundle.steps) {
      final existing = await _rawStepRow(step.id);
      if (existing == null) {
        stepsToWrite.add(step);
        newSteps++;
      } else if (step.updatedAt.isAfter(existing.updatedAt)) {
        stepsToWrite.add(step);
        updatedSteps++;
      }
    }

    final triggersToWrite = <Trigger>[];
    var newTriggers = 0;
    var updatedTriggers = 0;
    for (final trigger in bundle.triggers) {
      final existing = await _rawTriggerRow(trigger.id);
      if (existing == null) {
        triggersToWrite.add(trigger);
        newTriggers++;
      } else if (trigger.updatedAt.isAfter(existing.updatedAt)) {
        triggersToWrite.add(trigger);
        updatedTriggers++;
      }
    }

    return _ImportPlan(
      routinesToWrite: routinesToWrite,
      stepsToWrite: stepsToWrite,
      triggersToWrite: triggersToWrite,
      preview: ImportPreview(
        newRoutines: newRoutines,
        updatedRoutines: updatedRoutines,
        newSteps: newSteps,
        updatedSteps: updatedSteps,
        newTriggers: newTriggers,
        updatedTriggers: updatedTriggers,
      ),
    );
  }

  Future<List<String>> _orderedStepIds(String routineId) async {
    final rows =
        await (_db.select(_db.routineSteps)
              ..where(
                (s) => s.routineId.equals(routineId) & s.deletedAt.isNull(),
              )
              ..orderBy([(s) => OrderingTerm.asc(s.order)]))
            .get();
    return rows.map((row) => row.id).toList();
  }

  Future<db.Routine?> _rawRoutineRow(String id) => (_db.select(
    _db.routines,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<db.RoutineStep?> _rawStepRow(String id) => (_db.select(
    _db.routineSteps,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<db.Trigger?> _rawTriggerRow(String id) => (_db.select(
    _db.triggers,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Routine _routineFromRow(db.Routine row, List<String> stepIds) {
    return Routine(
      id: row.id,
      name: row.name,
      triggerId: row.triggerId,
      schedule: Schedule(
        mode: row.scheduleMode,
        days: row.scheduleDays,
        startTime: row.scheduleStartTime,
      ),
      stepIds: stepIds,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  RoutineStep _stepFromRow(db.RoutineStep row) {
    return RoutineStep(
      id: row.id,
      routineId: row.routineId,
      name: row.name,
      emoji: row.emoji,
      durationSeconds: row.durationSeconds,
      order: row.order,
      noExplicitTime: row.noExplicitTime,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  Trigger _triggerFromRow(db.Trigger row) {
    return Trigger(
      id: row.id,
      name: row.name,
      kind: TriggerKind.values.byName(row.kind),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

class _ImportPlan {
  _ImportPlan({
    required this.routinesToWrite,
    required this.stepsToWrite,
    required this.triggersToWrite,
    required this.preview,
  });

  final List<Routine> routinesToWrite;
  final List<RoutineStep> stepsToWrite;
  final List<Trigger> triggersToWrite;
  final ImportPreview preview;
}
