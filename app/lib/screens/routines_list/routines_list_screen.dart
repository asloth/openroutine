import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/step.dart';
import '../../models/trigger.dart';
import '../../services/routines/estimate.dart';
import '../../services/routines/next_up.dart';
import '../../services/routines/upcoming.dart';
import '../../state/clock_provider.dart';
import '../../state/reminder_provider.dart';
import '../../state/routines_provider.dart';
import '../../state/timer_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/mascot_slot.dart';
import '../../widgets/tinted/tinted.dart';

/// The mockup's vertical rhythm. These don't match any step in [AppSpacing],
/// so they live here as named literals rather than as new shared tokens —
/// see `openspec/changes/restyle-routines-list/design.md`.
const _headerToPillGap = 24.0;
const _labelToCardsGap = 12.0;
const _cardGap = 12.0;
const _groupGap = 28.0;

/// Clears the FAB so the last card is never trapped underneath it.
const _fabClearance = AppSpacing.section * 2.5;

/// The fill/foreground pair a routine's card — the moment-group one and the
/// "next up" hero — both draw from: the fixed upcoming green while
/// [upcoming] is non-null, the accent otherwise. Shared so the two widgets
/// can't drift apart on which pair means what.
(Color, Color) _upcomingCardColors(
  RoutineCardColors colors,
  UpcomingState? upcoming,
) => upcoming == null
    ? (colors.fill, colors.onFill)
    : (colors.upcomingFill, colors.onUpcomingFill);

/// "in {n} min" while a routine's still counting down, "Now" once it's
/// started, `null` when it isn't upcoming at all — never blank when it is,
/// so the state never rides on color alone. Minutes round up and never show
/// zero: a routine 40 seconds out still reads "in 1 min".
String? _upcomingLabel(AppLocalizations l10n, UpcomingState? upcoming) {
  return switch (upcoming) {
    StartsIn(:final remaining) => l10n.routinesUpcomingIn(
      (remaining.inSeconds / 60).ceil().clamp(1, 1 << 30),
    ),
    InProgress() => l10n.routinesUpcomingNow,
    null => null,
  };
}

