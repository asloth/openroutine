import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/schema_version.dart';

void main() {
  group('SchemaVersion', () {
    test('accepts legacy 1.0 exports and the current 1.1 export', () {
      expect(SchemaVersion.parseSupported('1.0.0'), SchemaVersion.v1_0);
      expect(SchemaVersion.parseSupported('1.0.9'), SchemaVersion.v1_0);
      expect(SchemaVersion.parseSupported('1.1.0'), SchemaVersion.current);
    });

    for (final version in ['1.1.1', '1.2.0', '2.0.0']) {
      test('classifies unsupported newer version $version for import UI', () {
        expect(
          () => SchemaVersion.parseSupported(version),
          throwsA(
            isA<UnsupportedSchemaVersionException>()
                .having((error) => error.version, 'version', version)
                .having((error) => error.isNewer, 'isNewer', isTrue),
          ),
        );
      });
    }

    test('classifies an unsupported older major as non-newer', () {
      expect(
        () => SchemaVersion.parseSupported('0.9.0'),
        throwsA(
          isA<UnsupportedSchemaVersionException>()
              .having((error) => error.version, 'version', '0.9.0')
              .having((error) => error.isNewer, 'isNewer', isFalse),
        ),
      );
    });

    test('refuses malformed versions as format errors', () {
      expect(
        () => SchemaVersion.parseSupported('one.one'),
        throwsFormatException,
      );
    });
  });
}
