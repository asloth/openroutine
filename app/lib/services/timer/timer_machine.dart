import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/completion_log.dart';
import '../../models/step.dart';

part 'timer_machine.freezed.dart';

/// docs/SPEC.md §8. `idle` only exists before [TimerState.start]; once a run
/// reaches `complete` it is terminal, whether it finished or was abandoned.
enum TimerPhase { idle, running, paused, complete }

/// Timer Mode's state machine (docs/SPEC.md §8), as a pure immutable value.
///
/// Deliberately free of Flutter, Riverpod and drift imports: every transition
/// is a method taking `now` and returning a new state, so the whole event
/// matrix is testable with a fake clock and no widget tree. The Riverpod
/// notifier in state/timer_provider.dart owns the ticker and the side effects;
/// this class owns the rules.
///
/// **Elapsed time is always derived from wall-clock timestamps, never
/// accumulated from ticks.** The 1-second ticker exists only to repaint. That
/// is what lets a run survive backgrounding, doze and process death: on resume
/// we recompute from [stepStartedAt] and get the true elapsed time, where a
/// tick counter would have silently frozen while the process was suspended.
///
/// A timed step does not auto-advance when it hits zero — it keeps counting
/// into overrun until the user acts. That is why `overrun` exists as a
/// [CompletionStepState] at all; auto-advancing would make it unreachable.
@freezed
abstract class TimerState with _$TimerState {
  const factory TimerState({
    required TimerPhase phase,
    required String routineId,
    required List<RoutineStep> steps,
    required int currentIndex,
    required Duration pausedAccumulated,
    required List<CompletionStep> outcomes,
    DateTime? startedAt,
    DateTime? stepStartedAt,
    DateTime? pausedAt,
    DateTime? endedAt,
    CompletionOutcome? outcome,
  }) = _TimerState;

  const TimerState._();

  factory TimerState.idle({
    required String routineId,
    required List<RoutineStep> steps,
  }) => TimerState(
    phase: TimerPhase.idle,
    routineId: routineId,
    steps: steps,
    currentIndex: 0,
    pausedAccumulated: Duration.zero,
    outcomes: const [],
  );

  RoutineStep? get currentStep =>
      currentIndex >= 0 && currentIndex < steps.length
      ? steps[currentIndex]
      : null;

  bool get isLastStep => currentIndex >= steps.length - 1;
  bool get isFirstStep => currentIndex <= 0;
  bool get isActive =>
      phase == TimerPhase.running || phase == TimerPhase.paused;

  /// Time spent on the current step, excluding any time spent paused. While
  /// paused the clock is read at [pausedAt] rather than `now`, so the display
  /// holds still.
  Duration elapsed(DateTime now) {
    final startedAt = stepStartedAt;
    if (startedAt == null) return Duration.zero;
    final readAt = pausedAt ?? now;
    final raw = readAt.difference(startedAt) - pausedAccumulated;
    return raw.isNegative ? Duration.zero : raw;
  }

  /// Time left on the current step, or null when the step has no target —
  /// either because it is `noExplicitTime` or because there is no current
  /// step. Goes negative once the step overruns; callers decide how to show
  /// that.
  Duration? remaining(DateTime now) {
    final step = currentStep;
    if (step == null || step.noExplicitTime) return null;
    final target = Duration(seconds: step.durationSeconds ?? 0);
    return target - elapsed(now);
  }

  /// When the current step's timer should fire, or null if it has no target.
  /// Used to schedule the expiry notification.
  DateTime? currentStepEndsAt(DateTime now) {
    final left = remaining(now);
    if (left == null || phase != TimerPhase.running) return null;
    return now.add(left);
  }

  TimerState start(DateTime now) {
    if (phase != TimerPhase.idle) return this;
    if (steps.isEmpty) {
      // Nothing to run. Land in the terminal phase rather than a running state
      // with no current step; the UI keeps Start Timer disabled anyway.
      return copyWith(
        phase: TimerPhase.complete,
        startedAt: now,
        endedAt: now,
        outcome: CompletionOutcome.completed,
      );
    }
    return copyWith(
      phase: TimerPhase.running,
      startedAt: now,
      stepStartedAt: now,
      pausedAccumulated: Duration.zero,
      currentIndex: 0,
    );
  }

