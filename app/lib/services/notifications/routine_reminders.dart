import '../../models/routine.dart';
import '../../models/schedule.dart';

/// One reminder to hand to the OS: an absolute local instant and the routine
/// it belongs to.
class ReminderRequest {
  const ReminderRequest({
    required this.notificationId,
    required this.routineId,
    required this.at,
    required this.title,
    required this.body,
  });

  final int notificationId;
  final String routineId;

  /// Local wall-clock time. Converted to an absolute instant at the moment of
  /// scheduling — see [ReminderSchedule] for why it is computed this way.
  final DateTime at;

  final String title;
  final String body;
}

/// Works out *when* a routine's reminders should fire. Pure date maths, no
/// plugin and no I/O, which is the whole reason it lives apart from
/// `NotificationService`.
///
/// **Why a rolling window of absolute instants rather than a repeating
/// alarm.** `flutter_local_notifications` can repeat daily via
/// `matchDateTimeComponents`, but that anchors to a fixed instant in whatever
/// zone the plugin's database is set to. This app deliberately leaves
/// `tz.local` at UTC (see `NotificationService.scheduleStepAlarms`) because
/// every other schedule it has is an offset from now, so a repeating match would
/// fire an hour off for half the year in any zone that observes DST. Pinning
/// that would mean adding `flutter_timezone` to a dependency graph that is
/// already awkward to resolve on this Flutter version.
///
/// Recomputing the next few days from *local* wall-clock time on every app
/// start sidesteps all of it: each occurrence is built as a local `DateTime`
/// and converted at scheduling time, so a DST boundary inside the window is
/// handled by the platform's own calendar rather than by us.
abstract final class ReminderSchedule {
  /// How far ahead to schedule. The window is re-armed whenever the routine
  /// list changes or the app is opened, so it only has to outlast a stretch of
  /// not opening the app.
  static const horizonDays = 7;

  /// iOS keeps at most 64 pending local notifications and silently drops the
  /// rest, so the total is capped well under that with room left for the
  /// timer's own three step notifications — the estimate boundary and the two
  /// mid-step nudges.
  static const maxReminders = 56;

  /// First id reserved for reminders. Kept clear of the timer's step ids
  /// (`NotificationService.stepEndNotificationId` and its two nudge
  /// siblings) so re-arming reminders can never cancel a running timer's
  /// pending notifications.
  static const idBase = 1000;

  /// The next reminder instants for [routine], already moved back by [lead].
  ///
  /// Empty for a flexible routine, one with no days, or one whose start time
  /// is missing or malformed — a routine with nothing to fire on is a normal
  /// state here, not an error.
  static List<DateTime> occurrences(
    Routine routine, {
    required DateTime now,
    Duration lead = Duration.zero,
    int horizon = horizonDays,
  }) {
    if (routine.schedule.mode != ScheduleMode.scheduled) return const [];
    if (routine.schedule.days.isEmpty) return const [];

    final time = _parseStartTime(routine.schedule.startTime);
    if (time == null) return const [];

    final weekdays = routine.schedule.days.map(_weekday).toSet();
    final today = DateTime(now.year, now.month, now.day);
    final result = <DateTime>[];

    // Starts at day 0 so today still counts if its reminder has not passed,
    // and runs one day past the horizon so a lead time that pushes an
    // occurrence back across midnight is not silently lost.
    for (var offset = 0; offset <= horizon; offset++) {
      final day = today.add(Duration(days: offset));
      if (!weekdays.contains(day.weekday)) continue;

      // Built from date parts rather than by adding a Duration: adding hours
      // to midnight lands an hour off on a DST transition day, whereas the
      // constructor resolves the wall-clock time the user actually meant.
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        time.$1,
        time.$2,
      );
      final at = start.subtract(lead);
      if (at.isAfter(now)) result.add(at);
    }

    result.sort();
    return result;
  }

  /// Flattens every routine's occurrences into one id-assigned list.
  ///
  /// Ids are handed out by position rather than derived from the routine id.
  /// Re-arming always cancels the whole reserved range first, so there is
  /// nothing to keep stable between runs, and position-based ids cannot
  /// collide the way a hash of a UUID could.
  static List<ReminderRequest> build({
    required List<Routine> routines,
    required DateTime now,
    required Duration lead,
    required String Function(Routine routine) title,
    required String Function(Routine routine, Duration lead) body,
    int horizon = horizonDays,
    int limit = maxReminders,
  }) {
    final pending = <(DateTime, Routine)>[];
    for (final routine in routines) {
      for (final at in occurrences(
        routine,
        now: now,
        lead: lead,
        horizon: horizon,
      )) {
        pending.add((at, routine));
      }
    }

    // Soonest first, so if the cap bites it drops the furthest-out reminders
    // rather than an arbitrary routine's.
    pending.sort((a, b) => a.$1.compareTo(b.$1));

    final requests = <ReminderRequest>[];
    for (final (at, routine) in pending.take(limit)) {
      requests.add(
        ReminderRequest(
          notificationId: idBase + requests.length,
          routineId: routine.id,
          at: at,
          title: title(routine),
          body: body(routine, lead),
        ),
      );
    }
    return requests;
  }

  /// "HH:MM" per schemas/routine.schema.json, as (hour, minute). Anything
  /// malformed — including a value an agent wrote by hand — yields null so the
  /// routine simply gets no reminder.
  static (int, int)? _parseStartTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  static int _weekday(DayOfWeek day) => switch (day) {
    DayOfWeek.mon => DateTime.monday,
    DayOfWeek.tue => DateTime.tuesday,
    DayOfWeek.wed => DateTime.wednesday,
    DayOfWeek.thu => DateTime.thursday,
    DayOfWeek.fri => DateTime.friday,
    DayOfWeek.sat => DateTime.saturday,
    DayOfWeek.sun => DateTime.sunday,
  };
}
