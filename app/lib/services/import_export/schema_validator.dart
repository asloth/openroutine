import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:json_schema/json_schema.dart';

/// Validates decoded JSON against schemas/export.schema.json (docs/SPEC.md
/// §13: "Validate all JSON reads against schemas/*.json and log (don't
/// crash) on drift"). The four schema files are bundled as Flutter assets
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

  /// Lets a test stand in a schema of its own — a permissive one, to reach
  /// the parse boundary behind this validator without hand-crafting data
  /// that defeats the real schema.
  @visibleForTesting
  SchemaValidator.forTesting(JsonSchema exportSchema)
    : _exportSchema = exportSchema;

  final JsonSchema _exportSchema;

  static const _schemaAssets = {
    'https://openroutine.app/schemas/v2/routine.schema.json':
        'assets/schemas/routine.schema.json',
    'https://openroutine.app/schemas/v2/step.schema.json':
        'assets/schemas/step.schema.json',
    'https://openroutine.app/schemas/v2/completion.schema.json':
        'assets/schemas/completion.schema.json',
    'https://openroutine.app/schemas/v2/export.schema.json':
        'assets/schemas/export.schema.json',
  };

  static const _exportSchemaId =
      'https://openroutine.app/schemas/v2/export.schema.json';

  /// json_schema's own `uuid` check predates RFC 9562: its regex accepts
  /// versions 0-5, so it rejects every v7 id this app writes. The schemas
  /// already pin v7 with a `pattern`, so this keeps `format: uuid` meaning
  /// "shaped like a UUID" and leaves the version to that pattern.
  static final _uuidShape = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static ValidationContext _validateUuid(
    ValidationContext context,
    String instanceData,
  ) {
    if (!_uuidShape.hasMatch(instanceData)) {
      context.addError('"uuid" format not accepted $instanceData');
    }
    return context;
  }

  static Future<SchemaValidator> load() async {
    final schemasById = <String, Map<String, dynamic>>{};
    for (final entry in _schemaAssets.entries) {
      final raw = await rootBundle.loadString(entry.value);
      schemasById[entry.key] = jsonDecode(raw) as Map<String, dynamic>;
    }
    final exportSchema = await JsonSchema.createAsync(
      schemasById[_exportSchemaId]!,
      refProvider: RefProvider.async((ref) async => schemasById[ref]),
      customFormats: {'uuid': _validateUuid},
    );
    return SchemaValidator._(exportSchema);
  }

  /// Throws [SchemaValidationException] with human-readable messages if
  /// [json] doesn't conform to export.schema.json. Never throws for reasons
  /// other than an actual schema mismatch — callers should catch this and
  /// show the user an error, not let it crash the app.
  void validateExportBundle(Map<String, dynamic> json) {
    // The schemas declare draft 2020-12, where json_schema leaves `format`
    // unchecked unless you ask. Without this, a `date-time` that isn't one
    // passes validation and fails later, in the models, as a raw exception.
    final result = _exportSchema.validate(json, validateFormats: true);
    if (!result.isValid) {
      throw SchemaValidationException(
        result.errors.map((e) => e.message).toList(),
      );
    }
  }
}
