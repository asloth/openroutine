/// Turns completion logs into the figures the statistics screen reports.
///
/// Deliberately pure: no Flutter, no storage, no providers. Every rule here is
/// arithmetic over records — which steps count, when a streak breaks, which
/// hour a run belongs to — and each one is a place a plausible-looking wrong
/// number could come from. Kept as a function of its inputs, each rule gets a
/// direct test, and the screen is left with nothing to get wrong but layout.
library;

import '../../models/completion_log.dart';
import '../../models/step.dart';

/// How one step's real duration compared with what it was estimated at.
class StepEstimate {
  const StepEstimate({
    required this.stepId,
    required this.name,
    required this.estimated,
    required this.actual,
  });

  final String stepId;
  final String name;
  final Duration estimated;
  final Duration actual;

  /// Positive when the step took longer than estimated.
  Duration get difference => actual - estimated;
}

/// Estimated against actual time, in total and per step.
///
/// Only ever constructed when at least one step recorded an estimate; the
/// absence of this object is how "nothing to compare" is expressed, rather
/// than a zeroed one that reads as perfect accuracy.
class EstimateAccuracy {
  const EstimateAccuracy({
    required this.estimated,
    required this.actual,
    required this.steps,
  });

  final Duration estimated;
  final Duration actual;

  /// Largest overrun first — the steps worth looking at are the ones where the
  /// estimate is furthest from the truth.
  final List<StepEstimate> steps;

  Duration get difference => actual - estimated;
}

class CompletionRate {
  const CompletionRate({
    required this.finished,
    required this.abandoned,
    required this.currentStreakDays,
  });

  final int finished;
  final int abandoned;

  /// Consecutive days, counting back from the most recent day with a finished
  /// run, on which at least one run was finished.
  final int currentStreakDays;

  int get total => finished + abandoned;

  /// Zero when nothing has been run, rather than undefined.
  double get rate => total == 0 ? 0 : finished / total;
}

class SkippedStep {
  const SkippedStep({
    required this.stepId,
    required this.name,
    required this.count,
  });

  final String stepId;
  final String name;
  final int count;
}

class HourBucket {
  const HourBucket({required this.hour, required this.runs});

  final int hour;
  final int runs;
}

class RoutineStatistics {
  const RoutineStatistics({
    required this.estimates,
    required this.completion,
    required this.skipped,
    required this.startTimes,
    required this.hasData,
  });

  /// Null when no step in any run recorded an estimate.
  final EstimateAccuracy? estimates;
  final CompletionRate completion;
  final List<SkippedStep> skipped;
  final List<HourBucket> startTimes;

  /// False when there are no completion logs at all. The screen shows what it
  /// will report once there is data rather than a page of zeros, because an
  /// empty chart reads as a score.
  final bool hasData;
}

/// Computes every reported figure from [logs].
///
/// [stepsById] resolves step identifiers to their current names; a step that
/// no longer exists is dropped rather than shown by identifier. [now] is
/// injected so streaks are testable without depending on the current date.
RoutineStatistics computeStatistics({
  required List<CompletionLog> logs,
  required Map<String, RoutineStep> stepsById,
  required DateTime now,
}) {
  if (logs.isEmpty) {
    return const RoutineStatistics(
      estimates: null,
      completion: CompletionRate(
        finished: 0,
        abandoned: 0,
        currentStreakDays: 0,
      ),
      skipped: [],
      startTimes: [],
      hasData: false,
    );
  }

  return RoutineStatistics(
    estimates: _estimates(logs, stepsById),
    completion: CompletionRate(
      finished: logs
          .where((l) => l.outcome == CompletionOutcome.completed)
          .length,
      abandoned: logs
          .where((l) => l.outcome == CompletionOutcome.abandoned)
          .length,
      currentStreakDays: _streak(logs, now),
    ),
    skipped: _skipped(logs, stepsById),
    startTimes: _startTimes(logs),
    hasData: true,
  );
}

EstimateAccuracy? _estimates(
  List<CompletionLog> logs,
  Map<String, RoutineStep> stepsById,
) {
  final estimated = <String, int>{};
  final actual = <String, int>{};

  for (final log in logs) {
    for (final step in log.steps) {
      final estimate = step.estimatedDurationSeconds;
      // An absent estimate is not an estimate of zero, so the step sits out of
      // the comparison entirely rather than counting as a perfect guess.
      if (estimate == null) continue;
      if (!stepsById.containsKey(step.stepId)) continue;
      estimated.update(
        step.stepId,
        (v) => v + estimate,
        ifAbsent: () => estimate,
      );
      actual.update(
        step.stepId,
        (v) => v + step.actualDurationSeconds,
        ifAbsent: () => step.actualDurationSeconds,
      );
    }
  }

  if (estimated.isEmpty) return null;

  final steps = [
    for (final id in estimated.keys)
      StepEstimate(
        stepId: id,
        name: stepsById[id]!.name,
        estimated: Duration(seconds: estimated[id]!),
        actual: Duration(seconds: actual[id]!),
      ),
  ]..sort((a, b) => b.difference.compareTo(a.difference));

  return EstimateAccuracy(
    estimated: Duration(
      seconds: estimated.values.fold(0, (a, b) => a + b),
    ),
    actual: Duration(seconds: actual.values.fold(0, (a, b) => a + b)),
    steps: steps,
  );
}

/// Consecutive days ending at the most recent finished run.
///
/// Counts finishing rather than attending: a day whose only run was abandoned
/// breaks the streak, because a number that keeps rising while things go badly
/// is worse than no number.
int _streak(List<CompletionLog> logs, DateTime now) {
  final finishedDays = <DateTime>{
    for (final log in logs)
      if (log.outcome == CompletionOutcome.completed) _dayOf(log.startedAt),
  };
  if (finishedDays.isEmpty) return 0;

  final today = _dayOf(now);
  var cursor = finishedDays.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  // Only today may be missing without breaking the streak — the day is not
  // over yet. Any earlier gap ends it.
  if (!finishedDays.contains(cursor)) return 0;

  var streak = 0;
  while (finishedDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

DateTime _dayOf(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<SkippedStep> _skipped(
  List<CompletionLog> logs,
  Map<String, RoutineStep> stepsById,
) {
  final counts = <String, int>{};
  for (final log in logs) {
    for (final step in log.steps) {
      if (step.state != CompletionStepState.skipped) continue;
      if (!stepsById.containsKey(step.stepId)) continue;
      counts.update(step.stepId, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  return [
    for (final entry in counts.entries)
      SkippedStep(
        stepId: entry.key,
        name: stepsById[entry.key]!.name,
        count: entry.value,
      ),
  ]..sort((a, b) => b.count.compareTo(a.count));
}

/// Runs grouped by the local hour they started in.
///
/// "When do I start my routine" is a question about the user's day, so this is
/// the one place the stored UTC value must not be reported directly.
List<HourBucket> _startTimes(List<CompletionLog> logs) {
  final counts = <int, int>{};
  for (final log in logs) {
    final hour = log.startedAt.toLocal().hour;
    counts.update(hour, (v) => v + 1, ifAbsent: () => 1);
  }

  return [
    for (final entry in counts.entries)
      HourBucket(hour: entry.key, runs: entry.value),
  ]..sort((a, b) => a.hour.compareTo(b.hour));
}
