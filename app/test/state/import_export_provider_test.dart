import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/import_export/import_service.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/import_export_provider.dart';
import 'package:openroutine/state/storage_provider.dart';

/// The import screen reads the service once, with `ref.read`, when you select
/// Choose file. Nothing listens to it, so if the provider can be disposed
/// while the schemas load, the read never resolves and the picker never
/// opens. That's the first-tap hang on the phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a one-off read of the import service resolves', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        storageAdapterProvider.overrideWithValue(LocalAdapter(db)),
        // On a cold start the phone takes a moment to read and compile the
        // schemas. Without the delay, the load wins the race in a test.
        schemaValidatorProvider.overrideWith((ref) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return SchemaValidator.load();
        }),
      ],
    );
    addTearDown(container.dispose);

    final service = await container
        .read(importServiceProvider.future)
        .timeout(const Duration(seconds: 10));

    expect(service, isA<ImportService>());
  });
}
