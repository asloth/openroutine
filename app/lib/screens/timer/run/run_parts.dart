import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/completion_log.dart';
import '../../../models/step.dart';
import '../../../services/timer/timer_machine.dart';
import '../../../theme/typography.dart';

/// Minutes left in the run: the estimates of the current step and every step
/// after it, less the time already spent on the current step. Rounded up and
/// never below zero; a step with no set time adds nothing.
int minutesLeftInRun(
  List<RoutineStep> steps,
  int currentIndex,
  Duration elapsed,
) {
  var seconds = 0;
  for (var i = currentIndex; i < steps.length; i++) {
    final step = steps[i];
    if (step.noExplicitTime) continue;
    seconds += step.durationSeconds ?? 0;
  }
  seconds -= elapsed.inSeconds;
  if (seconds <= 0) return 0;
  return (seconds / 60).ceil();
}

/// Whole minutes to go once an opted-in step reaches its midpoint, or `null`
/// when the halfway banner shouldn't show: before the midpoint, from the
/// estimate on, or for a step that didn't ask for mid-step reminders.
int? halfwayMinutesLeft(RoutineStep step, Duration elapsed) {
  if (!step.remindDuring || step.noExplicitTime) return null;
  final target = step.durationSeconds ?? 0;
  if (target <= 0) return null;
  final spent = elapsed.inSeconds;
  if (spent * 2 < target || spent >= target) return null;
  return ((target - spent) / 60).ceil();
}

/// One step's time, filling toward its estimate.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.value, required this.color});

  /// 0 to 1.
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.09);
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(9)),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Halfway through Stretch, 5 min to go." for a step that opted in.
class HalfwayBanner extends StatelessWidget {
  const HalfwayBanner({super.key, required this.step, required this.elapsed});

  final RoutineStep step;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final minutes = halfwayMinutesLeft(step, elapsed);
    if (minutes == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: scheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.timerHalfway(step.name, minutes),
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width action. The primary one is solid in the palette's primary
/// colour; a secondary one is a quiet outlined card.
class RunButton extends StatelessWidget {
  const RunButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.muted = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  /// Softer label ink, for the action you'd reach for least.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.all(Radius.circular(primary ? 20 : 18));
    return Material(
      color: primary ? scheme.primary : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: primary
            ? BorderSide.none
            : BorderSide(color: scheme.onSurface.withValues(alpha: 0.09)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: primary ? 58 : 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: primary ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: primary
                      ? scheme.onPrimary
                      : scheme.onSurface.withValues(alpha: muted ? 0.6 : 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every step in the order it will run, with what's happened to each so far.
class RestOfRun extends StatelessWidget {
  const RestOfRun({super.key, required this.state, required this.elapsed});

  final TimerState state;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    Color muted(double a) => scheme.onSurface.withValues(alpha: a);
    final outcomes = {for (final o in state.outcomes) o.stepId: o.state};
    final caption = TextStyle(
      fontFamily: AppTypography.body,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: muted(0.45),
    );

    return Column(
      key: const Key('restOfRun'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.timerRestOfRun.toUpperCase(),
              style: caption.copyWith(letterSpacing: 0.8),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: muted(0.1))),
            const SizedBox(width: 10),
            Text(
              l10n.timerMinutesLeft(
                minutesLeftInRun(state.steps, state.currentIndex, elapsed),
              ),
              style: caption,
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final (i, step) in state.steps.indexed)
          _StepRow(
            step: step,
            outcome: outcomes[step.id],
            current: i == state.currentIndex,
            first: i == 0,
            last: i == state.steps.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.outcome,
    required this.current,
    required this.first,
    required this.last,
  });

  final RoutineStep step;
  final CompletionStepState? outcome;
  final bool current;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    Color muted(double a) => scheme.onSurface.withValues(alpha: a);
    final skipped = outcome == CompletionStepState.skipped;
    final done = outcome != null && !skipped;
    final rail = muted(0.15);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Expanded(
                  child: Container(width: 1.5, color: first ? null : rail),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? scheme.primary : null,
                    border: Border.all(
                      width: current ? 2.5 : 1.5,
                      color: done || current ? scheme.primary : muted(0.25),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(width: 1.5, color: last ? null : rail),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: current
                  ? BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.45),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      step.name,
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: skipped
                            ? muted(0.4)
                            : current
                            ? scheme.onSurface
                            : muted(0.65),
                        decoration: skipped ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (!step.noExplicitTime)
                    Text(
                      l10n.timerStepMinutes(
                        ((step.durationSeconds ?? 0) / 60).ceil(),
                      ),
                      style: TextStyle(
                        fontFamily: AppTypography.body,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: muted(0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
