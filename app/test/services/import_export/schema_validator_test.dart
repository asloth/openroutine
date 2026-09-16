import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';

Map<String, dynamic> _validBundle() => {
  'schema_version': '2.0.0',
  'exported_at': '2026-01-01T00:00:00Z',
  'routines': [
    {
      'id': '018f1a2b-3c4d-7e5f-89ab-1234567890ab',
      'name': 'Morning Routine',
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
};

/// A 1.2.0 export as older builds wrote it, moments and all.
Map<String, dynamic> _legacyBundleWithMoments() {
  final bundle = _validBundle()..['schema_version'] = '1.2.0';
  (bundle['routines'] as List).first['trigger_id'] =
      '018f1a2b-3c4d-7e5f-89ab-1234567890ad';
  bundle['triggers'] = [
    {
      'id': '018f1a2b-3c4d-7e5f-89ab-1234567890ad',
      'name': 'Waking up',
      'kind': 'manual',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    },
  ];
  return bundle;
}

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

  test('a 1.2.0 export that still carries moments passes', () {
    expect(
      () => validator.validateExportBundle(_legacyBundleWithMoments()),
      returnsNormally,
    );
  });

  test('the public schemas no longer describe moments', () {
    expect(File('../schemas/trigger.schema.json').existsSync(), isFalse);
    expect(File('assets/schemas/trigger.schema.json').existsSync(), isFalse);
    final routine = File('../schemas/routine.schema.json').readAsStringSync();
    final export = File('../schemas/export.schema.json').readAsStringSync();
    expect(routine, isNot(contains('trigger')));
    expect(export, isNot(contains('trigger')));
    for (final schema in [routine, export]) {
      expect(schema, contains('https://openroutine.app/schemas/v2/'));
    }
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
