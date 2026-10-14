import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/step.dart';
import '../services/stats/routine_statistics.dart';
import '../services/stats/stats_period.dart';
import 'routines_provider.dart';
import 'storage_provider.dart';

part 'stats_provider.g.dart';

/// How far back the streak looks.
///
/// Bounded so the query stays cheap as history grows. A streak longer than a
/// year reads as a year, which is still the right message.
const streakWindow = Duration(days: 365);

/// The current streak, counted back from today.
///
/// Separate from [statistics] because the streak never depends on which
/// period the screen shows: viewing last month mustn't read as a streak of
/// zero today.
@riverpod
Future<int> streakDays(Ref ref) async {
  final storage = ref.watch(storageAdapterProvider);
  final now = DateTime.now();
  final logs = await storage.completionsInRange(
    now.toUtc().subtract(streakWindow),
    // Exclusive upper bound, nudged past now so a run finishing this instant
    // is included rather than sitting just outside the window.
    now.toUtc().add(const Duration(days: 1)),
  );
  return currentStreak(logs: logs, now: now);
}

/// Everything the statistics screen reports for [period], computed on demand.
///
/// Reads through [storageAdapterProvider] rather than reaching for the local
/// adapter directly: whichever adapter is configured is the one that knows
/// what this user's records are, and bypassing it would make statistics
/// silently wrong for anyone syncing with Drive.
@riverpod
Future<RoutineStatistics> statistics(Ref ref, StatsPeriod period) async {
  final storage = ref.watch(storageAdapterProvider);
  final now = DateTime.now();

  final (:start, :end) = period.range;
  final logs = await storage.completionsInRange(
    // All time reaches back to the first possible run.
    start?.toUtc() ?? DateTime.utc(1970),
    end?.toUtc() ?? now.toUtc().add(const Duration(days: 1)),
  );

  // Steps are needed to turn identifiers into names. A step that no longer
  // exists is dropped by the aggregation rather than shown raw.
  final routines = await ref.watch(routinesProvider.future);
  final stepsById = <String, RoutineStep>{};
  for (final routine in routines) {
    for (final step in await storage.getSteps(routine.id)) {
      stepsById[step.id] = step;
    }
  }

  return computeStatistics(
    logs: logs,
    stepsById: stepsById,
    currentStreakDays: await ref.watch(streakDaysProvider.future),
  );
}
