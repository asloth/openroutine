import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/completion_log.dart';
import '../../models/step.dart';
import '../../services/timer/timer_machine.dart';
import '../../services/timer/step_calibration.dart';
import '../../state/routines_provider.dart';
import '../../state/storage_provider.dart';
import '../../state/timer_provider.dart';
import '../../theme/typography.dart';
import '../../widgets/mascot_slot.dart';
import '../../widgets/tinted/tinted.dart';
import 'run/run_parts.dart';

export 'run/run_parts.dart'
    show StepProgressBar, HalfwayBanner, minutesLeftInRun, halfwayMinutesLeft;

/// docs/SPEC.md §7 screen 7 — the full-screen playlist runner.
///
/// The screen reads the clock on every build rather than holding a countdown
/// of its own; the notifier's 1-second ticker just triggers those builds. That
/// keeps the display honest after the app has been backgrounded, where a
/// locally decremented counter would come back stale.
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({
    super.key,
    required this.routineId,
    this.mode = RunMode.full,
    this.plannedStepIds,
  });

  final String routineId;
  final RunMode mode;
  final List<String>? plannedStepIds;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  bool _started = false;

  /// The latest thing the mascot should react to. Kept here rather than in
  /// the running view, which rebuilds every second and would otherwise lose it.
  MascotCue? _cue;

  /// Reads what just happened off the change in timer state: a new outcome is
  /// a step done or skipped, and a newly put-off step is a wave. The last
  /// step's outcome ends the run, and the finished screen celebrates instead.
  void _react(TimerState? previous, TimerState next) {
    if (previous == null || next.phase == TimerPhase.complete) return;
    MascotReaction? reaction;
    if (next.outcomes.length > previous.outcomes.length) {
      reaction = next.outcomes.last.state == CompletionStepState.skipped
          ? MascotReaction.skip
          : MascotReaction.stepDone;
    } else if (next.postponedIds.length > previous.postponedIds.length) {
      reaction = MascotReaction.wave;
    }
    if (reaction != null) setState(() => _cue = MascotCue(reaction!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepsAsync = ref.watch(routineStepsProvider(widget.routineId));
    final timer = ref.watch(routineTimerProvider(widget.routineId));
    ref.listen(routineTimerProvider(widget.routineId), _react);

    // Feed the steps in and auto-start once they've loaded: arriving here is
    // itself the user's "start" gesture, so a second tap would be ceremony.
    final steps = stepsAsync.value;
    if (steps != null && !_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(
          routineTimerProvider(widget.routineId).notifier,
        );
        notifier.load(
          steps,
          mode: widget.mode,
          plannedStepIds: widget.plannedStepIds,
        );
        notifier.start(
          notificationBody: l10n.timerNotificationBody,
          notificationChannelName: l10n.timerNotificationChannelName,
          notificationChannelDescription:
              l10n.timerNotificationChannelDescription,
          nudgeHalfwayBody: l10n.timerNotificationNudgeHalfwayBody,
          nudgeNearEndBody: l10n.timerNotificationNudgeNearEndBody,
          nudgeChannelName: l10n.timerNotificationNudgeChannelName,
          nudgeChannelDescription:
              l10n.timerNotificationNudgeChannelDescription,
        );
      });
    }

    return PopScope(
      // Leaving mid-run is abandoning it, and that needs confirming; the
      // terminal screen is free to pop.
      canPop: !timer.isActive,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmAbandon(context, l10n) && mounted) {
          ref.read(routineTimerProvider(widget.routineId).notifier).abandon();
        }
      },
      child: Scaffold(
        body: DecoratedBox(
          // A wash of the palette at the top that fades into the paper, the
          // design's calm "working with you" ground.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.42],
              colors: [
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.55),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: stepsAsync.hasError
                ? Center(child: Text(l10n.commonLoadError))
                : switch (timer.phase) {
                    TimerPhase.idle => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    TimerPhase.complete => _Summary(state: timer),
                    _ => _Running(
                      state: timer,
                      routineId: widget.routineId,
                      cue: _cue,
                    ),
                  },
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmAbandon(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerAbandonConfirmTitle),
        content: Text(l10n.timerAbandonConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.timerAbandonConfirmAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Running extends ConsumerWidget {
  const _Running({
    required this.state,
    required this.routineId,
    required this.cue,
  });

  final TimerState state;
  final String routineId;
  final MascotCue? cue;

  static const _stepNameStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(routineTimerProvider(routineId).notifier);
    final state = this.state;
    final step = state.currentStep;
    if (step == null) return const SizedBox.shrink();

    final routineName =
        ref
            .watch(routinesProvider)
            .value
            ?.where((routine) => routine.id == routineId)
            .firstOrNull
            ?.name ??
        '';
    final now = DateTime.now();
    final elapsed = state.elapsed(now);
    final paused = state.phase == TimerPhase.paused;
    final halfway = halfwayMinutesLeft(step, elapsed) != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Row(
          children: [
            SoftCircleButton(
              icon: Icons.chevron_left,
              tooltip: l10n.timerAbandonConfirmAction,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                routineName,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: l10n.timerStepCounter(
                state.currentIndex + 1,
                state.steps.length,
              ),
              excludeSemantics: true,
              child: Text(
                l10n.timerStepOfTotal(
                  state.currentIndex + 1,
                  state.steps.length,
                ),
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SoftCircleButton(
              icon: paused ? Icons.play_arrow : Icons.pause,
              tooltip: paused ? l10n.timerResume : l10n.timerPause,
              onPressed: paused ? notifier.resume : notifier.pause,
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Resting rather than thinking: stillness while a step runs is what
        // makes the pet feel like it's working alongside you. Big enough to
        // be company, not an icon. It reacts once to Done, Skip, and Do it
        // last, and dozes while the run is paused.
        Center(
          child: MascotSlot(
            size: 168,
            mood: paused ? MascotMood.resting : MascotMood.idle,
            cue: cue,
          ),
        ),
        const SizedBox(height: 28),
        KeyedSubtree(
          key: const Key('currentStep'),
          child: Text(
            step.name,
            textAlign: TextAlign.center,
            style: _stepNameStyle.copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: 14),
        TimerClock(
          step: step,
          elapsed: elapsed,
          estimateZone: state.estimateZone(now),
          paused: paused,
        ),
        if (halfway) ...[
          const SizedBox(height: 16),
          HalfwayBanner(step: step, elapsed: elapsed),
        ],
        const SizedBox(height: 20),
        RunButton(
          label: state.isLastStep ? l10n.timerFinish : l10n.timerDone,
          onPressed: notifier.completeStep,
          primary: true,
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            // Hidden rather than disabled on the last step and on a step
            // already put off once: a permanently greyed control is noise.
            if (state.canPostpone) ...[
              Expanded(
                child: RunButton(
                  label: l10n.timerDoLater,
                  onPressed: notifier.postpone,
                ),
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: RunButton(
                label: l10n.timerSkip,
                onPressed: notifier.skip,
                muted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        RestOfRun(state: state, elapsed: elapsed),
      ],
    );
  }
}

/// The count-up clock, and for a step with a set time, a bar filling toward
/// its estimate. At and past the estimate both turn the tertiary colour; there
/// is deliberately no overtime text.
class TimerClock extends StatelessWidget {
  const TimerClock({
    super.key,
    required this.step,
    required this.elapsed,
    required this.estimateZone,
    required this.paused,
  });

  final RoutineStep step;
  final Duration elapsed;
  final EstimateZone estimateZone;
  final bool paused;

  static const _clockStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 60,
    height: 1,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final boundaryColor = estimateZone == EstimateZone.yellow
        ? theme.colorScheme.tertiary
        : null;
    final label = Text(
      step.noExplicitTime ? _format(elapsed) : _formatTimedElapsed(elapsed),
      textAlign: TextAlign.center,
      style: _clockStyle.copyWith(
        color:
            boundaryColor ??
            (paused ? theme.disabledColor : theme.colorScheme.onSurface),
      ),
    );

    if (step.noExplicitTime) {
      return Column(
        children: [
          label,
          const SizedBox(height: 6),
          Text(l10n.timerNoSetTime, style: theme.textTheme.bodySmall),
        ],
      );
    }

    final target = Duration(seconds: step.durationSeconds ?? 0);
    final progress = target.inMilliseconds == 0
        ? 1.0
        : (elapsed.inMilliseconds / target.inMilliseconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label,
        const SizedBox(height: 22),
        StepProgressBar(
          value: progress,
          color: boundaryColor ?? theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _Summary extends ConsumerStatefulWidget {
  const _Summary({required this.state});

  final TimerState state;

  @override
  ConsumerState<_Summary> createState() => _SummaryState();
}

class _SummaryState extends ConsumerState<_Summary> {
  late final List<StepCalibration> _suggestions;
  CalibrationApproval? _approval;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    final steps = {for (final step in widget.state.steps) step.id: step};
    _suggestions = widget.state.outcomes
        .map((outcome) {
          final step = steps[outcome.stepId];
          return step == null ? null : StepCalibration.suggest(outcome, step);
        })
        .whereType<StepCalibration>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = widget.state;
    final completed = state.outcomes
        .where((o) => o.state != CompletionStepState.skipped)
        .length;
    final skipped = state.outcomes
        .where((o) => o.state == CompletionStepState.skipped)
        .length;
    final total = state.steps.length;
    final abandoned = state.outcome == CompletionOutcome.abandoned;
    final ran = state.startedAt != null && state.endedAt != null
        ? state.endedAt!.difference(state.startedAt!)
        : Duration.zero;

    final suggestion = abandoned ? null : _suggestions.firstOrNull;
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 56, 22, 24),
      children: [
        // The pet, not a tick. A finished routine is the one moment this app
        // gets to be warm about, and `abandoned` deliberately gets a resting
        // pet rather than a sad one — stopping early isn't a failure here.
        Center(
          child: MascotSlot(
            mood: abandoned ? MascotMood.resting : MascotMood.cheering,
            size: 124,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          abandoned
              ? l10n.timerAbandonedTitle
              : state.mode == RunMode.low
              ? l10n.timerLowModeCompleteTitle
              : l10n.timerCompleteTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.display,
            fontSize: 36,
            height: 1.1,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          state.mode == RunMode.low
              ? l10n.timerLowModeCompleteSummary(completed, total, _format(ran))
              : l10n.timerCompleteSummary(completed, total, _format(ran)),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 15,
            height: 1.45,
            color: muted,
          ),
        ),
        if (skipped > 0)
          Text(
            l10n.timerCompleteSkipped(skipped),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.body,
              fontSize: 14,
              color: muted,
            ),
          ),
        if (suggestion != null && _approval == null && !_dismissed) ...[
          const SizedBox(height: 24),
          Semantics(
            container: true,
            label: l10n.timerCalibrationTitle,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.all(Radius.circular(22)),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.07),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.timerCalibrationTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.timerCalibrationSummary(
                      _format(
                        Duration(seconds: suggestion.actualDurationSeconds),
                      ),
                      _format(
                        Duration(seconds: suggestion.sourceDurationSeconds),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 14,
                      height: 1.4,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => _approve(suggestion),
                      child: Text(
                        l10n.timerCalibrationApprove(
                          _format(
                            Duration(
                              seconds: suggestion.suggestedDurationSeconds,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => setState(() => _dismissed = true),
                      child: Text(l10n.timerCalibrationNotNow),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_approval != null) ...[
          const SizedBox(height: 24),
          Semantics(
            liveRegion: true,
            child: Text(
              _approval == CalibrationApproval.applied
                  ? l10n.timerCalibrationApplied
                  : l10n.timerCalibrationStale,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 32),
        RunButton(
          label: l10n.timerCloseSummary,
          onPressed: () => context.pop(),
          primary: true,
        ),
      ],
    );
  }

  Future<void> _approve(StepCalibration suggestion) async {
    final result = await suggestion.approve(
      ref.read(storageAdapterProvider),
      updatedAt: DateTime.now(),
    );
    if (mounted) setState(() => _approval = result);
  }
}

/// Elapsed/total time, rounded down — a count-up should read 00:00 for its
/// first second.
String _format(Duration d) => _clock(d.inSeconds);

String _formatTimedElapsed(Duration d) {
  final totalSeconds = d.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _clock(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
