import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/step.dart';
import '../services/stats/routine_statistics.dart';
import 'routines_provider.dart';
import 'storage_provider.dart';

part 'stats_provider.g.dart';

/// How far back the statistics screen looks.
///
/// Bounded rather than unbounded so the query stays cheap as history grows,
/// and because a streak or a skip count from two years ago is not what anyone
/// opens this screen to find out.
const statsWindow = Duration(days: 365);

/// Everything the statistics screen reports, computed on demand.
///
/// Reads through [storageAdapterProvider] rather than reaching for the local
/// adapter directly: whichever adapter is configured is the one that knows
/// what this user's records are, and bypassing it would make statistics
/// silently wrong for anyone syncing with Drive.
@riverpod
Future<RoutineStatistics> statistics(Ref ref) async {
  final storage = ref.watch(storageAdapterProvider);
  final now = DateTime.now();

  final logs = await storage.completionsInRange(
    now.toUtc().subtract(statsWindow),
    // Exclusive upper bound, nudged past now so a run finishing this instant
    // is included rather than sitting just outside the window.
    now.toUtc().add(const Duration(days: 1)),
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

  return computeStatistics(logs: logs, stepsById: stepsById, now: now);
}
