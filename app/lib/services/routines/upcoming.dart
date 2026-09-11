import '../../models/routine.dart';
import '../../models/schedule.dart';
import 'schedule_time.dart';

/// Whether a routine currently counts as "coming up soon," and if so, which
/// of the two ways.
///
/// `null` means the routine is not upcoming right now.
sealed class UpcomingState {
  const UpcomingState();
}

/// Still ahead of its start time, [remaining] away.
class StartsIn extends UpcomingState {
  const StartsIn(this.remaining);

  final Duration remaining;
}

/// Past its start time and still inside its estimated duration.
class InProgress extends UpcomingState {
  const InProgress();
}

/// Decides whether [routine] is upcoming at [now].
///
/// Pure date maths, no plugin and no I/O — the same shape as
/// `ReminderSchedule`, and for the same reason: a fake `now` is what keeps
/// this deterministic in tests without a fake clock harness.
///
/// Only a scheduled routine with a valid start time can be upcoming. Each
/// occurrence's window is `[start − lead, start + estimate)`: outside every
/// window, or once [completedToday] is `true`, the result is `null`. Inside
/// the lead but before the start, the result is [StartsIn]; from the start
/// until the estimate ends, it's [InProgress].
///
/// A window can cross midnight in either direction — a 23:40 run is still in
/// progress at 00:05, and a 00:05 start is already upcoming at 23:55 — so
/// yesterday's and tomorrow's occurrences are checked alongside today's.
UpcomingState? upcomingState(
  Routine routine, {
  required DateTime now,
  required Duration estimate,
  required bool completedToday,
  Duration lead = const Duration(minutes: 15),
}) {
  if (completedToday) return null;
  if (routine.schedule.mode != ScheduleMode.scheduled) return null;

  final time = ScheduleTime.parseStartTime(routine.schedule.startTime);
  if (time == null) return null;

  final weekdays = routine.schedule.days.map(ScheduleTime.weekday).toSet();

  for (final offset in const [-1, 0, 1]) {
    // Built from date parts rather than by adding a Duration to midnight — see
    // ReminderSchedule.occurrences for why: that avoids landing an hour off
    // on a DST transition day. The constructor also normalizes day 0 or 32.
    final start = DateTime(
      now.year,
      now.month,
      now.day + offset,
      time.$1,
      time.$2,
    );
    if (!weekdays.contains(start.weekday)) continue;

    if (now.isBefore(start.subtract(lead))) continue;
    if (now.isBefore(start)) return StartsIn(start.difference(now));
    if (now.isBefore(start.add(estimate))) return const InProgress();
  }
  return null;
}
