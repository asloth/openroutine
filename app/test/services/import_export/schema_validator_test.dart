import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';

Map<String, dynamic> _validBundle() => {
  'schema_version': '1.0.0',
  'exported_at': '2026-01-01T00:00:00Z',
  'routines': [
    {
      'id': '018f1a2b-3c4d-7e5f-89ab-1234567890ab',
      'name': 'Morning Routine',
      'trigger_id': null,
      'schedule': {
        'mode': 'scheduled',
        'days': ['mon', 'tue'],
        'start_time': '07:00',
      },
      'step_ids': ['018f1a2b-3c4d-7e5f-89ab-1234567890ac'],
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    },
  ],
  'steps': [
    {
      'id': '018f1a2b-3c4d-7e5f-89ab-1234567890ac',
      'routine_id': '018f1a2b-3c4d-7e5f-89ab-1234567890ab',
      'name': 'Brush my teeth',
      'emoji': '🪥',
      'duration_seconds': 180,
      'order': 0,
      'no_explicit_time': false,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    },
  ],
  'triggers': <Map<String, dynamic>>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemaValidator validator;

  setUpAll(() async {
    validator = await SchemaValidator.load();
  });

  test('a schema-conformant bundle passes without throwing', () {
    expect(
      () => validator.validateExportBundle(_validBundle()),
      returnsNormally,
    );
  });

  test(
    'cross-file \$ref actually resolves: a bad nested step is caught, not silently accepted',
    () {
      final bundle = _validBundle();
      final badStep = Map<String, dynamic>.from(
        (bundle['steps'] as List).first as Map,
      );
      badStep['no_explicit_time'] = true;
      badStep['duration_seconds'] = 60;
      bundle['steps'] = [badStep];

      expect(
        () => validator.validateExportBundle(bundle),
        throwsA(isA<SchemaValidationException>()),
      );
    },
  );

  test(
    'a structurally invalid bundle (missing required field) is rejected with a clear error, not a crash',
    () {
      final bundle = _validBundle()..remove('schema_version');

      expect(
        () => validator.validateExportBundle(bundle),
        throwsA(
          isA<SchemaValidationException>().having(
            (e) => e.errors,
            'errors',
            isNotEmpty,
          ),
        ),
      );
    },
  );

  test(
    'assets/schemas/ is byte-identical to the repo-root schemas/ — the bundled copy must never drift',
    () {
      // schema_validator.dart validates against the bundled asset copy, but
      // schemas/*.json at the repo root is the documented public API
      // (docs/SPEC.md §13). If someone edits one without the other, the app
      // silently validates against a stale or wrong schema.
      const fileNames = [
        'routine.schema.json',
        'step.schema.json',
        'trigger.schema.json',
        'completion.schema.json',
        'export.schema.json',
      ];
      for (final fileName in fileNames) {
        final bundled = File('assets/schemas/$fileName').readAsStringSync();
        final source = File('../schemas/$fileName').readAsStringSync();
        expect(
          bundled,
          equals(source),
          reason:
              '$fileName differs between assets/schemas/ and the repo-root schemas/',
        );
      }
    },
  );
}
