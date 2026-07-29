import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'trigger.freezed.dart';
part 'trigger.g.dart';

/// Only `manual` is created or accepted in schema v1. docs/SPEC.md §4
/// reserves `time`/`location`/`calendar_event` for v2 — not modeled yet,
/// since nothing in M2 produces or consumes them.
enum TriggerKind { manual }

@freezed
abstract class Trigger with _$Trigger {
  const factory Trigger({
    required String id,
    required String name,
    required TriggerKind kind,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Trigger;

  factory Trigger.fromJson(Map<String, dynamic> json) =>
      _$TriggerFromJson(json);
}
