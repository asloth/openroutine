import '../../models/routine.dart';
import '../../models/schedule.dart';
import 'schedule_time.dart';

/// Picks the routine most worth showing as "next up" today, or `null` when
/// nothing qualifies.
///
/// Pure date maths, no plugin and no I/O — the same shape as
/// `upcomingState`, and for the same reason: a fake `now` is what keeps this
/// deterministic in tests. [estimateFor] and [completedTodayFor] let the
/// caller assemble each candidate's estimate and today's completion from
/// whatever providers it watches, without this function knowing about
/// either.
///
/// A routine qualifies when it's in scheduled mode, its days include today's
/// weekday, its start time parses, its window — `[start, start + estimate)`
/// — hasn't ended yet, and it hasn't already been completed today. Among
/// qualifying routines, the earliest `start` wins, so a routine already in
/// progress still outranks one that hasn't started. Unlike `upcomingState`,
/// there's no lead time and no yesterday/tomorrow occurrence search — only
/// today's occurrence is ever considered, because "next up" means the next
/// thing left to do today, not a countdown that might start early.
Routine? nextUpRoutine(
  List<Routine> routines, {
  required DateTime now,
  required Duration Function(Routine routine) estimateFor,
  required bool Function(Routine routine) completedTodayFor,
}) {
  Routine? winner;
  DateTime? winnerStart;

  for (final routine in routines) {
    if (routine.schedule.mode != ScheduleMode.scheduled) continue;

    final time = ScheduleTime.parseStartTime(routine.schedule.startTime);
    if (time == null) continue;

    final start = DateTime(now.year, now.month, now.day, time.$1, time.$2);
    final weekdays = routine.schedule.days.map(ScheduleTime.weekday).toSet();
    if (!weekdays.contains(start.weekday)) continue;

    if (completedTodayFor(routine)) continue;
    if (!now.isBefore(start.add(estimateFor(routine)))) continue;

    if (winnerStart == null || start.isBefore(winnerStart)) {
      winner = routine;
      winnerStart = start;
    }
  }

  return winner;
}
