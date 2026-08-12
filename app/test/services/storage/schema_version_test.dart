import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/schema_version.dart';

void main() {
  group('SchemaVersion', () {
    test('accepts legacy 1.0 exports and the current 1.1 export', () {
      expect(SchemaVersion.parseSupported('1.0.0'), SchemaVersion.v1_0);
      expect(SchemaVersion.parseSupported('1.0.9'), SchemaVersion.v1_0);
      expect(SchemaVersion.parseSupported('1.1.0'), SchemaVersion.current);
    });

    test('refuses malformed, newer, and different-major versions', () {
      expect(
        () => SchemaVersion.parseSupported('1.2.0'),
        throwsFormatException,
      );
      expect(
        () => SchemaVersion.parseSupported('1.1.1'),
        throwsFormatException,
      );
      expect(
        () => SchemaVersion.parseSupported('2.0.0'),
        throwsFormatException,
      );
      expect(
        () => SchemaVersion.parseSupported('one.one'),
        throwsFormatException,
      );
    });
  });
}