  TimerState pause(DateTime now) {
    if (phase != TimerPhase.running) return this;
    return copyWith(phase: TimerPhase.paused, pausedAt: now);
  }

  TimerState resume(DateTime now) {
    if (phase != TimerPhase.paused) return this;
    final pausedSince = pausedAt;
    return copyWith(
      phase: TimerPhase.running,
      pausedAccumulated:
          pausedAccumulated +
          (pausedSince == null ? Duration.zero : now.difference(pausedSince)),
      pausedAt: null,
    );
  }

  /// Finish the current step, recording it as `completed` — or `overrun` if it
  /// ran past its target.
  TimerState completeStep(DateTime now) => _advance(now, skipped: false);

  /// Finish the current step, recording it as `skipped`. The elapsed time is
  /// still recorded: skipping after two minutes is different from skipping
  /// immediately, and agents analysing the log can tell them apart.
  TimerState skip(DateTime now) => _advance(now, skipped: true);

  /// Step back to the previous step and re-run it, dropping the outcome
  /// already recorded for it so the retry is what ends up in the log.
  TimerState back(DateTime now) {
    if (!isActive || isFirstStep) return this;
    final trimmed = outcomes.isEmpty
        ? outcomes
        : outcomes.sublist(0, outcomes.length - 1);
    return copyWith(
      currentIndex: currentIndex - 1,
      outcomes: trimmed,
    )._restartStepClock(now);
  }

  /// Restart the current step's clock without changing position.
  TimerState resetStep(DateTime now) {
    if (!isActive) return this;
    return _restartStepClock(now);
  }

  /// End the run early. The in-progress step is deliberately not recorded:
  /// schemas/completion.schema.json only admits completed/skipped/overrun, and
  /// a step the user walked away from is none of those.
  TimerState abandon(DateTime now) {
    if (phase == TimerPhase.complete) return this;
    return copyWith(
      phase: TimerPhase.complete,
      pausedAt: null,
      endedAt: now,
      outcome: CompletionOutcome.abandoned,
    );
  }

  /// The record to persist once [phase] is `complete`; null before then.
  CompletionLog? toLog(String id) {
    final started = startedAt;
    final ended = endedAt;
    if (phase != TimerPhase.complete ||
        started == null ||
        ended == null ||
        outcome == null) {
      return null;
    }
    return CompletionLog(
      id: id,
      routineId: routineId,
      startedAt: started.toUtc(),
      endedAt: ended.toUtc(),
      outcome: outcome!,
      steps: outcomes,
    );
  }

  TimerState _advance(DateTime now, {required bool skipped}) {
    final step = currentStep;
    if (!isActive || step == null) return this;

    final spent = elapsed(now);
    final recorded = CompletionStep(
      stepId: step.id,
      state: skipped
          ? CompletionStepState.skipped
          : _finishedState(step, spent),
      actualDurationSeconds: spent.inSeconds,
    );
    final nextOutcomes = [...outcomes, recorded];

    if (isLastStep) {
      return copyWith(
        phase: TimerPhase.complete,
        outcomes: nextOutcomes,
        pausedAt: null,
        endedAt: now,
        outcome: CompletionOutcome.completed,
      );
    }
    return copyWith(
      currentIndex: currentIndex + 1,
      outcomes: nextOutcomes,
    )._restartStepClock(now);
  }

  /// A step with no target can never overrun — there is nothing to exceed.
  CompletionStepState _finishedState(RoutineStep step, Duration spent) {
    if (step.noExplicitTime) return CompletionStepState.completed;
    final target = Duration(seconds: step.durationSeconds ?? 0);
    return spent > target
        ? CompletionStepState.overrun
        : CompletionStepState.completed;
  }

  /// Point the clock at a fresh step. Navigating between steps preserves
  /// whether the run is paused: someone who paused on purpose and then tapped
  /// back should not find the next step already counting down.
  TimerState _restartStepClock(DateTime now) {
    return copyWith(
      stepStartedAt: now,
      pausedAccumulated: Duration.zero,
      pausedAt: phase == TimerPhase.paused ? now : null,
    );
  }
}
