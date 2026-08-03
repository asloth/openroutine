import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Schema v1 → v2, the migration M3 added when it introduced `completion_logs`.
///
/// This matters more than the usual test: every install so far has been a clean
/// one, because `flutter install` uninstalls first and wipes app data. That
/// means the branch protecting a real user's routines during an upgrade has
/// never actually executed on a device. The only way to exercise it is to build
/// a v1 database deliberately, which is what this file does.
///
/// The v1 DDL below is written by hand rather than generated. drift builds its
/// schema at runtime, so there is no v1 SQL left in the repo to point at — it
/// only exists in the shape of `tables.dart` as of commit e5fd887~1. If a
/// future migration changes these three tables, this DDL stays frozen at v1;
/// it describes history, not the current model.
const _v1Ddl = [
  '''
  CREATE TABLE triggers (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (id)
  )''',
  '''
  CREATE TABLE routines (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    trigger_id TEXT REFERENCES triggers (id),
    schedule_mode TEXT NOT NULL,
    schedule_days TEXT NOT NULL DEFAULT '',
    schedule_start_time TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    PRIMARY KEY (id)
  )''',
  // "order" is quoted because it is a SQL keyword — the same reason drift
  // quotes it in the generated schema.
  '''
  CREATE TABLE routine_steps (
    id TEXT NOT NULL,
    routine_id TEXT NOT NULL REFERENCES routines (id),
    name TEXT NOT NULL,
    emoji TEXT NOT NULL,
    duration_seconds INTEGER,
    "order" INTEGER NOT NULL,
    no_explicit_time INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    PRIMARY KEY (id)
  )''',
];

/// drift stores DateTime as unix **seconds** by default, not milliseconds.
int _epoch(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

final _createdAt = DateTime.utc(2026, 7, 29, 12);

/// A v1 database holding one routine, two steps and a trigger — the shape an
/// M2 install would have on disk before upgrading.
sqlite.Database _seedV1Database() {
  final db = sqlite.sqlite3.openInMemory();
  for (final statement in _v1Ddl) {
    db.execute(statement);
  }

  db.execute(
    'INSERT INTO triggers (id, name, kind, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?)',
    ['t1', 'alarm', 'manual', _epoch(_createdAt), _epoch(_createdAt)],
  );
  db.execute(
    'INSERT INTO routines (id, name, trigger_id, schedule_mode, '
    'schedule_days, schedule_start_time, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      'r1',
      'morning',
      't1',
      'scheduled',
      'mon,tue,wed',
      '07:20',
      _epoch(_createdAt),
      _epoch(_createdAt),
    ],
  );
  for (final (index, step) in [
    ('s1', 'Brush my teeth', 180),
    ('s2', 'Shower', 300),
  ].indexed) {
    db.execute(
      'INSERT INTO routine_steps (id, routine_id, name, emoji, '
      'duration_seconds, "order", no_explicit_time, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        step.$1,
        'r1',
        step.$2,
        '🪥',
        step.$3,
        index,
        0,
        _epoch(_createdAt),
        _epoch(_createdAt),
      ],
    );
  }

  // What tells drift there is a migration to run at all.
  db.execute('PRAGMA user_version = 1');
  return db;
}

void main() {
  late sqlite.Database raw;
  late AppDatabase db;
  late LocalAdapter adapter;

  setUp(() {
    raw = _seedV1Database();
    db = AppDatabase(NativeDatabase.opened(raw));
    adapter = LocalAdapter(db);
  });

  tearDown(() => db.close());

  test('a v1 database reports schema version 1 before being opened', () {
    // Guards the test itself: if this ever reads 2, the fixture is no longer
    // a v1 database and everything below would pass vacuously.
    expect(raw.userVersion, 1);
  });

  test('opening a v1 database upgrades it to v2', () async {
    // Any query forces drift to run the migration.
    await adapter.getRoutine('r1');
    expect(raw.userVersion, 2);
  });

  test('routines survive the upgrade intact', () async {
    final routine = await adapter.getRoutine('r1');

    expect(routine, isNotNull);
    expect(routine!.name, 'morning');
    expect(routine.triggerId, 't1');
    expect(routine.schedule.startTime, '07:20');
    expect(routine.schedule.days.map((d) => d.name), ['mon', 'tue', 'wed']);
    // stepIds are derived from routine_steps, so this also proves the child
    // rows came across in the right order.
    expect(routine.stepIds, ['s1', 's2']);
  });

  test('steps survive the upgrade intact', () async {
    final steps = await adapter.getSteps('r1');

    expect(steps.map((s) => s.name), ['Brush my teeth', 'Shower']);
    expect(steps.map((s) => s.durationSeconds), [180, 300]);
    expect(steps.every((s) => s.noExplicitTime == false), isTrue);
    expect(steps.first.emoji, '🪥');
  });

  test('triggers survive the upgrade intact', () async {
    final triggers = await adapter.getTriggers();

    expect(triggers, hasLength(1));
    expect(triggers.single.name, 'alarm');
  });

  test('the completion_logs table the upgrade adds is usable', () async {
    // The whole point of v2. Writing to it proves onUpgrade created the table
    // rather than the migration silently doing nothing.
    await adapter.appendCompletion(
      CompletionLog(
        id: 'c1',
        routineId: 'r1',
        startedAt: DateTime.utc(2026, 8, 2, 9),
        endedAt: DateTime.utc(2026, 8, 2, 9, 10),
        outcome: CompletionOutcome.completed,
        steps: const [
          CompletionStep(
            stepId: 's1',
            state: CompletionStepState.completed,
            actualDurationSeconds: 170,
          ),
        ],
      ),
    );

    final logs = await adapter.getCompletions('r1');
    expect(logs.single.steps.single.stepId, 's1');
  });

  test('a v1 install can still export everything after upgrading', () async {
    // Export walks every table, so it fails loudly if the migration left the
    // database in a shape the adapter can't read end to end.
    final bundle = await adapter.exportAll();

    expect(bundle.routines, hasLength(1));
    expect(bundle.steps, hasLength(2));
    expect(bundle.triggers, hasLength(1));
  });
}
