import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/trigger.dart';
import '../../state/reminder_provider.dart';
import '../../state/routines_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/mascot_slot.dart';

/// docs/SPEC.md §7 screen 2: tabs Scheduled/Flexible, sections by trigger,
/// FAB for new routine, and a settings icon. Statistics is a destination on
/// the bottom bar; Import lives in Settings.
class RoutinesListScreen extends ConsumerWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final routinesAsync = ref.watch(routinesProvider);
    final triggersAsync = ref.watch(triggersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.routinesTabScheduled),
              Tab(text: l10n.routinesTabFlexible),
            ],
          ),
          actions: [
            // Statistics moved to the bottom bar and Import into Settings, so
            // the corner the overflow menu used to occupy now holds the one
            // destination left: Settings itself.
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settingsTitle,
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: routinesAsync.when(
          data: (routines) {
            final triggersById = {
              for (final t in triggersAsync.value ?? const <Trigger>[]) t.id: t,
            };
            _armReminders(context, ref, routines, triggersById);
            return TabBarView(
              children: [
                _RoutineSectionList(
                  routines: routines
                      .where((r) => r.schedule.mode == ScheduleMode.scheduled)
                      .toList(),
                  triggersById: triggersById,
                  emptyMessage: l10n.routinesEmptyScheduled,
                ),
                _RoutineSectionList(
                  routines: routines
                      .where((r) => r.schedule.mode == ScheduleMode.flexible)
                      .toList(),
                  triggersById: triggersById,
                  emptyMessage: l10n.routinesEmptyFlexible,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(l10n.routinesLoadError)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/routines/new'),
          tooltip: l10n.routinesNewRoutine,
          child: const Icon(Icons.add),
        ),
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

    final theme = Theme.of(context);

    // A single untriggered group means every routine here is untriggered, and
    // a heading announcing that above the whole list is pure noise. Headings
    // earn their place only when they tell one group apart from another.
    final showHeaders = sectionKeys.length > 1 || sectionKeys.single != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.element,
        AppSpacing.element,
        AppSpacing.element,
        // Clears the FAB so the last card is never trapped underneath it.
        AppSpacing.section * 2.5,
      ),
      children: [
        for (final (index, triggerId) in sectionKeys.indexed) ...[
          if (showHeaders)
            Padding(
              // A heading belongs to the cards under it, so it sits closer to
              // them than to the group above. The old padding had that
              // backwards — 16 above, 8 below — which read as the heading
              // being crowded by its own first card.
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base,
                index == 0 ? 0 : AppSpacing.section,
                AppSpacing.base,
                AppSpacing.element,
              ),
              child: Text(
                triggersById[triggerId]?.name ?? l10n.routinesNoTrigger,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final routine in byTrigger[triggerId]!)
            _RoutineCard(routine: routine),
        ],
      ],
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final steps = ref.watch(routineStepsProvider(routine.id)).value;
    final hasCoreSteps = steps?.any((step) => step.isCore) ?? false;
    return NeumorphicCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.element),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.element,
        vertical: AppSpacing.element,
      ),
      onTap: () => context.push('/routines/${routine.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StartTime(routine: routine),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  l10n.routinesStepCount(routine.stepIds.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (steps != null && !hasCoreSteps) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.routinesLowModeSetupGuidance,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasCoreSteps)
            Semantics(
              button: true,
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => context.push(
                    '/routines/${routine.id}/timer?mode=low&steps=${steps!.where((step) => step.isCore).map((step) => step.id).join(',')}',
                  ),
                  child: Text(l10n.routinesStartLowMode),
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
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
  const _StartTime({required this.routine});

  final Routine routine;

  /// Wide enough for "12:00 AM" at the body-small size.
  static const _width = 62.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
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
