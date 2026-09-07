import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Imported for the enums drift's generated part file references in its
// textEnum() column converters, not for anything in this file's own body.
import '../../../models/completion_log.dart';
import '../../../models/schedule.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Routines, RoutineSteps, Triggers, CompletionLogs, SyncState],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// v2 (M3) added [CompletionLogs]; v3 (M4) added [SyncState]; v4 adds
  /// the additive Low Mode core-step marker; v5 records Low Mode run evidence;
  /// v6 adds the additive per-step mid-step reminder opt-in.
  /// Bump this and
  /// add an `onUpgrade` branch for every schema change — installs from M2
  /// carry real user routines, so dropping and recreating is not an option.
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(completionLogs);
      }
      if (from < 3) {
        await m.createTable(syncState);
      }
      if (from < 4) {
        await m.addColumn(routineSteps, routineSteps.isCore);
      }
      if (from >= 2 && from < 5) {
        await m.addColumn(completionLogs, completionLogs.mode);
        await m.addColumn(completionLogs, completionLogs.plannedStepIdsJson);
      }
      if (from < 6) {
        await m.addColumn(routineSteps, routineSteps.remindDuring);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'openroutine');
  }
}
