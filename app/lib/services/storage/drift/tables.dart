import 'package:drift/drift.dart';

import '../../../models/schedule.dart';

/// Comma-joined list of [DayOfWeek] enum names, e.g. "mon,tue,wed". Simpler
/// than JSON for a short list of fixed tokens with no embedded commas.
class DayListConverter extends TypeConverter<List<DayOfWeek>, String> {
  const DayListConverter();

  @override
  List<DayOfWeek> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return fromDb
        .split(',')
        .map((name) => DayOfWeek.values.byName(name))
        .toList();
  }

  @override
  String toSql(List<DayOfWeek> value) => value.map((day) => day.name).join(',');
}

/// Routine metadata. `step_ids` from schemas/routine.schema.json is
/// deliberately NOT a column here — it's derived by querying [RoutineSteps]
/// ordered by `order`, so the two can never drift apart. `Schedule` is
/// flattened into scheduleMode/scheduleDays/scheduleStartTime columns.
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get triggerId => text().nullable().references(Triggers, #id)();
  TextColumn get scheduleMode => textEnum<ScheduleMode>()();
  TextColumn get scheduleDays =>
      text().map(const DayListConverter()).withDefault(const Constant(''))();
  TextColumn get scheduleStartTime => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Matches schemas/step.schema.json. Named RoutineSteps (not Steps) to
/// mirror the RoutineStep domain model naming — see models/step.dart for
/// why "Step" alone collides with Flutter's Stepper widget.
class RoutineSteps extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get emoji => text()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get order => integer()();
  BoolColumn get noExplicitTime => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Matches schemas/trigger.schema.json.
class Triggers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get kind => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
