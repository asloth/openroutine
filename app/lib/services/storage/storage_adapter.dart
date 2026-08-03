import '../../models/completion_log.dart';
import '../../models/export_bundle.dart';
import '../../models/import_preview.dart';
import '../../models/routine.dart';
import '../../models/step.dart';
import '../../models/trigger.dart';

/// Pure domain-facing storage interface — no Drift or Drive types in this
/// signature (docs/SPEC.md §13). LocalAdapter is the only implementation in
/// M2; DriveAdapter (M4) implements the same interface so screens never
/// change when Drive support lands.
///
/// saveRoutine/saveStep persist the record exactly as given, including
/// `updatedAt` — they do NOT bump it. Callers editing via the UI must bump
/// `updatedAt` themselves before calling save (see `nowUtc()`). This is
/// deliberate: confirmImport also goes through these same methods and must
/// preserve each incoming record's own `updatedAt` to make its
/// last-writer-wins comparison meaningful (docs/SPEC.md §5).
abstract class StorageAdapter {
  Stream<List<Routine>> watchRoutines();
  Future<Routine?> getRoutine(String id);
  Future<List<RoutineStep>> getSteps(String routineId);
  Future<List<Trigger>> getTriggers();

  Future<void> saveRoutine(Routine routine);
  Future<void> saveStep(RoutineStep step);
  Future<void> saveTrigger(Trigger trigger);

  /// Soft delete: sets deleted_at (and bumps updated_at) rather than
  /// removing the row — see docs/SPEC.md §5.
  Future<void> deleteRoutine(String id);
  Future<void> deleteStep(String id);

  /// Append-only, per docs/SPEC.md §4 — there is deliberately no update or
  /// delete counterpart. M4 turns each record into one line of
  /// `completions/YYYY-MM.ndjson`, a format whose concurrent-append safety
  /// depends on records never being rewritten (docs/SPEC.md §5).
  Future<void> appendCompletion(CompletionLog log);

  /// Newest first. [since] is inclusive and compared against `startedAt`;
  /// pass it to avoid loading a routine's entire history for the 7-day dots.
  Future<List<CompletionLog>> getCompletions(String routineId, {DateTime? since});

  Future<ExportBundle> exportAll();
  Future<ExportBundle> exportRoutine(String id);

  /// Dry-runs the same last-writer-wins merge confirmImport would perform,
  /// without writing anything — so the preview screen (docs/SPEC.md §10)
  /// exactly matches what confirming will do.
  Future<ImportPreview> previewImport(ExportBundle bundle);
  Future<void> confirmImport(ExportBundle bundle);
}

/// Current UTC instant, truncated to the precision the JSON schemas expect.
/// Call sites bump `updatedAt` with this before calling save*() after a user
/// edit — see StorageAdapter's doc comment above for why the adapter itself
/// doesn't do this.
DateTime nowUtc() => DateTime.now().toUtc();
