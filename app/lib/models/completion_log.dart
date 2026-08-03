import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'completion_log.freezed.dart';
part 'completion_log.g.dart';

/// Matches schemas/completion.schema.json's `outcome` enum.
enum CompletionOutcome { completed, abandoned }

/// Matches schemas/completion.schema.json's `steps[].state` enum.
///
/// `overrun` means the step was finished, but took longer than its
/// `duration_seconds` — it is a completed step, not a failed one. Steps with
/// `no_explicit_time` can never be `overrun` because they have no target to
/// exceed.
enum CompletionStepState { completed, skipped, overrun }

/// One step's outcome within a single Timer Mode run.
@freezed
abstract class CompletionStep with _$CompletionStep {
  const factory CompletionStep({
    required String stepId,
    required CompletionStepState state,
    required int actualDurationSeconds,
  }) = _CompletionStep;

  factory CompletionStep.fromJson(Map<String, dynamic> json) =>
      _$CompletionStepFromJson(json);
}

/// An append-only record of a single Timer Mode run through a routine
/// (docs/SPEC.md §4). Matches schemas/completion.schema.json field-for-field.
///
/// Append-only is a real constraint, not a convention: StorageAdapter exposes
/// no update or delete for these. M4 writes each record as one line of
/// `completions/YYYY-MM.ndjson`, where multiple writers append concurrently and
/// readers dedupe by `id` (docs/SPEC.md §5) — a mutable log would break that.
@freezed
abstract class CompletionLog with _$CompletionLog {
  const factory CompletionLog({
    required String id,
    required String routineId,
    @UtcDateTimeConverter() required DateTime startedAt,
    @UtcDateTimeConverter() required DateTime endedAt,
    required CompletionOutcome outcome,
    required List<CompletionStep> steps,
  }) = _CompletionLog;

  factory CompletionLog.fromJson(Map<String, dynamic> json) =>
      _$CompletionLogFromJson(json);
}
