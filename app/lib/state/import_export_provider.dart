import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/import_export/export_service.dart';
import '../services/import_export/import_service.dart';
import '../services/import_export/schema_validator.dart';
import 'storage_provider.dart';

part 'import_export_provider.g.dart';

@riverpod
Future<SchemaValidator> schemaValidator(Ref ref) => SchemaValidator.load();

@riverpod
Future<ImportService> importService(Ref ref) async {
  final validator = await ref.watch(schemaValidatorProvider.future);
  return ImportService(ref.watch(storageAdapterProvider), validator);
}

@riverpod
ExportService exportService(Ref ref) =>
    ExportService(ref.watch(storageAdapterProvider));
