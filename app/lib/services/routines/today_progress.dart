/// One run of a routine, reduced to what today's progress needs. [startedAt]
/// is local time.
typedef RunRecord = ({DateTime startedAt, bool completed, int stepsDone});

/// How far a routine got today, shown on its home card.
sealed class TodayProgress {
  const TodayProgress();
}

/// A run finished today.
class DoneToday extends TodayProgress {
  const DoneToday();
}

/// The latest run today stopped after [done] of [total] steps.
class PartwayToday extends TodayProgress {
  const PartwayToday(this.done, this.total);

  final int done;
  final int total;
}

/// Decides a routine's progress for the local day containing [now], or `null`
/// when there's nothing to show.
///
/// A finished run always wins, even over a later stopped one: once you've
/// done the routine today, starting it again and stopping doesn't undo that.
/// Otherwise the latest stopped run counts, as long as it got through at
/// least one step. Pure, so a fake [now] keeps it deterministic.
TodayProgress? todayProgress(
  Iterable<RunRecord> runs, {
  required DateTime now,
  required int stepCount,
}) {
  bool isToday(DateTime t) =>
      t.year == now.year && t.month == now.month && t.day == now.day;

  final today = runs.where((run) => isToday(run.startedAt)).toList();
  if (today.any((run) => run.completed)) return const DoneToday();
  if (today.isEmpty) return null;

  final latest = today.reduce(
    (a, b) => b.startedAt.isAfter(a.startedAt) ? b : a,
  );
  if (latest.stepsDone <= 0) return null;
  return PartwayToday(latest.stepsDone.clamp(0, stepCount), stepCount);
}
