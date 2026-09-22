import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/import_export/export_service.dart';

void main() {
  test('a plain routine name is kept as it is', () {
    expect(ExportService.fileNameFor('Morning'), 'Morning');
  });

  test('a name with separators loses them but stays readable', () {
    expect(ExportService.fileNameFor('../../etc/passwd'), 'etc-passwd');
  });

  test('a name with nothing usable left still produces a file name', () {
    expect(ExportService.fileNameFor('///'), 'export');
  });
}
