import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/services/stats/routine_statistics.dart';

RoutineStep _step(String id, String name) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: name,
  emoji: '*',
  durationSeconds: 60,
  order: 0,
  noExplicitTime: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

CompletionLog _log({
  required String id,
  required DateTime startedAt,
  CompletionOutcome outcome = CompletionOutcome.completed,
  List<CompletionStep> steps = const [],
}) => CompletionLog(
  id: id,
  routineId: 'r1',
  startedAt: startedAt,
  endedAt: startedAt.add(const Duration(minutes: 10)),
  outcome: outcome,
  steps: steps,
);

CompletionStep _done(
  String stepId, {
  required int actual,
  int? estimated,
  CompletionStepState state = CompletionStepState.completed,
}) => CompletionStep(
  stepId: stepId,
  state: state,
  actualDurationSeconds: actual,
  estimatedDurationSeconds: estimated,
);

void main() {
  final steps = {'a': _step('a', 'Shower'), 'b': _step('b', 'Breakfast')};

  group('estimate accuracy', () {
    test('reports a step that ran over by the difference', () {
      final stats = computeStatistics(
        logs: [
          _log(
            id: 'c1',
            startedAt: DateTime.utc(2026, 9, 1, 7),
            steps: [_done('a', actual: 90, estimated: 60)],
          ),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      final accuracy = stats.estimates!;
      expect(accuracy.actual, const Duration(seconds: 90));
      expect(accuracy.estimated, const Duration(seconds: 60));
      expect(accuracy.steps.single.name, 'Shower');
      expect(accuracy.steps.single.difference, const Duration(seconds: 30));
    });

    test('excludes steps with no recorded estimate from the totals', () {
      final stats = computeStatistics(
        logs: [
          _log(
            id: 'c1',
            startedAt: DateTime.utc(2026, 9, 1, 7),
            steps: [
              _done('a', actual: 90, estimated: 60),
              // No estimate: an absent estimate is not an estimate of zero,
              // so this must not drag the totals.
              _done('b', actual: 300),
            ],
          ),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      final accuracy = stats.estimates!;
      expect(accuracy.actual, const Duration(seconds: 90));
      expect(accuracy.estimated, const Duration(seconds: 60));
      expect(accuracy.steps.map((s) => s.stepId), ['a']);
    });

    test('is absent entirely when no step recorded an estimate', () {
      final stats = computeStatistics(
        logs: [
          _log(
            id: 'c1',
            startedAt: DateTime.utc(2026, 9, 1, 7),
            steps: [_done('a', actual: 90)],
          ),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      expect(stats.estimates, isNull);
      expect(stats.hasData, isTrue);
    });
  });

  group('completion rate and streak', () {
    test('counts finished runs against abandoned ones', () {
      final stats = computeStatistics(
        logs: [
          _log(id: 'c1', startedAt: DateTime.utc(2026, 9, 1, 7)),
          _log(
            id: 'c2',
            startedAt: DateTime.utc(2026, 9, 1, 9),
            outcome: CompletionOutcome.abandoned,
          ),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      expect(stats.completion.finished, 1);
      expect(stats.completion.abandoned, 1);
      expect(stats.completion.rate, 0.5);
    });

    test('counts consecutive days that contain a finished run', () {
      final stats = computeStatistics(
        logs: [
          _log(id: 'c1', startedAt: DateTime.utc(2026, 9, 1, 7)),
          _log(id: 'c2', startedAt: DateTime.utc(2026, 9, 2, 7)),
          _log(id: 'c3', startedAt: DateTime.utc(2026, 9, 3, 7)),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 3, 12),
      );

      expect(stats.completion.currentStreakDays, 3);
    });

    test('a day whose only run was abandoned does not extend the streak', () {
      final stats = computeStatistics(
        logs: [
          _log(id: 'c1', startedAt: DateTime.utc(2026, 9, 1, 7)),
          _log(
            id: 'c2',
            startedAt: DateTime.utc(2026, 9, 2, 7),
            outcome: CompletionOutcome.abandoned,
          ),
          _log(id: 'c3', startedAt: DateTime.utc(2026, 9, 3, 7)),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 3, 12),
      );

      // The streak counts finishing, not attending, so it starts again at the
      // 3rd rather than reaching back past the abandoned 2nd.
      expect(stats.completion.currentStreakDays, 1);
    });

    test('a gap day ends the streak', () {
      final stats = computeStatistics(
        logs: [
          _log(id: 'c1', startedAt: DateTime.utc(2026, 9, 1, 7)),
          _log(id: 'c2', startedAt: DateTime.utc(2026, 9, 3, 7)),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 3, 12),
      );

      expect(stats.completion.currentStreakDays, 1);
    });
  });

  group('skipped steps', () {
    test('orders by how often each was skipped and names them', () {
      final stats = computeStatistics(
        logs: [
          _log(
            id: 'c1',
            startedAt: DateTime.utc(2026, 9, 1, 7),
            steps: [
              _done('a', actual: 0, state: CompletionStepState.skipped),
              _done('b', actual: 0, state: CompletionStepState.skipped),
            ],
          ),
          _log(
            id: 'c2',
            startedAt: DateTime.utc(2026, 9, 2, 7),
            steps: [_done('b', actual: 0, state: CompletionStepState.skipped)],
          ),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 2, 12),
      );

      expect(stats.skipped.first.name, 'Breakfast');
      expect(stats.skipped.first.count, 2);
      expect(stats.skipped.last.name, 'Shower');
    });

    test('omits a skipped step whose definition no longer exists', () {
      final stats = computeStatistics(
        logs: [
          _log(
            id: 'c1',
            startedAt: DateTime.utc(2026, 9, 1, 7),
            steps: [
              _done('gone', actual: 0, state: CompletionStepState.skipped),
              _done('a', actual: 0, state: CompletionStepState.skipped),
            ],
          ),
        ],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      // An identifier tells the user nothing, so a deleted step is dropped
      // rather than shown raw.
      expect(stats.skipped.map((s) => s.stepId), ['a']);
    });
  });

  group('start times', () {
    test('buckets by local hour, not the stored UTC hour', () {
      // 06:30 UTC. In any timezone that is not UTC this must not land in
      // bucket 6 — the bug is invisible at offset zero.
      final started = DateTime.utc(2026, 9, 1, 6, 30);
      final stats = computeStatistics(
        logs: [_log(id: 'c1', startedAt: started)],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      expect(stats.startTimes.single.hour, started.toLocal().hour);
      expect(stats.startTimes.single.runs, 1);
    });
  });

  group('no data', () {
    test('reports having nothing rather than zeroed figures', () {
      final stats = computeStatistics(
        logs: const [],
        stepsById: steps,
        now: DateTime.utc(2026, 9, 1, 12),
      );

      expect(stats.hasData, isFalse);
      expect(stats.estimates, isNull);
      expect(stats.skipped, isEmpty);
      expect(stats.startTimes, isEmpty);
    });
  });
}
