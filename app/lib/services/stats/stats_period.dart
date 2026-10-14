/// Which kind of stretch of time the statistics screen reports on.
enum StatsPeriodKind { week, month, allTime }

/// A half-open local range, `[start, end)`. A null end is open-ended, and a
/// null start reaches back to the first run.
typedef StatsRange = ({DateTime? start, DateTime? end});

/// One calendar week, one calendar month, or all time.
///
/// Calendar periods rather than rolling windows: "last week" means Monday to
/// Sunday (or Sunday to Saturday) to most people, and a rolling window would
/// show different runs for the same arrow press depending on today's date.
///
/// Everything is in local calendar days, matching how the streak buckets days,
/// so a run at 23:30 lands in the week you'd expect.
class StatsPeriod {
  /// The week containing [day]. [firstDayOfWeek] counts from Sunday as `0`,
  /// the way `MaterialLocalizations.firstDayOfWeekIndex` reports it.
  factory StatsPeriod.week(DateTime day, {required int firstDayOfWeek}) {
    final local = day.toLocal();
    // DateTime.weekday is Monday 1 … Sunday 7; % 7 makes Sunday 0.
    final back = (local.weekday % 7 - firstDayOfWeek) % 7;
    return StatsPeriod._(
      StatsPeriodKind.week,
      DateTime(local.year, local.month, local.day - back),
    );
  }

  /// The month containing [day].
  factory StatsPeriod.month(DateTime day) {
    final local = day.toLocal();
    return StatsPeriod._(
      StatsPeriodKind.month,
      DateTime(local.year, local.month),
    );
  }

  const StatsPeriod.allTime() : kind = StatsPeriodKind.allTime, _start = null;

  const StatsPeriod._(this.kind, this._start);

  final StatsPeriodKind kind;

  /// Local midnight on the period's first day, or null for all time.
  final DateTime? _start;

  StatsRange get range {
    final start = _start;
    if (start == null) return (start: null, end: null);
    return (start: start, end: _shift(start, 1));
  }

  /// The period before this one. All time has no neighbours.
  StatsPeriod previous() => _step(-1);

  /// The period after this one. The screen stops you at the current one.
  StatsPeriod next() => _step(1);

  /// Whether [now] falls inside this period.
  bool isCurrent(DateTime now) {
    final (:start, :end) = range;
    if (start == null || end == null) return true;
    final local = now.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  StatsPeriod _step(int by) {
    final start = _start;
    if (start == null) return this;
    return StatsPeriod._(kind, _shift(start, by));
  }

  /// Built from calendar fields rather than by adding a Duration, so a
  /// daylight saving change can't knock the start off midnight.
  DateTime _shift(DateTime start, int by) => switch (kind) {
    StatsPeriodKind.week => DateTime(start.year, start.month, start.day + 7 * by),
    StatsPeriodKind.month => DateTime(start.year, start.month + by),
    StatsPeriodKind.allTime => start,
  };

  @override
  bool operator ==(Object other) =>
      other is StatsPeriod && other.kind == kind && other._start == _start;

  @override
  int get hashCode => Object.hash(kind, _start);
}
