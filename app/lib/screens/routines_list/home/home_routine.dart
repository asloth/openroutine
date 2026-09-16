import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/routine.dart';
import '../../../models/step.dart';
import '../../../services/routines/today_progress.dart';
import '../../../services/routines/upcoming.dart';
import 'home_ink.dart';

/// A routine with everything home shows about it today, gathered once by the
/// screen so the sections below stay free of providers.
class HomeRoutine {
  const HomeRoutine({
    required this.routine,
    required this.steps,
    required this.estimate,
    required this.progress,
    required this.upcoming,
  });

  final Routine routine;
  final List<RoutineStep> steps;
  final Duration estimate;
  final TodayProgress? progress;
  final UpcomingState? upcoming;

  String get id => routine.id;

  /// Rounded up, so a 30-second routine doesn't read "0 min".
  int get minutes => (estimate.inSeconds / 60).ceil();

  bool get hasCoreSteps => steps.any((step) => step.isCore);

  String summary(AppLocalizations l10n) =>
      l10n.homeStepsAndMinutes(routine.stepIds.length, minutes);

  void open(BuildContext context) => context.push('/routines/$id');

  void start(BuildContext context) => context.push('/routines/$id/timer');

  void startLowMode(BuildContext context) => context.push(
    '/routines/$id/timer?mode=low'
    '&steps=${steps.where((step) => step.isCore).map((step) => step.id).join(',')}',
  );
}

/// A small round dot in the accent.
class HomeDot extends StatelessWidget {
  const HomeDot({super.key, this.size = 9});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: HomeInk.of(context).accent,
      shape: BoxShape.circle,
    ),
  );
}

/// The rounded row that opens and closes a collapsible home section.
class HomeSectionToggle extends StatelessWidget {
  const HomeSectionToggle({
    super.key,
    required this.leading,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(18));
    return Material(
      color: ink.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ink.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: HomeInk.title.copyWith(
                      fontSize: 13.5,
                      color: ink.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: HomeInk.label.copyWith(color: ink.muted(0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain white row for a routine: dot, name, summary, and an optional
/// trailing control. Used by Anytime today and Other days.
class HomeRoutineRow extends StatelessWidget {
  const HomeRoutineRow({
    super.key,
    required this.item,
    required this.subtitle,
    this.trailing,
  });

  final HomeRoutine item;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(20));
    return Material(
      color: ink.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ink.hairline),
      ),
      child: InkWell(
        onTap: () => item.open(context),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 13, 8, 13),
          child: Row(
            children: [
              const HomeDot(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.routine.name,
                      style: HomeInk.title.copyWith(color: ink.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: HomeInk.detail.copyWith(
                        fontSize: 12.5,
                        color: ink.muted(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet text action inside a card, 48px tall so it's easy to hit.
class HomeTextAction extends StatelessWidget {
  const HomeTextAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: HomeInk.label.copyWith(color: ink.accent),
            ),
          ),
        ),
      ),
    );
  }
}
