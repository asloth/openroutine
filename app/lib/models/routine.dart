import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';
import 'schedule.dart';

part 'routine.freezed.dart';
part 'routine.g.dart';

/// Matches schemas/routine.schema.json. `stepIds` is derived from the Steps
/// table at read/export time (ordered by RoutineStep.order) rather than
/// stored redundantly — see LocalAdapter.
@freezed
abstract class Routine with _$Routine {
  const factory Routine({
    required String id,
    required String name,
    required String? triggerId,
    required Schedule schedule,
    required List<String> stepIds,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
    @NullableUtcDateTimeConverter() DateTime? deletedAt,
  }) = _Routine;

  factory Routine.fromJson(Map<String, dynamic> json) =>
      _$RoutineFromJson(json);
}
