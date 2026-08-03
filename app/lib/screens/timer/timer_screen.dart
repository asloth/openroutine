import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/completion_log.dart';
import '../../models/step.dart';
import '../../services/timer/timer_machine.dart';
import '../../state/routines_provider.dart';
import '../../state/timer_provider.dart';

/// docs/SPEC.md §7 screen 7 — the full-screen playlist runner.
///
/// The screen reads the clock on every build rather than holding a countdown
/// of its own; the notifier's 1-second ticker just triggers those builds. That
/// keeps the display honest after the app has been backgrounded, where a
/// locally decremented counter would come back stale.
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepsAsync = ref.watch(routineStepsProvider(widget.routineId));
    final timer = ref.watch(routineTimerProvider(widget.routineId));

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
        notifier.load(steps);
        notifier.start();
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
        body: SafeArea(
          child: switch (timer.phase) {
            TimerPhase.idle => const Center(child: CircularProgressIndicator()),
            TimerPhase.complete => _Summary(state: timer),
            _ => _Running(state: timer, routineId: widget.routineId),
          },
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
  const _Running({required this.state, required this.routineId});

  final TimerState state;
  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notifier = ref.read(routineTimerProvider(routineId).notifier);
    final step = state.currentStep;
    if (step == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final elapsed = state.elapsed(now);
    final remaining = state.remaining(now);
    final overrun = remaining != null && remaining.isNegative;

    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.timerAbandonConfirmAction,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.timerStepCounter(state.currentIndex + 1, state.steps.length),
            style: theme.textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (state.currentIndex + 1) / state.steps.length,
        ),
        // Scrollable so the runner survives short screens and large system
        // font scales; the controls below stay pinned either way.
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(step.emoji, style: const TextStyle(fontSize: 88)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      step.name,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Clock(
                    step: step,
                    elapsed: elapsed,
                    remaining: remaining,
                    paused: state.phase == TimerPhase.paused,
                  ),
                  if (overrun)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.timerOverrunBy(_format(-remaining)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircleAction(
                icon: Icons.skip_previous,
                label: l10n.timerBack,
                onPressed: state.isFirstStep ? null : notifier.back,
              ),
              _CircleAction(
                icon: state.phase == TimerPhase.paused
                    ? Icons.play_arrow
                    : Icons.pause,
                label: state.phase == TimerPhase.paused
                    ? l10n.timerResume
                    : l10n.timerPause,
                onPressed: state.phase == TimerPhase.paused
                    ? notifier.resume
                    : notifier.pause,
              ),
              _CircleAction(
                icon: Icons.restart_alt,
                label: l10n.timerRestartStep,
                onPressed: notifier.resetStep,
              ),
              _CircleAction(
                icon: Icons.skip_next,
                label: l10n.timerSkip,
                onPressed: notifier.skip,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: notifier.completeStep,
              icon: const Icon(Icons.check),
              label: Text(
                state.isLastStep ? l10n.timerFinish : l10n.timerDone,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The countdown, or a count-up for steps with no target. Steps without an
/// explicit time get no ring — there is no fraction of "done" to show.
class _Clock extends StatelessWidget {
  const _Clock({
    required this.step,
    required this.elapsed,
    required this.remaining,
    required this.paused,
  });

  final RoutineStep step;
  final Duration elapsed;
  final Duration? remaining;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = Text(
      remaining == null
          ? _format(elapsed)
          : _formatRemaining(
              remaining!.isNegative ? Duration.zero : remaining!,
            ),
      style: theme.textTheme.displayMedium?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: paused ? theme.disabledColor : null,
      ),
    );

    if (remaining == null) {
      return Column(
        children: [
          label,
          Text(l10n.timerNoSetTime, style: theme.textTheme.bodySmall),
        ],
      );
    }

    final target = Duration(seconds: step.durationSeconds ?? 0);
    final progress = target.inMilliseconds == 0
        ? 1.0
        : (elapsed.inMilliseconds / target.inMilliseconds).clamp(0.0, 1.0);

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(value: progress, strokeWidth: 10),
          ),
          label,
        ],
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.state});

  final TimerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              abandoned ? Icons.pause_circle_outline : Icons.check_circle,
              size: 96,
              color: abandoned
                  ? theme.disabledColor
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              abandoned ? l10n.timerAbandonedTitle : l10n.timerCompleteTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.timerCompleteSummary(completed, total, _format(ran)),
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (skipped > 0)
              Text(
                l10n.timerCompleteSkipped(skipped),
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.timerCloseSummary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      icon: Icon(icon),
      tooltip: label,
      onPressed: onPressed,
    );
  }
}

/// Elapsed/total time, rounded down — a count-up should read 00:00 for its
/// first second.
String _format(Duration d) => _clock(d.inSeconds);

/// Time remaining, rounded **up**. A 60-second step is a few milliseconds in by
/// the time it first paints, and truncating would show 00:59 before the user
/// has blinked. Rounding up means it reads 01:00 until a full second is gone,
/// and reaches 00:00 exactly when the step is up.
String _formatRemaining(Duration d) => _clock((d.inMilliseconds / 1000).ceil());

String _clock(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
