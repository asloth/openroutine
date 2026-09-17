import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/schedule.dart';
import '../../state/app_prefs_provider.dart';
import '../../theme/motion.dart';
import '../../theme/typography.dart';
import '../../widgets/mascot_slot.dart';
import '../routines_list/home/home_ink.dart';

/// Onboarding as a five-beat story the mascot acts out: hello, scheduled
/// routines, flexible routines, going step by step, and making your first
/// routine. It ends in the routine builder, on top of Today.
///
/// There's no storage question. Everyone starts Local-only, and Drive is one
/// switch away in Settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// One move the pet makes, at a point (0 to 1) through its beat's script.
typedef _Move = (double at, MascotReaction reaction);

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _beatCount = 5;

  /// How long each beat's script runs. Long enough for the Rive moves to
  /// play out, short enough that nobody waits for Next.
  static const _scriptLength = Duration(milliseconds: 2600);

  /// Where the run-in ends on the scheduled beat, and the bell rings.
  static const _arrival = 0.55;
  static const _bell = 0.62;

  /// Where the done and skipped steps land on the steps beat.
  static const _stepDone = 0.25;
  static const _stepSkipped = 0.7;

  static const _moves = <List<_Move>>[
    [(0.2, MascotReaction.wave)],
    [(0, MascotReaction.run), (_bell, MascotReaction.jump)],
    [(0.1, MascotReaction.bounce)],
    [(_stepDone, MascotReaction.stepDone), (_stepSkipped, MascotReaction.skip)],
    [(0.1, MascotReaction.celebrate)],
  ];

  final _pages = PageController();
  late final AnimationController _script = AnimationController(
    vsync: this,
    duration: _scriptLength,
  )..addListener(_cueMoves);

  int _beat = 0;
  int _movesPlayed = 0;
  MascotCue? _cue;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play(0);
  }

  @override
  void dispose() {
    _script.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Starts [beat]'s script from the top. Reduced motion jumps to its end, so
  /// the demo shows its final state and the pet gets only the last cue.
  void _play(int beat) {
    _beat = beat;
    _movesPlayed = 0;
    _script
      ..duration = context.motion(_scriptLength)
      ..value = 0;
    _cueMoves();
    _script.forward();
  }

  void _cueMoves() {
    final moves = _moves[_beat];
    var next = _movesPlayed;
    while (next < moves.length && moves[next].$1 <= _script.value) {
      next++;
    }
    if (next == _movesPlayed) return;
    setState(() {
      _movesPlayed = next;
      _cue = MascotCue(moves[next - 1].$2);
    });
  }

  void _next() {
    _pages.nextPage(
      duration: context.motion(AppMotion.emphasized),
      curve: AppMotion.transition,
    );
  }

  /// Marks onboarding done and opens Today, with the builder on top when
  /// [create] names the kind of routine to start.
  Future<void> _finish({ScheduleMode? create}) async {
    final router = GoRouter.of(context);
    await ref.read(onboardingCompleteProvider.notifier).complete();
    router.go('/routines');
    if (create != null) router.push('/routines/new?mode=${create.name}');
  }

  double _progressOf(int beat) => beat == _beat
      ? _script.value
      : beat < _beat
      ? 1
      : 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              ink.scheme.primaryContainer.withValues(alpha: 0.45),
              ink.scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgressBar(beat: _beat, count: _beatCount),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: ink.muted(0.62),
                      ),
                      child: Text(l10n.onboardingSkip, style: HomeInk.label),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Held sideways there's no height for a stage under the
                    // words, so the pet stands beside them instead.
                    final sideways =
                        constraints.maxWidth > constraints.maxHeight * 1.4;
                    // Upright, the pet takes whatever the words and the demo
                    // leave over, within reason.
                    final height = sideways
                        ? constraints.maxHeight
                        : (constraints.maxHeight - 420).clamp(176.0, 300.0);
                    final pages = AnimatedBuilder(
                      animation: _script,
                      builder: (context, _) => PageView(
                        controller: _pages,
                        onPageChanged: _play,
                        children: [
                          _Beat(
                            title: l10n.onboardingHelloTitle,
                            body: l10n.onboardingHelloBody,
                          ),
                          _Beat(
                            title: l10n.onboardingScheduledTitle,
                            body: l10n.onboardingScheduledBody,
                            demo: _RoutineDemo(
                              icon: Icons.wb_sunny_outlined,
                              name: l10n.onboardingScheduledDemoName,
                              when: l10n.onboardingScheduledDemoWhen,
                              reminder: _progressOf(1) >= _bell
                                  ? l10n.onboardingScheduledDemoReminder
                                  : null,
                            ),
                          ),
                          _Beat(
                            title: l10n.onboardingFlexibleTitle,
                            body: l10n.onboardingFlexibleBody,
                            demo: _RoutineDemo(
                              icon: Icons.self_improvement,
                              name: l10n.onboardingFlexibleDemoName,
                              when: l10n.routinesAnytime,
                            ),
                          ),
                          _Beat(
                            title: l10n.onboardingStepsTitle,
                            body: l10n.onboardingStepsBody,
                            demo: _StepsDemo(progress: _progressOf(3)),
                          ),
                          _Beat(
                            title: l10n.onboardingCreateTitle,
                            body: l10n.onboardingCreateBody,
                          ),
                        ],
                      ),
                    );
                    final stage = AnimatedBuilder(
                      animation: _script,
                      builder: (context, child) {
                        // On the scheduled beat the pet runs in from off the left
                        // edge while Rive plays the stride on the spot.
                        final width = MediaQuery.sizeOf(context).width;
                        final t = _beat == 1
                            ? AppMotion.entrance.transform(
                                math.min(1, _script.value / _arrival),
                              )
                            : 1.0;
                        return Transform.translate(
                          offset: Offset(-(width / 2 + 130) * (1 - t), 0),
                          child: child,
                        );
                      },
                      child: Center(
                        child: MascotSlot(
                          size: math.min(240, height * 0.8),
                          cue: _cue,
                        ),
                      ),
                    );
                    if (sideways) {
                      return Row(
                        children: [
                          Expanded(flex: 3, child: pages),
                          Expanded(flex: 2, child: stage),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(child: pages),
                        SizedBox(height: height, child: stage),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: switch (_beat) {
                  0 => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PrimaryButton(
                        label: l10n.onboardingGetStarted,
                        onPressed: _next,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.onboardingHelloFootnote,
                        textAlign: TextAlign.center,
                        style: HomeInk.detail.copyWith(
                          fontSize: 12,
                          color: ink.muted(0.45),
                        ),
                      ),
                    ],
                  ),
                  4 => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PrimaryButton(
                        label: l10n.onboardingCreateScheduled,
                        onPressed: () =>
                            _finish(create: ScheduleMode.scheduled),
                      ),
                      const SizedBox(height: 10),
                      _PrimaryButton(
                        label: l10n.onboardingCreateFlexible,
                        quiet: true,
                        onPressed: () => _finish(create: ScheduleMode.flexible),
                      ),
                    ],
                  ),
                  _ => _PrimaryButton(
                    label: l10n.onboardingNext,
                    onPressed: _next,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.beat, required this.count});

  final int beat;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: context.motion(AppMotion.standard),
              curve: AppMotion.transition,
              height: 4,
              decoration: BoxDecoration(
                color: i <= beat ? ink.ink : ink.muted(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A beat's words, and the small demo that illustrates them.
class _Beat extends StatelessWidget {
  const _Beat({required this.title, required this.body, this.demo});

  final String title;
  final String body;
  final Widget? demo;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.display,
              fontSize: 34,
              height: 1.08,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w700,
              color: ink.ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: HomeInk.detail.copyWith(
              fontSize: 15.5,
              height: 1.5,
              color: ink.muted(0.62),
            ),
          ),
          if (demo != null) ...[const SizedBox(height: 24), demo!],
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.hairline),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

/// An example routine card. On the scheduled beat, a reminder pops in beside
/// it when the bell rings.
class _RoutineDemo extends StatelessWidget {
  const _RoutineDemo({
    required this.icon,
    required this.name,
    required this.when,
    this.reminder,
  });

  final IconData icon;
  final String name;
  final String when;
  final String? reminder;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    final reminder = this.reminder;
    return _DemoCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ink.scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ink.scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: HomeInk.title.copyWith(color: ink.ink)),
                const SizedBox(height: 2),
                Text(
                  when,
                  style: HomeInk.detail.copyWith(color: ink.muted(0.55)),
                ),
              ],
            ),
          ),
          AnimatedScale(
            scale: reminder == null ? 0.6 : 1,
            duration: context.motion(AppMotion.emphasized),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: reminder == null ? 0 : 1,
              duration: context.motion(AppMotion.quick),
              child: reminder == null
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ink.action,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 15,
                            color: ink.onAction,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reminder,
                            style: HomeInk.label.copyWith(
                              fontSize: 12,
                              color: ink.onAction,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { waiting, now, done, skipped }

/// A three-step run playing out: the first step gets done, the second gets
/// skipped, and the third is up.
class _StepsDemo extends StatelessWidget {
  const _StepsDemo({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = progress >= _OnboardingScreenState._stepDone;
    final skipped = progress >= _OnboardingScreenState._stepSkipped;
    final steps = [
      (l10n.onboardingStepsDemo1, done ? _StepState.done : _StepState.now),
      (
        l10n.onboardingStepsDemo2,
        skipped
            ? _StepState.skipped
            : done
            ? _StepState.now
            : _StepState.waiting,
      ),
      (
        l10n.onboardingStepsDemo3,
        skipped ? _StepState.now : _StepState.waiting,
      ),
    ];
    return _DemoCard(
      child: Column(
        children: [
          for (final (name, state) in steps) _StepRow(name: name, state: state),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.name, required this.state});

  final String name;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final (icon, colour, label) = switch (state) {
      _StepState.done => (
        Icons.check_circle,
        ink.accent,
        l10n.onboardingStepsDone,
      ),
      _StepState.skipped => (
        Icons.redo_rounded,
        ink.muted(0.4),
        l10n.onboardingStepsSkipped,
      ),
      _StepState.now => (
        Icons.radio_button_checked,
        ink.accent,
        l10n.onboardingStepsNow,
      ),
      _StepState.waiting => (Icons.circle_outlined, ink.muted(0.25), null),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: context.motion(AppMotion.quick),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(icon, key: ValueKey(state), size: 22, color: colour),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: HomeInk.title.copyWith(
                fontSize: 14.5,
                color: state == _StepState.skipped ? ink.muted(0.4) : ink.ink,
                decoration: state == _StepState.skipped
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (label != null)
            Text(label, style: HomeInk.label.copyWith(color: colour)),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.quiet = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// The second choice: the card colour with a hairline, not a solid fill.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: quiet ? ink.card : ink.action,
        foregroundColor: quiet ? ink.ink : ink.onAction,
        side: quiet ? BorderSide(color: ink.muted(0.14)) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(label, style: HomeInk.title),
    );
  }
}
