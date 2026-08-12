import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/storage/drive/drive_api_client.dart';
import 'package:openroutine/services/storage/drive/drive_layout.dart';

import 'fake_drive_api_client.dart';

void main() {
  group('Drive authority discovery', () {
    test('missing folder is read-only', () async {
      final api = FakeDriveApiClient();

      expect(await api.discoverFolder(DriveLayout.folderName), isNull);
      expect(api.mutations, isEmpty);
    });

    test('duplicate folders are refused without mutation', () async {
      final api = FakeDriveApiClient();
      api.seedFolder(DriveLayout.folderName);
      api.seedFolder(DriveLayout.folderName);

      expect(
        () => api.discoverFolder(DriveLayout.folderName),
        throwsA(isA<DriveAmbiguousDiscovery>()),
      );
      expect(api.mutations, isEmpty);
    });

    test(
      'authority snapshot retains identity, content, schema, and revision',
      () async {
        final api = FakeDriveApiClient();
        api.seed(
          path: DriveLayout.metaFile,
          content: '{"schema_version":"1.1.0"}',
        );

        final folder = await api.discoverFolder(DriveLayout.folderName);
        final snapshot = await api.readTextFile(
          parentId: folder!,
          name: DriveLayout.metaFile,
        );

        expect(snapshot!.file.id, startsWith('id-'));
        expect(snapshot.content, '{"schema_version":"1.1.0"}');
        expect(snapshot.schemaAuthority, '1.1.0');
        expect(snapshot.file.version, 1);
        expect(snapshot.file.etag, 'etag-1');
      },
    );
  });

  test(
    'conditional update rejects a changed snapshot without writing',
    () async {
      final api = FakeDriveApiClient();
      api.seed(
        path: DriveLayout.routinesFile,
        content: '{"schema_version":"1.1.0"}',
      );
      final folder = await api.discoverFolder(DriveLayout.folderName);
      final snapshot = await api.readTextFile(
        parentId: folder!,
        name: DriveLayout.routinesFile,
      );
      api.seed(
        path: DriveLayout.routinesFile,
        content: '{"schema_version":"1.1.1"}',
      );

      expect(
        () => api.uploadText(
          parentId: folder,
          name: DriveLayout.routinesFile,
          content: 'local',
          fileId: snapshot!.file.id,
          expectedRevision: snapshot.file,
        ),
        throwsA(isA<DriveRevisionConflict>()),
      );
      expect(
        api.contentOf(DriveLayout.routinesFile),
        '{"schema_version":"1.1.1"}',
      );
    },
  );

  test('expected-absent create rejects a file that appeared', () async {
    final api = FakeDriveApiClient();
    final folder = await api.ensureFolder(DriveLayout.folderName);
    api.seed(path: DriveLayout.metaFile, content: 'remote');

    expect(
      () => api.uploadText(
        parentId: folder,
        name: DriveLayout.metaFile,
        content: 'local',
        expectAbsent: true,
      ),
      throwsA(isA<DriveRevisionConflict>()),
    );
    expect(api.contentOf(DriveLayout.metaFile), 'remote');
  });
}
