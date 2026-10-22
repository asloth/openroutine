import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/import_export/export_service.dart';
import '../services/import_export/import_service.dart';
import '../services/import_export/schema_validator.dart';
import 'storage_provider.dart';

part 'import_export_provider.g.dart';

/// Kept alive because the schemas are bundled assets: they can't change while
/// the app runs, and compiling them is slow on a cold start. Callers read
/// this once, with nothing listening, so an auto-dispose version could be
/// torn down mid-load.
@Riverpod(keepAlive: true)
Future<SchemaValidator> schemaValidator(Ref ref) => SchemaValidator.load();

/// Kept alive for the same reason. The import screen reads it once when you
/// select Choose file. Auto-dispose dropped it during the first, slow schema
/// load, so the read failed and the file picker never opened.
@Riverpod(keepAlive: true)
Future<ImportService> importService(Ref ref) async {
  final storage = ref.watch(storageAdapterProvider);
  final validator = await ref.watch(schemaValidatorProvider.future);
  return ImportService(storage, validator);
}

@riverpod
ExportService exportService(Ref ref) =>
    ExportService(ref.watch(storageAdapterProvider));
