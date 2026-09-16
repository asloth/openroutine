import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/schema_version.dart';

void main() {
  group('SchemaVersion', () {
    test('accepts every 1.x export and the current 2.0 export', () {
      expect(SchemaVersion.parseSupported('1.0.0'), SchemaVersion.v1_0);
      expect(SchemaVersion.parseSupported('1.0.9'), SchemaVersion.v1_0);
      expect(SchemaVersion.parseSupported('1.1.0'), SchemaVersion.v1_1);
      expect(SchemaVersion.parseSupported('1.2.0'), SchemaVersion.v1_2);
      expect(SchemaVersion.parseSupported('2.0.0'), SchemaVersion.current);
    });

    test('2.0.0 is the version this build writes', () {
      expect(SchemaVersion.current, SchemaVersion.v2_0);
      expect(SchemaVersion.currentValue, '2.0.0');
    });

    for (final version in [
      '1.1.1',
      '1.2.1',
      '1.3.0',
      '2.0.1',
      '2.1.0',
      '3.0.0',
    ]) {
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
