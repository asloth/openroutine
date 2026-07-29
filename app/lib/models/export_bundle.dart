import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';
import 'routine.dart';
import 'step.dart';
import 'trigger.dart';

part 'export_bundle.freezed.dart';
part 'export_bundle.g.dart';

/// Matches schemas/export.schema.json — the shared top-level shape for
/// Drive's routines.json and for Import/Export files (docs/SPEC.md §10).
/// A single-routine export is the same shape with one entry in `routines`
/// plus its referenced steps and trigger.
@freezed
abstract class ExportBundle with _$ExportBundle {
  const factory ExportBundle({
    required String schemaVersion,
    @UtcDateTimeConverter() required DateTime exportedAt,
    required List<Routine> routines,
    required List<RoutineStep> steps,
    required List<Trigger> triggers,
  }) = _ExportBundle;

  factory ExportBundle.fromJson(Map<String, dynamic> json) =>
      _$ExportBundleFromJson(json);
}
