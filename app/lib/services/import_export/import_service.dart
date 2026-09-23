import 'dart:convert';

import 'package:file_selector/file_selector.dart';

import '../../models/export_bundle.dart';
import '../../models/import_preview.dart';
import '../schema_version.dart';
import '../storage/storage_adapter.dart';
import 'schema_validator.dart';

/// Reason distinguishes "not JSON at all" from "valid JSON, wrong shape" —
/// docs/SPEC.md §10 wants a clear message either way, with a link to the
/// schema doc, never a crash.
enum ImportFailureReason { invalidJson, schemaViolation }

class ImportException implements Exception {
  ImportException(this.reason, this.details);

  final ImportFailureReason reason;
  final String details;
}

const _jsonTypeGroup = XTypeGroup(
  label: 'JSON',
  extensions: ['json'],
  mimeTypes: ['application/json'],
  uniformTypeIdentifiers: ['public.json'],
);

class ImportService {
  ImportService(this._storage, this._validator);

  final StorageAdapter _storage;
  final SchemaValidator _validator;

  /// Opens the file picker. Returns null if the user cancels — not an
  /// error. Throws [ImportException] for bad JSON or a schema mismatch.
  Future<ExportBundle?> pickAndValidate() async {
    final file = await openFile(acceptedTypeGroups: [_jsonTypeGroup]);
    if (file == null) return null;

    final contents = await file.readAsString();
    return validateJsonString(contents);
  }

  /// Split out from [pickAndValidate] so tests can exercise validation
  /// without a real file picker.
  ExportBundle validateJsonString(String contents) {
    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (e) {
      throw ImportException(ImportFailureReason.invalidJson, e.message);
    }
    if (decoded is! Map<String, dynamic>) {
      throw ImportException(
        ImportFailureReason.invalidJson,
        'The import must contain a JSON object.',
      );
    }

    try {
      _validator.validateExportBundle(decoded);
    } on SchemaValidationException catch (e) {
      throw ImportException(
        ImportFailureReason.schemaViolation,
        e.errors.join('\n'),
      );
    }

    // Schema validation covers what the schema can express. The models parse
    // on top of that, so this boundary has to be total: a value that gets
    // past the schema and defeats a model is still the file's problem, and
    // the screen can only show it if it arrives as an ImportException.
    try {
      return ExportBundle.fromJson(decoded);
    } on UnsupportedSchemaVersionException {
      // A bundle from a newer build has its own answer on the screen, and
      // this subclasses FormatException, so it has to pass through first.
      rethrow;
    } on FormatException catch (e) {
      throw ImportException(ImportFailureReason.schemaViolation, e.message);
    } on ArgumentError catch (e) {
      throw ImportException(ImportFailureReason.schemaViolation, '$e');
    }
  }

  Future<ImportPreview> preview(ExportBundle bundle) =>
      _storage.previewImport(bundle);

  Future<void> confirm(ExportBundle bundle) => _storage.confirmImport(bundle);
}
