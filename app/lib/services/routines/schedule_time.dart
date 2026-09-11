import '../../models/schedule.dart';

/// Shared date maths for [Schedule]: parsing its "HH:MM" start time and
/// mapping [DayOfWeek] onto [DateTime]'s weekday numbering.
///
/// Extracted out of `ReminderSchedule`, which had both privately, so
/// `upcoming.dart` can reuse the exact same parsing and mapping instead of
/// keeping a second copy that could drift from it.
abstract final class ScheduleTime {
  /// "HH:MM" per schemas/routine.schema.json, as (hour, minute). Anything
  /// malformed — including a value an agent wrote by hand — yields null so
  /// the caller simply treats the routine as having no start time.
  static (int, int)? parseStartTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  static int weekday(DayOfWeek day) => switch (day) {
    DayOfWeek.mon => DateTime.monday,
    DayOfWeek.tue => DateTime.tuesday,
    DayOfWeek.wed => DateTime.wednesday,
    DayOfWeek.thu => DateTime.thursday,
    DayOfWeek.fri => DateTime.friday,
    DayOfWeek.sat => DateTime.saturday,
    DayOfWeek.sun => DateTime.sunday,
  };
}
