import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'step.freezed.dart';
part 'step.g.dart';

/// Named `RoutineStep`, not `Step` — `package:flutter/material.dart` (which
/// nearly every screen imports) already exports a `Step` class used by the
/// `Stepper` widget. Matches schemas/step.schema.json field-for-field; the
/// `duration_seconds` null-iff-`no_explicit_time` constraint is enforced by
/// the step form UI and by schema_validator.dart on import, not here — this
/// class is a plain data container.
@freezed
abstract class RoutineStep with _$RoutineStep {
  const factory RoutineStep({
    required String id,
    required String routineId,
    required String name,
    required String emoji,
    required int? durationSeconds,
    required int order,
    required bool noExplicitTime,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
    @NullableUtcDateTimeConverter() DateTime? deletedAt,
  }) = _RoutineStep;

  factory RoutineStep.fromJson(Map<String, dynamic> json) =>
      _$RoutineStepFromJson(json);
}
