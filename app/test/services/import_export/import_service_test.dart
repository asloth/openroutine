import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/import_export/import_service.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';
import 'package:openroutine/services/schema_version.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImportService service;
  late LocalAdapter adapter;

  setUpAll(() async {
    final validator = await SchemaValidator.load();
    adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    service = ImportService(adapter, validator);
  });

  String bundleExportedAt(String exportedAt) =>
      '''
    {
      "schema_version": "1.0.0",
      "exported_at": $exportedAt,
      "routines": [],
      "steps": [],
      "triggers": []
    }
    ''';

  test('malformed JSON throws ImportException(invalidJson), not a crash', () {
    expect(
      () => service.validateJsonString('{not valid json'),
      throwsA(
        isA<ImportException>().having(
          (e) => e.reason,
          'reason',
          ImportFailureReason.invalidJson,
        ),
      ),
    );
  });

  for (final entry in {
    'array': '[]',
    'null': 'null',
    'string': '"text"',
    'number': '42',
    'boolean': 'true',
  }.entries) {
    test(
      'valid JSON ${entry.key} root throws ImportException(invalidJson)',
      () {
        expect(
          () => service.validateJsonString(entry.value),
          throwsA(
            isA<ImportException>().having(
              (e) => e.reason,
              'reason',
              ImportFailureReason.invalidJson,
            ),
          ),
        );
      },
    );
  }

  test(
    'valid JSON that violates the schema throws ImportException(schemaViolation)',
    () {
      expect(
        () => service.validateJsonString('{"schema_version": "1.0.0"}'),
        throwsA(
          isA<ImportException>().having(
            (e) => e.reason,
            'reason',
            ImportFailureReason.schemaViolation,
          ),
        ),
      );
    },
  );

  test('a malformed date-time is a schema violation, not a crash', () {
    expect(
      () => service.validateJsonString(bundleExportedAt('"yesterday"')),
      throwsA(
        isA<ImportException>().having(
          (e) => e.reason,
          'reason',
          ImportFailureReason.schemaViolation,
        ),
      ),
    );
  });

  test('a bundle this build exported still validates', () async {
    await adapter.saveRoutine(
      Routine(
        id: '019c0000-0000-7000-8000-00000000000a',
        name: 'Morning',
        schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
        stepIds: const [],
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        deletedAt: null,
      ),
    );
    final exported = jsonEncode(
      await adapter.exportAll().then((b) => b.toJson()),
    );

    final bundle = service.validateJsonString(exported);
    expect(bundle.routines.single.name, 'Morning');
  });

  test('a value the schema lets through is reported, not thrown raw', () {
    // Nothing in the export schema can express every constraint the models
    // apply, so the parse boundary has to hold on its own. A schema that
    // accepts anything is how you see it holding.
    final permissive = SchemaValidator.forTesting(JsonSchema.create(true));
    final unguarded = ImportService(adapter, permissive);

    expect(
      () => unguarded.validateJsonString(bundleExportedAt('"yesterday"')),
      throwsA(
        isA<ImportException>().having(
          (e) => e.reason,
          'reason',
          ImportFailureReason.schemaViolation,
        ),
      ),
    );
  });

  test('a value outside a model enum is reported, not thrown raw', () {
    // An unknown enum value throws ArgumentError rather than FormatException,
    // so it has a catch clause of its own at the parse boundary.
    final permissive = SchemaValidator.forTesting(JsonSchema.create(true));
    final unguarded = ImportService(adapter, permissive);
    const unknownMode = '''
    {
      "schema_version": "2.0.0",
      "exported_at": "2026-01-01T00:00:00Z",
      "routines": [{
        "id": "019c0000-0000-7000-8000-000000000001",
        "name": "Morning",
        "schedule": {"mode": "sometimes", "days": []},
        "step_ids": [],
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-01T00:00:00Z"
      }],
      "steps": []
    }
    ''';

    expect(
      () => unguarded.validateJsonString(unknownMode),
      throwsA(
        isA<ImportException>().having(
          (e) => e.reason,
          'reason',
          ImportFailureReason.schemaViolation,
        ),
      ),
    );
  });

  test('a schema version too large to parse is newer, not a crash', () async {
    // The schema bounds the version's shape but not its digits, so this gets
    // past validation. Previewing it has to end in the screen's "newer
    // version" answer rather than a raw FormatException.
    final bundle = service.validateJsonString('''
    {
      "schema_version": "99999999999999999999.0.0",
      "exported_at": "2026-01-01T00:00:00Z",
      "routines": [],
      "steps": []
    }
    ''');

    await expectLater(
      service.preview(bundle),
      throwsA(
        isA<UnsupportedSchemaVersionException>().having(
          (e) => e.isNewer,
          'isNewer',
          isTrue,
        ),
      ),
    );
  });

  test('a fully valid export bundle parses into an ExportBundle', () {
    const validJson = '''
    {
      "schema_version": "1.0.0",
      "exported_at": "2026-01-01T00:00:00Z",
      "routines": [],
      "steps": [],
      "triggers": []
    }
    ''';
    final bundle = service.validateJsonString(validJson);
    expect(bundle.schemaVersion, '1.0.0');
    expect(bundle.routines, isEmpty);
  });

  test('a 1.2.0 export with moments imports and drops them', () {
    const withMoments = '''
    {
      "schema_version": "1.2.0",
      "exported_at": "2026-01-01T00:00:00Z",
      "routines": [{
        "id": "019c0000-0000-7000-8000-000000000001",
        "name": "Morning",
        "trigger_id": "019c0000-0000-7000-8000-000000000009",
        "schedule": {"mode": "scheduled", "days": ["mon"], "start_time": "07:00"},
        "step_ids": [],
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-01T00:00:00Z"
      }],
      "steps": [],
      "triggers": [{
        "id": "019c0000-0000-7000-8000-000000000009",
        "name": "Waking up",
        "kind": "manual",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-01T00:00:00Z"
      }]
    }
    ''';

    final bundle = service.validateJsonString(withMoments);
    expect(bundle.routines.single.name, 'Morning');
    expect(bundle.toJson().containsKey('triggers'), isFalse);
    expect(bundle.routines.single.toJson().containsKey('trigger_id'), isFalse);
  });

  test('legacy 1.0 data defaults every additive ADHD-supportive field', () {
    const legacyExport = '''
    {
      "schema_version": "1.0.0",
      "exported_at": "2026-01-01T00:00:00Z",
      "routines": [{
        "id": "019c0000-0000-7000-8000-000000000001",
        "name": "Morning",
        "trigger_id": null,
        "schedule": {"mode": "flexible", "days": []},
        "step_ids": ["019c0000-0000-7000-8000-000000000002"],
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-01T00:00:00Z"
      }],
      "steps": [{
        "id": "019c0000-0000-7000-8000-000000000002",
        "routine_id": "019c0000-0000-7000-8000-000000000001",
        "name": "Brush teeth",
        "emoji": "🪥",
        "duration_seconds": 120,
        "order": 0,
        "no_explicit_time": false,
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-01T00:00:00Z"
      }],
      "triggers": []
    }
    ''';

    final bundle = service.validateJsonString(legacyExport);
    expect(bundle.steps.single.isCore, isFalse);

    final legacyRun = CompletionLog.fromJson({
      'id': 'c1',
      'routine_id': 'r1',
      'started_at': '2026-01-01T08:00:00Z',
      'ended_at': '2026-01-01T08:02:00Z',
      'outcome': 'completed',
      'steps': [
        {'step_id': 's1', 'state': 'completed', 'actual_duration_seconds': 120},
      ],
    });
    expect(legacyRun.mode, RunMode.full);
    expect(legacyRun.plannedStepIds, isEmpty);
    expect(legacyRun.steps.single.estimatedDurationSeconds, isNull);
  });
}
