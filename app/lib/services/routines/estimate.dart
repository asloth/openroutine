import '../../models/step.dart';

/// The routine's estimated duration: the sum of `durationSeconds` over steps
/// whose `noExplicitTime` is `false`. A step opted out of an explicit time
/// contributes nothing, the same way `routine_detail_screen.dart`'s own
/// estimate line already excludes it.
Duration routineEstimate(List<RoutineStep> steps) {
  final totalSeconds = steps
      .where((step) => !step.noExplicitTime)
      .fold<int>(0, (sum, step) => sum + (step.durationSeconds ?? 0));
  return Duration(seconds: totalSeconds);
}
