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
/// Only a scheduled routine with a valid start time on today's weekday can be
/// upcoming. Its window is `[start − lead, start + estimate)`: before that,
/// or once [completedToday] is `true`, the result is `null`. Inside the lead
/// but before the start, the result is [StartsIn]; from the start until the
/// estimate ends, it's [InProgress].
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
  if (!weekdays.contains(now.weekday)) return null;

  // Built from date parts rather than by adding a Duration to midnight — see
  // ReminderSchedule.occurrences for why: that avoids landing an hour off on
  // a DST transition day.
  final start = DateTime(now.year, now.month, now.day, time.$1, time.$2);
  final windowStart = start.subtract(lead);
  final windowEnd = start.add(estimate);

  if (now.isBefore(windowStart)) return null;
  if (now.isBefore(start)) return StartsIn(start.difference(now));
  if (now.isBefore(windowEnd)) return const InProgress();
  return null;
}
