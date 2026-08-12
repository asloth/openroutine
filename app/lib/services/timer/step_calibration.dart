import '../../models/completion_log.dart';
import '../../models/step.dart';
import '../storage/storage_adapter.dart';

/// A consent-bound estimate update derived from one completed timer step.
class StepCalibration {
  const StepCalibration({
    required this.stepId,
    required this.routineId,
    required this.sourceUpdatedAt,
    required this.sourceDurationSeconds,
    required this.suggestedDurationSeconds,
    required this.actualDurationSeconds,
  });

  final String stepId;
  final String routineId;
  final DateTime sourceUpdatedAt;
  final int sourceDurationSeconds;
  final int suggestedDurationSeconds;
  final int actualDurationSeconds;

  static StepCalibration? suggest(CompletionStep completion, RoutineStep step) {
    final estimate = completion.estimatedDurationSeconds;
    final difference = estimate == null
        ? null
        : (completion.actualDurationSeconds - estimate).abs();
    if (completion.state != CompletionStepState.completed ||
        estimate == null ||
        difference! < 60 ||
        difference / estimate < .25) {
      return null;
    }
    final rounded =
        (completion.actualDurationSeconds / 60).round().clamp(1, 1 << 31) * 60;
    return StepCalibration(
      stepId: completion.stepId,
      routineId: step.routineId,
      sourceUpdatedAt: step.updatedAt,
      sourceDurationSeconds: estimate,
      suggestedDurationSeconds: rounded,
      actualDurationSeconds: completion.actualDurationSeconds,
    );
  }

  /// Applies only the value the person saw and approved. A reread prevents an
  /// old summary from overwriting edits, deletes, or a changed estimate.
  Future<CalibrationApproval> approve(
    StorageAdapter adapter, {
    required DateTime updatedAt,
  }) async {
    final latest = await adapter.getSteps(routineId);
    final step = latest.where((item) => item.id == stepId).firstOrNull;
    if (step == null ||
        step.updatedAt != sourceUpdatedAt ||
        step.durationSeconds != sourceDurationSeconds) {
      return CalibrationApproval.stale;
    }
    await adapter.saveStep(
      step.copyWith(
        durationSeconds: suggestedDurationSeconds,
        updatedAt: updatedAt.toUtc(),
      ),
    );
    return CalibrationApproval.applied;
  }
}

enum CalibrationApproval { applied, stale }
