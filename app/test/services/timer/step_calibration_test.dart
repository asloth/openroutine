import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/services/timer/step_calibration.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/drive/drive_adapter.dart';
import 'package:openroutine/services/storage/drive/sync_queue.dart';
import 'package:openroutine/services/storage/local_adapter.dart';

final _createdAt = DateTime.utc(2026, 8, 12, 9);

RoutineStep _step({int durationSeconds = 300, DateTime? updatedAt}) =>
    RoutineStep(
      id: 's1',
      routineId: 'r1',
      name: 'Brush teeth',
      emoji: '🪥',
      durationSeconds: durationSeconds,
      order: 2,
      noExplicitTime: false,
      createdAt: _createdAt,
      updatedAt: updatedAt ?? _createdAt,
    );

void main() {
  group('StepCalibration', () {
    test(
      'suggests a rounded minute only for a materially different completion',
      () {
        final suggestion = StepCalibration.suggest(
          CompletionStep(
            stepId: 's1',
            state: CompletionStepState.completed,
            actualDurationSeconds: 451,
            estimatedDurationSeconds: 300,
          ),
          _step(),
        );

        expect(suggestion?.suggestedDurationSeconds, 480);
        expect(suggestion?.sourceUpdatedAt, _createdAt);
        expect(suggestion?.stepId, 's1');
      },
    );

    test('keeps a zero-second eligible suggestion at one minute', () {
      final suggestion = StepCalibration.suggest(
        const CompletionStep(
          stepId: 's1',
          state: CompletionStepState.completed,
          actualDurationSeconds: 0,
          estimatedDurationSeconds: 60,
        ),
        _step(durationSeconds: 60),
      );

      expect(suggestion?.suggestedDurationSeconds, 60);
    });

    test('rejects skipped, untimed, legacy, and immaterial completions', () {
      final current = _step();
      expect(
        StepCalibration.suggest(
          const CompletionStep(
            stepId: 's1',
            state: CompletionStepState.skipped,
            actualDurationSeconds: 600,
            estimatedDurationSeconds: 300,
          ),
          current,
        ),
        isNull,
      );
      expect(
        StepCalibration.suggest(
          const CompletionStep(
            stepId: 's1',
            state: CompletionStepState.completed,
            actualDurationSeconds: 330,
            estimatedDurationSeconds: 300,
          ),
          current,
        ),
        isNull,
      );
      expect(
        StepCalibration.suggest(
          const CompletionStep(
            stepId: 's1',
            state: CompletionStepState.completed,
            actualDurationSeconds: 600,
          ),
          current,
        ),
        isNull,
      );
    });

    test(
      'approval preserves latest fields but refuses changed source evidence',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final adapter = LocalAdapter(db);
        final original = _step();
        await adapter.saveStep(original);
        final persisted = (await adapter.getSteps('r1')).single;
        final suggestion = StepCalibration.suggest(
          const CompletionStep(
            stepId: 's1',
            state: CompletionStepState.completed,
            actualDurationSeconds: 451,
            estimatedDurationSeconds: 300,
          ),
          persisted,
        )!;

        expect(
          await suggestion.approve(
            adapter,
            updatedAt: _createdAt.add(const Duration(minutes: 1)),
          ),
          CalibrationApproval.applied,
        );
        final saved = (await adapter.getSteps('r1')).single;
        expect(saved.durationSeconds, 480);
        expect(saved.order, 2);
        expect(saved.name, 'Brush teeth');

        await adapter.saveStep(saved.copyWith(durationSeconds: 600));
        expect(
          await suggestion.approve(
            adapter,
            updatedAt: _createdAt.add(const Duration(minutes: 2)),
          ),
          CalibrationApproval.stale,
        );
        expect((await adapter.getSteps('r1')).single.durationSeconds, 600);
      },
    );

    test(
      'valid Drive approval marks routines dirty and notifies once',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final local = LocalAdapter(db);
        final queue = SyncQueue(db);
        var callbacks = 0;
        final adapter = DriveAdapter(
          local: local,
          queue: queue,
          onLocalChange: () => callbacks++,
        );
        final original = _step();
        await local.saveStep(original);
        final suggestion = StepCalibration.suggest(
          const CompletionStep(
            stepId: 's1',
            state: CompletionStepState.completed,
            actualDurationSeconds: 451,
            estimatedDurationSeconds: 300,
          ),
          (await local.getSteps('r1')).single,
        )!;

        expect(
          await suggestion.approve(
            adapter,
            updatedAt: _createdAt.add(const Duration(minutes: 1)),
          ),
          CalibrationApproval.applied,
        );
        expect(await queue.routinesDirty, isTrue);
        expect(callbacks, 1);
      },
    );
  });
}
