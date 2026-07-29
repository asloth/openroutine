import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_preview.freezed.dart';

/// Summary of what StorageAdapter.confirmImport would actually write, per
/// docs/SPEC.md §10's "preview screen (X routines, Y steps to add/update)".
/// Not schema-backed and never serialized — internal to the import flow.
@freezed
abstract class ImportPreview with _$ImportPreview {
  const factory ImportPreview({
    required int newRoutines,
    required int updatedRoutines,
    required int newSteps,
    required int updatedSteps,
    required int newTriggers,
    required int updatedTriggers,
  }) = _ImportPreview;

  const ImportPreview._();

  bool get isEmpty =>
      newRoutines == 0 &&
      updatedRoutines == 0 &&
      newSteps == 0 &&
      updatedSteps == 0 &&
      newTriggers == 0 &&
      updatedTriggers == 0;
}
