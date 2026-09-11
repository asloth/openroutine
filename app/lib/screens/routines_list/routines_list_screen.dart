import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/trigger.dart';
import '../../services/routines/estimate.dart';
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
  });

  final List<Routine> routines;
  final Map<String, Trigger> triggersById;
  final String emptyMessage;

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

    final fill = upcoming == null ? colors.fill : colors.upcomingFill;
    final onFill = upcoming == null ? colors.onFill : colors.onUpcomingFill;
    final secondaryStyle = TextStyle(
      fontFamily: AppTypography.body,
      fontSize: 14,
      color: onFill.withValues(alpha: 0.8),
    );

    // "in {n} min" while it's still counting down, "Now" once it's started;
    // never blank, so the state never rides on color alone. Minutes round up
    // and never show zero — a routine 40 seconds out still reads "in 1 min".
    final upcomingLabel = switch (upcoming) {
      StartsIn(:final remaining) => l10n.routinesUpcomingIn(
        (remaining.inSeconds / 60).ceil().clamp(1, 1 << 30),
      ),
      InProgress() => l10n.routinesUpcomingNow,
      null => null,
    };
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
