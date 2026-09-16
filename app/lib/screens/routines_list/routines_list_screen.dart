import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/trigger.dart';
import '../../services/routines/estimate.dart';
import '../../services/routines/next_up.dart';
import '../../services/routines/schedule_time.dart';
import '../../services/routines/today_progress.dart';
import '../../services/routines/upcoming.dart';
import '../../state/clock_provider.dart';
import '../../state/reminder_provider.dart';
import '../../state/routines_provider.dart';
import '../../state/stats_provider.dart';
import '../../state/timer_provider.dart';
import '../../widgets/mascot_slot.dart';
import 'home/anytime_section.dart';
import 'home/home_header.dart';
import 'home/home_ink.dart';
import 'home/home_routine.dart';
import 'home/nudge_card.dart';
import 'home/other_days.dart';
import 'home/timeline.dart';

/// Side padding from the design.
const _gutter = 22.0;

/// Clears the Add a routine pill so the last card is never trapped under it.
const _fabClearance = 96.0;

/// Home: today's date and streak, a nudge from the mascot about the next
/// routine, flexible routines under Anytime today, today's scheduled routines
/// on a timeline, and everything else folded under Other days. See
/// `openspec/changes/redesign-home-today/`.
class RoutinesListScreen extends ConsumerStatefulWidget {
  const RoutinesListScreen({super.key});

  @override
  ConsumerState<RoutinesListScreen> createState() => _RoutinesListScreenState();
}

class _RoutinesListScreenState extends ConsumerState<RoutinesListScreen> {
  bool _anytimeOpen = true;
  bool _otherDaysOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final routinesAsync = ref.watch(routinesProvider);
    final triggersAsync = ref.watch(triggersProvider);
    final now = ref.watch(clockProvider);
    final streak =
        ref.watch(statisticsProvider).value?.completion.currentStreakDays ?? 0;

    // No AppBar, so the screen sets its own status bar: dark icons over the
    // light theme, light over the dark, transparent so the paper shows.
    final overlayStyle =
        (brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 12, _gutter, 0),
      child: HomeHeader(now: now, streakDays: streak),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: routinesAsync.when(
            data: (routines) {
              final triggersById = {
                for (final t in triggersAsync.value ?? const <Trigger>[])
                  t.id: t,
              };
              _armReminders(context, ref, routines, triggersById);
              if (routines.isEmpty) {
                return Column(
                  children: [
                    header,
                    const Expanded(child: _EmptyState()),
                  ],
                );
              }
              return _buildDay(context, header, routines, now);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text(l10n.routinesLoadError)),
          ),
        ),
        // The shell's nav pill floats over the body and reports itself as
        // bottom padding, which the Scaffold doesn't lift a button for. The
        // pill is wide enough to collide with this one, so it clears it here.
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/routines/new'),
            backgroundColor: HomeInk.of(context).action,
            foregroundColor: HomeInk.of(context).onAction,
            shape: const StadiumBorder(),
            icon: const Icon(Icons.add),
            label: Text(
              l10n.homeAddRoutine,
              style: HomeInk.title.copyWith(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDay(
    BuildContext context,
    Widget header,
    List<Routine> routines,
    DateTime now,
  ) {
    final items = [for (final r in routines) _gather(r, now)];
    final byId = {for (final item in items) item.id: item};

    final anytime = [
      for (final item in items)
        if (item.routine.schedule.mode == ScheduleMode.flexible) item,
    ];
    final scheduled = [
      for (final item in items)
        if (item.routine.schedule.mode == ScheduleMode.scheduled) item,
    ];
    final today = [
      for (final item in scheduled)
        if (_dueToday(item.routine, now)) item,
    ]..sort((a, b) => _startMinutes(a).compareTo(_startMinutes(b)));
    final otherDays = [
      for (final item in scheduled)
        if (!_dueToday(item.routine, now)) item,
    ];

    // The nudge only speaks up inside the routine's upcoming window: a
    // routine hours away is on the timeline, not worth interrupting for.
    final nextUp = nextUpRoutine(
      routines,
      now: now,
      estimateFor: (r) => byId[r.id]!.estimate,
      completedTodayFor: (r) => byId[r.id]!.progress is DoneToday,
    );
    final nudge = nextUp == null ? null : byId[nextUp.id]!;
    final nudgeState = nudge?.upcoming;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        if (nudge != null && nudgeState != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_gutter, 20, _gutter, 0),
              child: NudgeCard(routine: nudge.routine, upcoming: nudgeState),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (anytime.isNotEmpty)
          AnytimeSection(
            routines: anytime,
            open: _anytimeOpen,
            onToggle: () => setState(() => _anytimeOpen = !_anytimeOpen),
          ),
        if (today.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_gutter - 8, 12, _gutter, 0),
            sliver: SliverToBoxAdapter(child: Timeline(routines: today)),
          ),
        if (otherDays.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_gutter, 20, _gutter, 0),
            sliver: SliverToBoxAdapter(
              child: OtherDays(
                routines: otherDays,
                open: _otherDaysOpen,
                onToggle: () =>
                    setState(() => _otherDaysOpen = !_otherDaysOpen),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + _fabClearance,
          ),
        ),
      ],
    );
  }

  HomeRoutine _gather(Routine routine, DateTime now) {
    final steps = ref.watch(routineStepsProvider(routine.id)).value ?? const [];
    final runs =
        ref.watch(routineCompletionsProvider(routine.id)).value ?? const [];
    final estimate = routineEstimate(steps);
    final progress = todayProgress(
      [
        for (final run in runs)
          (
            startedAt: run.startedAt,
            completed: run.completed,
            stepsDone: run.stepsDone,
          ),
      ],
      now: now,
      stepCount: routine.stepIds.length,
    );
    return HomeRoutine(
      routine: routine,
      steps: steps,
      estimate: estimate,
      progress: progress,
      upcoming: upcomingState(
        routine,
        now: now,
        estimate: estimate,
        completedToday: progress is DoneToday,
      ),
    );
  }

  static bool _dueToday(Routine routine, DateTime now) =>
      routine.schedule.days.map(ScheduleTime.weekday).contains(now.weekday);

  /// Minutes past midnight, with an unparseable time sorted last.
  static int _startMinutes(HomeRoutine item) {
    final time = ScheduleTime.parseStartTime(item.routine.schedule.startTime);
    return time == null ? 24 * 60 : time.$1 * 60 + time.$2;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotSlot(size: 112),
            const SizedBox(height: 24),
            Text(l10n.routinesEmptyScheduled, textAlign: TextAlign.center),
          ],
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
