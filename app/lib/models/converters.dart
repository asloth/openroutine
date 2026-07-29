import 'package:freezed_annotation/freezed_annotation.dart';

/// Serializes DateTime as ISO-8601 UTC (docs/SPEC.md §4: "All timestamps are
/// ISO-8601 UTC"). Dart's DateTime.toIso8601String() only emits a trailing
/// 'Z' when isUtc is true, so every value is normalized through toUtc()
/// first — otherwise a local-time DateTime would serialize without 'Z' and
/// silently violate the schema's date-time format.
class UtcDateTimeConverter implements JsonConverter<DateTime, String> {
  const UtcDateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toUtc();

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

class NullableUtcDateTimeConverter
    implements JsonConverter<DateTime?, String?> {
  const NullableUtcDateTimeConverter();

  @override
  DateTime? fromJson(String? json) =>
      json == null ? null : DateTime.parse(json).toUtc();

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}
