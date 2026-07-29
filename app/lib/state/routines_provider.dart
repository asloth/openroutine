import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/routine.dart';
import '../models/step.dart';
import '../models/trigger.dart';
import 'storage_provider.dart';

part 'routines_provider.g.dart';

@riverpod
Stream<List<Routine>> routines(Ref ref) {
  return ref.watch(storageAdapterProvider).watchRoutines();
}

@riverpod
Future<List<Trigger>> triggers(Ref ref) {
  return ref.watch(storageAdapterProvider).getTriggers();
}

@riverpod
Future<Routine?> routine(Ref ref, String routineId) {
  return ref.watch(storageAdapterProvider).getRoutine(routineId);
}

@riverpod
Future<List<RoutineStep>> routineSteps(Ref ref, String routineId) {
  return ref.watch(storageAdapterProvider).getSteps(routineId);
}

@riverpod
Future<RoutineStep?> step(Ref ref, String routineId, String stepId) async {
  final steps = await ref.watch(routineStepsProvider(routineId).future);
  for (final step in steps) {
    if (step.id == stepId) return step;
  }
  return null;
}
