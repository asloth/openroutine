import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../services/routines/estimate.dart';
import '../../services/routines/schedule_time.dart';
import '../../state/routines_provider.dart';
import '../../theme/typography.dart';
import '../../widgets/mascot_slot.dart';
import '../routines_list/home/add_routine_button.dart';
import '../routines_list/home/home_ink.dart';
import '../routines_list/home/home_routine.dart';

/// The Routines tab: every routine, whatever day it's due. Scheduled ones come
/// first in start-time order, then the ones you can start any time.
///
/// A plain list for now; it gets its own redesign round later.
class RoutinesLibraryScreen extends ConsumerWidget {
  const RoutinesLibraryScreen({super.key});

  static const _titleStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final routinesAsync = ref.watch(routinesProvider);

    final title = Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Text(
        l10n.navRoutines,
        style: _titleStyle.copyWith(color: ink.ink),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: routinesAsync.when(
          data: (routines) {
            if (routines.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const MascotSlot(size: 112),
                            const SizedBox(height: 24),
                            Text(
                              l10n.routinesEmptyScheduled,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final sorted = [...routines]..sort(_byStart);
            return ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 96,
              ),
              children: [
                title,
                for (final routine in sorted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: _Row(routine: routine),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(l10n.routinesLoadError)),
        ),
      ),
      floatingActionButton: AddRoutineButton(
        clearance: MediaQuery.paddingOf(context).bottom,
      ),
    );
  }

  /// Scheduled routines by start time, then anytime ones, each by name.
  static int _byStart(Routine a, Routine b) {
    int key(Routine r) {
      if (r.schedule.mode == ScheduleMode.flexible) return 24 * 60 + 1;
      final time = ScheduleTime.parseStartTime(r.schedule.startTime);
      return time == null ? 24 * 60 : time.$1 * 60 + time.$2;
    }

    final byKey = key(a).compareTo(key(b));
    return byKey != 0 ? byKey : a.name.compareTo(b.name);
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final steps = ref.watch(routineStepsProvider(routine.id)).value ?? const [];
    final item = HomeRoutine(
      routine: routine,
      steps: steps,
      estimate: routineEstimate(steps),
      progress: null,
      upcoming: null,
    );
    return HomeRoutineRow(
      item: item,
      subtitle: '${_when(context, l10n)} · ${item.summary(l10n)}',
    );
  }

  String _when(BuildContext context, AppLocalizations l10n) {
    if (routine.schedule.mode == ScheduleMode.flexible) {
      return l10n.routinesAnytime;
    }
    final time = ScheduleTime.parseStartTime(routine.schedule.startTime);
    if (time == null) return l10n.routinesAnytime;
    final at = DateTime(2000, 1, 1, time.$1, time.$2);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return MediaQuery.alwaysUse24HourFormatOf(context)
        ? DateFormat.Hm(locale).format(at)
        : DateFormat.jm(locale).format(at);
  }
}
