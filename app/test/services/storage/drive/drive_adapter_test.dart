import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/services/storage/drive/drive_adapter.dart';
import 'package:openroutine/services/storage/drive/sync_queue.dart';
import 'package:openroutine/services/storage/local_adapter.dart';

final _createdAt = DateTime.utc(2026, 8, 1);

Routine _routine() => Routine(
  id: 'r1',
  name: 'Morning',
  triggerId: null,
  schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
  stepIds: const [],
  createdAt: _createdAt,
  updatedAt: _createdAt,
);

RoutineStep _step(String id, int order, {DateTime? deletedAt}) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: 'Step $id',
  emoji: '•',
  durationSeconds: 60,
  order: order,
  noExplicitTime: false,
  createdAt: _createdAt,
  updatedAt: _createdAt,
  deletedAt: deletedAt,
);

void main() {
  test('reorder marks routines dirty and notifies exactly once', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final local = LocalAdapter(db);
    final queue = SyncQueue(db);
    var localChanges = 0;
    final adapter = DriveAdapter(
      local: local,
      queue: queue,
      onLocalChange: () => localChanges++,
    );
    await local.saveRoutine(_routine());
    await local.saveStep(_step('s1', 0));
    await local.saveStep(_step('s2', 1));
    await local.saveStep(
      _step('deleted', 2, deletedAt: DateTime.utc(2026, 8, 2)),
    );
    final reorderedAt = DateTime.utc(2026, 8, 11);

    await adapter.reorderSteps('r1', ['s2', 's1'], updatedAt: reorderedAt);

    expect(queue.routinesGeneration, 1);
    expect(await queue.routinesDirty, isTrue);
    expect(localChanges, 1);

    final exported = await local.exportForSync();
    final activeSteps =
        exported.steps.where((step) => step.deletedAt == null).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    expect(activeSteps.map((step) => step.id), ['s2', 's1']);
    expect(activeSteps.map((step) => step.order), [0, 1]);
    expect(
      activeSteps.map((step) => step.updatedAt.toUtc()),
      everyElement(reorderedAt),
    );
    expect(exported.routines.single.updatedAt.toUtc(), reorderedAt);

    final tombstone = exported.steps.singleWhere(
      (step) => step.id == 'deleted',
    );
    expect(tombstone.order, 2);
    expect(tombstone.updatedAt.toUtc(), _createdAt);
    expect(tombstone.deletedAt?.toUtc(), DateTime.utc(2026, 8, 2));
    expect(tombstone.name, 'Step deleted');
  });
  test('completionsInRange reads through to the local adapter', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final local = LocalAdapter(db);
    final adapter = DriveAdapter(
      local: local,
      queue: SyncQueue(db),
      onLocalChange: () {},
    );
    await local.saveRoutine(_routine());
    await local.appendCompletion(
      CompletionLog(
        id: 'c1',
        routineId: 'r1',
        startedAt: DateTime.utc(2026, 9, 1, 7),
        endedAt: DateTime.utc(2026, 9, 1, 7, 20),
        outcome: CompletionOutcome.completed,
        steps: const [],
      ),
    );

    final from = DateTime.utc(2026, 8, 1);
    final to = DateTime.utc(2026, 10, 1);

    // The Drive adapter delegates reads to local; statistics must see the same
    // records whichever adapter is configured.
    expect(
      (await adapter.completionsInRange(from, to)).map((c) => c.id),
      (await local.completionsInRange(from, to)).map((c) => c.id),
    );
    expect((await adapter.completionsInRange(from, to)).single.id, 'c1');
  });

}
