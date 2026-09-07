class UnsupportedSchemaVersionException extends FormatException {
  UnsupportedSchemaVersionException(this.version, {required this.isNewer})
    : super('Unsupported schema version: $version');

  final String version;
  final bool isNewer;
}

/// Versions this installation can safely read and write.
enum SchemaVersion {
  v1_0('1.0.0'),
  v1_1('1.1.0'),
  v1_2('1.2.0');

  const SchemaVersion(this.value);

  final String value;

  static const current = SchemaVersion.v1_2;
  static const currentValue = '1.2.0';

  /// Accepts additive 1.0 patch releases and the exact 1.1 and 1.2 formats.
  static SchemaVersion parseSupported(String value) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
    if (match == null) {
      throw FormatException('Malformed schema version: $value');
    }

    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    if (major == 1) {
      // 1.0 shipped before this gate existed, so every 1.0 patch release is
      // readable. Each minor since is purely additive and pinned to patch 0;
      // a patch on one of those is a revision we have never seen.
      if (minor == 0) return v1_0;
      if (patch == 0 && minor == 1) return v1_1;
      if (patch == 0 && minor == 2) return v1_2;
    }
    throw UnsupportedSchemaVersionException(
      value,
      // Anything rejected inside major 1 claims a revision written after one
      // we understand, so the import screen can tell the user to update. Only
      // an older major predates the format entirely.
      isNewer: major >= 1,
    );
  }
}
