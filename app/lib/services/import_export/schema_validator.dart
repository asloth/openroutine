import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';

/// Validates decoded JSON against schemas/export.schema.json (docs/SPEC.md
/// §13: "Validate all JSON reads against schemas/*.json and log (don't
/// crash) on drift"). The five schema files are bundled as Flutter assets
/// under assets/schemas/ — a committed copy of the repo-root schemas/
/// directory (see schema_validator_test.dart's sibling test verifying the two
/// stay byte-identical, since drift between them would silently break the
/// public contract).
class SchemaValidationException implements Exception {
  SchemaValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'Schema validation failed:\n${errors.join('\n')}';
}

class SchemaValidator {
  SchemaValidator._(this._exportSchema);

  final JsonSchema _exportSchema;

  static const _schemaAssets = {
    'https://openroutine.app/schemas/v1/routine.schema.json':
        'assets/schemas/routine.schema.json',
    'https://openroutine.app/schemas/v1/step.schema.json':
        'assets/schemas/step.schema.json',
    'https://openroutine.app/schemas/v1/trigger.schema.json':
        'assets/schemas/trigger.schema.json',
    'https://openroutine.app/schemas/v1/completion.schema.json':
        'assets/schemas/completion.schema.json',
    'https://openroutine.app/schemas/v1/export.schema.json':
        'assets/schemas/export.schema.json',
  };

  static const _exportSchemaId =
      'https://openroutine.app/schemas/v1/export.schema.json';

  static Future<SchemaValidator> load() async {
    final schemasById = <String, Map<String, dynamic>>{};
    for (final entry in _schemaAssets.entries) {
      final raw = await rootBundle.loadString(entry.value);
      schemasById[entry.key] = jsonDecode(raw) as Map<String, dynamic>;
    }
    final exportSchema = await JsonSchema.createAsync(
      schemasById[_exportSchemaId]!,
      refProvider: RefProvider.async((ref) async => schemasById[ref]),
    );
    return SchemaValidator._(exportSchema);
  }

  /// Throws [SchemaValidationException] with human-readable messages if
  /// [json] doesn't conform to export.schema.json. Never throws for reasons
  /// other than an actual schema mismatch — callers should catch this and
  /// show the user an error, not let it crash the app.
  void validateExportBundle(Map<String, dynamic> json) {
    final result = _exportSchema.validate(json);
    if (!result.isValid) {
      throw SchemaValidationException(
        result.errors.map((e) => e.message).toList(),
      );
    }
  }
}
