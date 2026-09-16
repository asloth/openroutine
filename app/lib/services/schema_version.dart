class UnsupportedSchemaVersionException extends FormatException {
  UnsupportedSchemaVersionException(this.version, {required this.isNewer})
    : super('Unsupported schema version: $version');

  final String version;
  final bool isNewer;
}

/// Versions this installation can read. It writes only [current].
enum SchemaVersion {
  v1_0('1.0.0'),
  v1_1('1.1.0'),
  v1_2('1.2.0'),

  /// Moments (triggers) removed: routines lose `trigger_id` and exports lose
  /// `triggers`. See `openspec/changes/remove-moments/`.
  v2_0('2.0.0');

  const SchemaVersion(this.value);

  final String value;

  static const current = SchemaVersion.v2_0;
  static const currentValue = '2.0.0';

  /// Accepts additive 1.0 patch releases, the exact 1.1 and 1.2 formats, and
  /// 2.0.
  ///
  /// Every 1.x file reads as a 2.0 file with moments on it: the models ignore
  /// `trigger_id` and `triggers`, so no conversion is needed, and the next
  /// write declares 2.0.0.
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
    if (major == 2 && minor == 0 && patch == 0) return v2_0;
    throw UnsupportedSchemaVersionException(
      value,
      // Anything rejected from major 1 on claims a revision written after one
      // we understand, so the import screen can tell the user to update. Only
      // an older major predates the format entirely.
      isNewer: major >= 1,
    );
  }
}
