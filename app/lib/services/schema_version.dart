class UnsupportedSchemaVersionException extends FormatException {
  UnsupportedSchemaVersionException(this.version, {required this.isNewer})
    : super('Unsupported schema version: $version');

  final String version;
  final bool isNewer;
}

/// Versions this installation can safely read and write.
enum SchemaVersion {
  v1_0('1.0.0'),
  v1_1('1.1.0');

  const SchemaVersion(this.value);

  final String value;

  static const current = SchemaVersion.v1_1;
  static const currentValue = '1.1.0';

  /// Accepts additive 1.0 patch releases and the exact 1.1 format.
  static SchemaVersion parseSupported(String value) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
    if (match == null) {
      throw FormatException('Malformed schema version: $value');
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    if (major != 1 || (minor == 1 && patch != 0) || minor > 1) {
      throw UnsupportedSchemaVersionException(
        value,
        isNewer:
            major > 1 ||
            (major == 1 && (minor > 1 || (minor == 1 && patch > 0))),
      );
    }
    return minor == 0 ? v1_0 : v1_1;
  }
}
