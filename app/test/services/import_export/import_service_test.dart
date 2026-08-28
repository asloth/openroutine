import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/services/import_export/import_service.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ImportService service;

  setUpAll(() async {
    final validator = await SchemaValidator.load();
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    service = ImportService(adapter, validator);
  });

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
