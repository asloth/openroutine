import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/export_bundle.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/models/trigger.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';

ExportBundle _bundleWithRoutine(Routine routine) {
  return ExportBundle(
    schemaVersion: '1.0.0',
    exportedAt: DateTime.utc(2026, 1, 1),
    routines: [routine],
    steps: const [],
    triggers: const [],
  );
}

Routine _routine({
  String id = 'r1',
  String name = 'Morning',
  List<String> stepIds = const [],
  DateTime? updatedAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Routine(
    id: id,
    name: name,
    triggerId: null,
    schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
    stepIds: stepIds,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    deletedAt: null,
  );
}

RoutineStep _step({
  String id = 's1',
  String routineId = 'r1',
  int order = 0,
  DateTime? updatedAt,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return RoutineStep(
    id: id,
    routineId: routineId,
    name: 'Brush teeth',
    emoji: '🪥',
    durationSeconds: 180,
    order: order,
    noExplicitTime: false,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    deletedAt: null,
  );
}

void main() {
  // The schema-conformance group below reads the bundled schema assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalAdapter adapter;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    adapter = LocalAdapter(db);
  });

  tearDown(() => db.close());

  group('CRUD round-trips', () {
    test('saveRoutine then getRoutine returns the same routine', () async {
      await adapter.saveRoutine(_routine());
      final result = await adapter.getRoutine('r1');
      expect(result?.name, 'Morning');
      expect(result?.schedule.mode, ScheduleMode.flexible);
    });

    test(
      'getRoutine derives stepIds from RoutineSteps ordered by order, not a stored column',
      () async {
        await adapter.saveRoutine(_routine());
        await adapter.saveStep(_step(id: 's2', order: 1));
        await adapter.saveStep(_step(id: 's1', order: 0));

        final result = await adapter.getRoutine('r1');
        expect(result?.stepIds, ['s1', 's2']);
      },
    );

    test('saveTrigger then getTriggers round-trips', () async {
      final trigger = Trigger(
        id: 't1',
        name: 'Waking up',
        kind: TriggerKind.manual,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      await adapter.saveTrigger(trigger);
      final triggers = await adapter.getTriggers();
      expect(triggers, hasLength(1));
      expect(triggers.single.name, 'Waking up');
    });
  });

  group('completion logs', () {
    CompletionLog completion({
      String id = 'c1',
      DateTime? startedAt,
      CompletionOutcome outcome = CompletionOutcome.completed,
      List<CompletionStep> steps = const [
        CompletionStep(
          stepId: 's1',
          state: CompletionStepState.completed,
          actualDurationSeconds: 42,
        ),
      ],
    }) {
      final started = startedAt ?? DateTime.utc(2026, 8, 2, 9);
      return CompletionLog(
        id: id,
        routineId: 'r1',
        startedAt: started,
        endedAt: started.add(const Duration(minutes: 10)),
        outcome: outcome,
        steps: steps,
      );
    }

    setUp(() => adapter.saveRoutine(_routine()));

    test('a completion round-trips including its nested steps', () async {
      final log = completion(
        steps: const [
          CompletionStep(
            stepId: 's1',
            state: CompletionStepState.overrun,
            actualDurationSeconds: 91,
          ),
          CompletionStep(
            stepId: 's2',
            state: CompletionStepState.skipped,
            actualDurationSeconds: 3,
          ),
        ],
      );
      await adapter.appendCompletion(log);

      expect(await adapter.getCompletions('r1'), [log]);
    });

    test('completions come back newest first', () async {
      await adapter.appendCompletion(
        completion(id: 'older', startedAt: DateTime.utc(2026, 8, 1)),
      );
      await adapter.appendCompletion(
        completion(id: 'newer', startedAt: DateTime.utc(2026, 8, 3)),
      );

      final logs = await adapter.getCompletions('r1');
      expect(logs.map((l) => l.id), ['newer', 'older']);
    });

    test('since filters out older runs, inclusive of the boundary', () async {
      final boundary = DateTime.utc(2026, 8, 2);
      await adapter.appendCompletion(
        completion(id: 'before', startedAt: DateTime.utc(2026, 8, 1)),
      );
      await adapter.appendCompletion(
        completion(id: 'on', startedAt: boundary),
      );
      await adapter.appendCompletion(
        completion(id: 'after', startedAt: DateTime.utc(2026, 8, 3)),
      );

      final logs = await adapter.getCompletions('r1', since: boundary);
      expect(logs.map((l) => l.id), ['after', 'on']);
    });

    test('another routine\'s completions are not returned', () async {
      await adapter.saveRoutine(_routine(id: 'r2'));
      await adapter.appendCompletion(completion());

      expect(await adapter.getCompletions('r2'), isEmpty);
    });

    test('an abandoned run keeps its outcome', () async {
      await adapter.appendCompletion(
        completion(outcome: CompletionOutcome.abandoned),
      );

      final logs = await adapter.getCompletions('r1');
      expect(logs.single.outcome, CompletionOutcome.abandoned);
    });

    test('re-appending the same id throws rather than overwriting', () async {
      await adapter.appendCompletion(completion());

      // The log is append-only (docs/SPEC.md §4); a duplicate id is a bug, and
      // silently absorbing it would corrupt the history.
      expect(
        () => adapter.appendCompletion(completion()),
        throwsA(anything),
      );
    });
  });

  group('soft delete', () {
    test(
      'deleteRoutine hides it from getRoutine/watchRoutines but does not remove the row',
      () async {
        await adapter.saveRoutine(_routine());
        await adapter.deleteRoutine('r1');

        expect(await adapter.getRoutine('r1'), isNull);
        expect(await adapter.watchRoutines().first, isEmpty);
      },
    );

    test(
      'deleteStep removes it from getSteps and from the parent routine\'s stepIds',
      () async {
        await adapter.saveRoutine(_routine());
        await adapter.saveStep(_step());
        await adapter.deleteStep('s1');

        expect(await adapter.getSteps('r1'), isEmpty);
        expect((await adapter.getRoutine('r1'))?.stepIds, isEmpty);
      },
    );
  });

  group('import last-writer-wins', () {
    test(
      'previewImport and confirmImport agree: new routine counted and written',
      () async {
        final bundle = _bundleWithRoutine(_routine(id: 'new-r'));

        final preview = await adapter.previewImport(bundle);
        expect(preview.newRoutines, 1);
        expect(preview.updatedRoutines, 0);

        await adapter.confirmImport(bundle);
        expect(await adapter.getRoutine('new-r'), isNotNull);
      },
    );

    test(
      'an older incoming updatedAt loses to a newer local one and is not written',
      () async {
        await adapter.saveRoutine(
          _routine(name: 'Local newer', updatedAt: DateTime.utc(2026, 6, 1)),
        );

        final bundle = _bundleWithRoutine(
          _routine(name: 'Import older', updatedAt: DateTime.utc(2026, 1, 1)),
        );

        final preview = await adapter.previewImport(bundle);
        expect(preview.newRoutines, 0);
        expect(preview.updatedRoutines, 0);

        await adapter.confirmImport(bundle);
        expect((await adapter.getRoutine('r1'))?.name, 'Local newer');
      },
    );

    test('a newer incoming updatedAt wins over an older local one', () async {
      await adapter.saveRoutine(
        _routine(name: 'Local older', updatedAt: DateTime.utc(2026, 1, 1)),
      );

      final bundle = _bundleWithRoutine(
        _routine(name: 'Import newer', updatedAt: DateTime.utc(2026, 6, 1)),
      );

      await adapter.confirmImport(bundle);
      expect((await adapter.getRoutine('r1'))?.name, 'Import newer');
    });

    test(
      'import cannot resurrect a locally soft-deleted routine with an older timestamp',
      () async {
        await adapter.saveRoutine(
          _routine(updatedAt: DateTime.utc(2026, 6, 1)),
        );
        await adapter.deleteRoutine(
          'r1',
        ); // updatedAt bumps to "now" (>> 2026-06-01)

        final bundle = _bundleWithRoutine(
          _routine(updatedAt: DateTime.utc(2026, 6, 2)),
        );

        await adapter.confirmImport(bundle);
        expect(await adapter.getRoutine('r1'), isNull);
      },
    );
  });

  // What the adapter exports is a public contract: the same bytes go to the
  // share sheet, to Drive, and to anyone who opens the folder. A regression
  // here is invisible locally and only bites when someone tries to read the
  // file back — so it is asserted against the published schemas, not against
  // our own parser.
  //
  // Regression: flexible routines serialise `start_time: null`, and the
  // schema originally allowed only a string there. Exporting a flexible
  // routine therefore produced a file the app itself refused to import. Every
  // routine on a test device happened to be scheduled, so nothing caught it
  // until Drive started validating what it uploaded.
  group('exports honour the published schemas', () {
    const uuid = '019fc553-a96e-7cb7-84e8-93de8598e290';

    Future<void> expectExportValidates() async {
      final validator = await SchemaValidator.load();
      final json =
          jsonDecode(jsonEncode((await adapter.exportAll()).toJson()))
              as Map<String, dynamic>;
      validator.validateExportBundle(json);
    }

    test('a flexible routine, which has no start time', () async {
      await adapter.saveRoutine(_routine(id: uuid));
      await expectExportValidates();
    });

    test('a scheduled routine with days and a start time', () async {
      await adapter.saveRoutine(
        Routine(
          id: uuid,
          name: 'morning',
          triggerId: null,
          schedule: const Schedule(
            mode: ScheduleMode.scheduled,
            days: [DayOfWeek.mon, DayOfWeek.tue],
            startTime: '07:20',
          ),
          stepIds: const [],
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
          deletedAt: null,
        ),
      );
      await expectExportValidates();
    });
  });
}