/// docs/SPEC.md §7 screen 2: tabs Scheduled/Flexible, sections by trigger,
/// FAB for new routine, and a settings icon. Statistics is a destination on
/// the bottom bar; Import lives in Settings.
class RoutinesListScreen extends ConsumerWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final routinesAsync = ref.watch(routinesProvider);
    final triggersAsync = ref.watch(triggersProvider);

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          // Removing the AppBar removes the status-bar styling it used to
          // supply for free, so the screen sets its own: dark icons over the
          // light theme, light icons over the dark one, and a transparent
          // bar so the tinted background shows through behind it.
          final overlayStyle =
              (brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(statusBarColor: Colors.transparent);

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: Scaffold(
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.element,
                      ),
                      child: Column(
                        children: [
                          PageHeader(
                            title: l10n.appTitle,
                            actions: [
                              SoftCircleButton(
                                icon: Icons.settings_outlined,
                                tooltip: l10n.settingsTitle,
                                onPressed: () => context.push('/settings'),
                              ),
                            ],
                          ),
                          const SizedBox(height: _headerToPillGap),
                          PillSegmentedControl(
                            controller: DefaultTabController.of(context),
                            labels: [
                              l10n.routinesTabScheduled,
                              l10n.routinesTabFlexible,
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: routinesAsync.when(
                        data: (routines) {
                          final triggersById = {
                            for (final t
                                in triggersAsync.value ?? const <Trigger>[])
                              t.id: t,
                          };
                          _armReminders(context, ref, routines, triggersById);
                          return TabBarView(
                            controller: DefaultTabController.of(context),
                            children: [
                              _RoutineSectionList(
                                routines: routines
                                    .where(
                                      (r) =>
                                          r.schedule.mode ==
                                          ScheduleMode.scheduled,
                                    )
                                    .toList(),
                                triggersById: triggersById,
                                emptyMessage: l10n.routinesEmptyScheduled,
                                isScheduledTab: true,
                              ),
                              _RoutineSectionList(
                                routines: routines
                                    .where(
                                      (r) =>
                                          r.schedule.mode ==
                                          ScheduleMode.flexible,
                                    )
                                    .toList(),
                                triggersById: triggersById,
                                emptyMessage: l10n.routinesEmptyFlexible,
                              ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text(l10n.routinesLoadError)),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => context.push('/routines/new'),
                tooltip: l10n.routinesNewRoutine,
                child: const Icon(Icons.add),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Re-arms the OS reminders every time the routine list resolves.
///
/// This screen is the app's home and every mutation — create, edit, delete, a
/// Drive sync pulling down another device's change — surfaces here as a fresh
/// `routinesProvider` value. Hanging the arming off that means no individual
/// call site has to remember to do it, and it is also the only layer that has
/// both the routines and an `AppLocalizations` to write the copy with.
///
/// Deferred a frame because it runs during `build`, and the notifier it calls
/// updates state of its own.
void _armReminders(
  BuildContext context,
  WidgetRef ref,
  List<Routine> routines,
  Map<String, Trigger> triggersById,
) {
  final l10n = AppLocalizations.of(context)!;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref
        .read(routineRemindersProvider.notifier)
        .arm(
          routines,
          ReminderCopy(
            title: (routine) => routine.name,
            body: (routine, lead) {
              final detail = lead == Duration.zero
                  ? l10n.reminderBodyNow
                  : l10n.reminderBodyLead(lead.inMinutes);
              final trigger = triggersById[routine.triggerId];
              // The trigger is the human name for the moment the routine
              // belongs to ("After waking up"), so it earns the front of the
              // line when there is one.
              return trigger == null
                  ? detail
                  : l10n.reminderBodyWithTrigger(trigger.name, detail);
            },
            channelName: l10n.reminderChannelName,
            channelDescription: l10n.reminderChannelDescription,
          ),
        );
  });
}

class _RoutineSectionList extends ConsumerWidget {
  const _RoutineSectionList({
    required this.routines,
    required this.triggersById,
    required this.emptyMessage,
    this.isScheduledTab = false,
  });

  final List<Routine> routines;
  final Map<String, Trigger> triggersById;
  final String emptyMessage;

  /// Only the Scheduled tab's instance computes and shows the "Next up"
  /// hero card — Flexible routines have no start time to rank by, so the
  /// Flexible tab's identical widget never runs that computation.
  final bool isScheduledTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotSlot(mood: MascotMood.idle, size: 112),
              const SizedBox(height: AppSpacing.container),
              Text(emptyMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    // Every candidate's steps and today's completions, the same providers
    // each visible `_RoutineCard` below already reads for itself — reading
    // them here too is what lets `nextUpRoutine` rank the whole tab at once.
    Widget? nextUpCard;
    if (isScheduledTab) {
      final now = ref.watch(clockProvider);
      final today = DateTime(now.year, now.month, now.day);
      final stepsById = <String, List<RoutineStep>?>{};
      final estimateById = <String, Duration>{};
      final completedTodayById = <String, bool>{};
      for (final routine in routines) {
        final steps = ref.watch(routineStepsProvider(routine.id)).value;
        final completions =
            ref.watch(routineCompletionsProvider(routine.id)).value ?? const [];
        stepsById[routine.id] = steps;
        estimateById[routine.id] = routineEstimate(steps ?? const []);
        completedTodayById[routine.id] = completions.any(
          (log) => log.completed && log.localDay == today,
        );
      }
      final nextUp = nextUpRoutine(
        routines,
        now: now,
        estimateFor: (routine) => estimateById[routine.id]!,
        completedTodayFor: (routine) => completedTodayById[routine.id]!,
      );
      if (nextUp != null) {
        nextUpCard = _NextUpCard(
          routine: nextUp,
          moment:
              triggersById[nextUp.triggerId]?.name ?? l10n.routinesNoTrigger,
          steps: stepsById[nextUp.id],
          now: now,
          estimate: estimateById[nextUp.id]!,
          completedToday: completedTodayById[nextUp.id]!,
        );
      }
    }

    final byTrigger = <String?, List<Routine>>{};
    for (final routine in routines) {
      byTrigger.putIfAbsent(routine.triggerId, () => []).add(routine);
    }
    final sectionKeys = byTrigger.keys.toList()
      ..sort(
        (a, b) => (triggersById[a]?.name ?? '').compareTo(
          triggersById[b]?.name ?? '',
        ),
      );

    // A single untriggered group means every routine here is untriggered, and
    // a heading announcing that above the whole list is pure noise. Headings
    // earn their place only when they tell one group apart from another.
    final showHeaders = sectionKeys.length > 1 || sectionKeys.single != null;

    final children = <Widget>[];
    if (nextUpCard != null) {
      children.add(SectionLabel(l10n.routinesNextUp));
      children.add(const SizedBox(height: _labelToCardsGap));
      children.add(nextUpCard);
      children.add(const SizedBox(height: _groupGap));
    }
    for (final (index, triggerId) in sectionKeys.indexed) {
      // A heading belongs to the cards under it, so it sits closer to them
      // than to the group above.
      if (index > 0) children.add(const SizedBox(height: _groupGap));
      if (showHeaders) {
        children.add(
          SectionLabel(triggersById[triggerId]?.name ?? l10n.routinesNoTrigger),
        );
        children.add(const SizedBox(height: _labelToCardsGap));
      }
      final groupRoutines = byTrigger[triggerId]!;
      for (final (i, routine) in groupRoutines.indexed) {
        if (i > 0) children.add(const SizedBox(height: _cardGap));
        children.add(_RoutineCard(routine: routine));
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.element,
        AppSpacing.element,
        AppSpacing.element,
        MediaQuery.paddingOf(context).bottom + _fabClearance,
      ),
      children: children,
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  static const _nameStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.routineCardColors;
    final steps = ref.watch(routineStepsProvider(routine.id)).value;
    final hasCoreSteps = steps?.any((step) => step.isCore) ?? false;

    final now = ref.watch(clockProvider);
    final completions =
        ref.watch(routineCompletionsProvider(routine.id)).value ?? const [];
    final today = DateTime(now.year, now.month, now.day);
    final completedToday = completions.any(
      (log) => log.completed && log.localDay == today,
    );
    final upcoming = upcomingState(
      routine,
      now: now,
      estimate: routineEstimate(steps ?? const []),
      completedToday: completedToday,
    );

    final (fill, onFill) = _upcomingCardColors(colors, upcoming);
    final secondaryStyle = TextStyle(
      fontFamily: AppTypography.body,
      fontSize: 14,
      color: onFill.withValues(alpha: 0.8),
    );

    final upcomingLabel = _upcomingLabel(l10n, upcoming);
    final stepCountLine = upcomingLabel == null
        ? l10n.routinesStepCount(routine.stepIds.length)
        : '${l10n.routinesStepCount(routine.stepIds.length)} · $upcomingLabel';

    return Semantics(
      hint: upcomingLabel,
      child: TintedCard(
        color: fill,
        foregroundColor: onFill,
        padding: EdgeInsets.fromLTRB(16, 18, hasCoreSteps ? 12 : 16, 18),
        onTap: () => context.push('/routines/${routine.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StartTime(routine: routine, onFill: onFill),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name, style: _nameStyle),
                  const SizedBox(height: 2),
                  Text(stepCountLine, style: secondaryStyle),
                  if (steps != null && !hasCoreSteps) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.routinesLowModeSetupGuidance,
                      style: secondaryStyle,
                    ),
                  ],
                ],
              ),
            ),
            if (hasCoreSteps)
              _LowModePill(
                label: l10n.routinesStartLowMode,
                onFill: onFill,
                onPressed: () => context.push(
                  '/routines/${routine.id}/timer?mode=low&steps=${steps!.where((step) => step.isCore).map((step) => step.id).join(',')}',
                ),
              )
            else
              Icon(Icons.chevron_right, color: onFill),
          ],
        ),
      ),
    );
  }
}

/// "Start Low Mode" as a filled pill: `onFill` at 10% opacity, its label in
/// full `onFill`. Nested inside the card's own tappable `TintedCard` the same
/// way the stock `TextButton` it replaces was, so a tap on the pill wins over
/// a tap on the card behind it.
class _LowModePill extends StatelessWidget {
  const _LowModePill({
    required this.label,
    required this.onFill,
    required this.onPressed,
  });

  final String label;
  final Color onFill;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.pillBorder,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onFill.withValues(alpha: 0.1),
              borderRadius: AppRadius.pillBorder,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onFill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Scheduled tab's hero card for the next routine left to run today,
/// picked by `nextUpRoutine` in `_RoutineSectionList`. The routine it names
/// still appears in its own moment group below; this is a second, larger
/// presentation of the same routine, not a replacement for it.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.routine,
    required this.moment,
    required this.steps,
    required this.now,
    required this.estimate,
    required this.completedToday,
  });

  final Routine routine;
  final String moment;
  final List<RoutineStep>? steps;
  final DateTime now;
  final Duration estimate;
  final bool completedToday;

  static const _nameStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.3,
  );
  static const _momentStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const _timeStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Up to five, in step order — a sixth or later step earns its place on
  /// the detail screen, not here.
  static const _maxEmoji = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.routineCardColors;
    final upcoming = upcomingState(
      routine,
      now: now,
      estimate: estimate,
      completedToday: completedToday,
    );
    final (fill, onFill) = _upcomingCardColors(colors, upcoming);
    final upcomingLabel = _upcomingLabel(l10n, upcoming);
    final secondaryStyle = TextStyle(
      fontFamily: AppTypography.body,
      fontSize: 14,
      color: onFill.withValues(alpha: 0.8),
    );

    final timeOfDay = _StartTime._parse(routine.schedule.startTime);
    final timeText = timeOfDay == null
        ? ''
        : MaterialLocalizations.of(context).formatTimeOfDay(
            timeOfDay,
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );

    final visibleSteps = (steps ?? const []).take(_maxEmoji).toList();
    final hasSteps = (steps ?? const []).isNotEmpty;
    final stepsLine = estimate > Duration.zero
        ? '${l10n.routinesStepCount(routine.stepIds.length)} · '
              '${l10n.routineDetailEstimateMinutes((estimate.inSeconds / 60).ceil())}'
        : l10n.routinesStepCount(routine.stepIds.length);

    final momentLine = upcomingLabel == null
        ? moment
        : '$moment · $upcomingLabel';
    final summary = upcomingLabel == null
        ? '${l10n.routinesNextUp}: ${routine.name}, $moment, $timeText'
        : '${l10n.routinesNextUp}: ${routine.name}, $moment, $timeText, '
              '$upcomingLabel';

    return Semantics(
      label: summary,
      child: TintedCard(
        key: const Key('nextUpCard'),
        color: fill,
        foregroundColor: onFill,
        borderRadius: AppRadius.heroBorder,
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        onTap: () => context.push('/routines/${routine.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(momentLine, style: _momentStyle)),
                Text(timeText, style: _timeStyle),
              ],
            ),
            const SizedBox(height: 14),
            Text(routine.name, style: _nameStyle),
            const SizedBox(height: 14),
            if (visibleSteps.isNotEmpty) ...[
              Row(
                children: [
                  for (final (i, step) in visibleSteps.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Text(step.emoji, style: const TextStyle(fontSize: 22)),
                  ],
                ],
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(child: Text(stepsLine, style: secondaryStyle)),
                if (hasSteps)
                  _StartTimerPill(
                    label: l10n.routineDetailStartTimer,
                    fill: fill,
                    onFill: onFill,
                    onPressed: () =>
                        context.push('/routines/${routine.id}/timer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Start Timer" as a solid pill: filled with the card's foreground color,
/// its label and icon in the card's fill color — the inverse of
/// `_LowModePill`'s translucent treatment, since this is the hero card's one
/// primary action rather than a secondary one. `minHeight` rather than a
/// fixed `height` keeps the label from clipping at a large text scale.
class _StartTimerPill extends StatelessWidget {
  const _StartTimerPill({
    required this.label,
    required this.fill,
    required this.onFill,
    required this.onPressed,
  });

  final String label;

  /// The card's own fill — this pill's label and icon color, so it reads as
  /// a cutout of the card rather than an unrelated color.
  final Color fill;

  /// The card's own foreground — this pill's fill.
  final Color onFill;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.pillBorder,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onFill,
              borderRadius: AppRadius.pillBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.display,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: fill,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.play_arrow, size: 18, color: fill),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The hour a routine starts, in a fixed-width column down the left of the
/// list so the times line up regardless of how long the names are.
///
/// Flexible routines have no start time and still reserve the column: letting
/// their cards slide left would break the alignment for every scheduled one
/// around them, which is the whole reason the column exists.
class _StartTime extends StatelessWidget {
  const _StartTime({required this.routine, required this.onFill});

  final Routine routine;

  /// The card's current foreground color — the accent's `onFill`, or
  /// `onUpcomingFill` while the routine is coming up soon.
  final Color onFill;

  /// Wide enough for "12:00 AM" at the body-small size.
  static const _width = 62.0;

  @override
  Widget build(BuildContext context) {
    final time = _parse(routine.schedule.startTime);

    return SizedBox(
      width: _width,
      child: time == null
          ? const SizedBox.shrink()
          : Text(
              // Follows the phone's 12/24-hour setting rather than echoing the
              // 24-hour string the schema stores.
              MaterialLocalizations.of(context).formatTimeOfDay(
                time,
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onFill,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
    );
  }

  /// "HH:MM" per schemas/routine.schema.json. Anything malformed — including a
  /// value an agent wrote by hand — is treated as "no time" rather than
  /// crashing the list it appears in.
  static TimeOfDay? _parse(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
