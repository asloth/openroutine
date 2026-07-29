import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
