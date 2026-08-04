import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/export_bundle.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/import_export/schema_validator.dart';
import 'package:openroutine/services/storage/drive/drive_api_client.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/drive/drive_layout.dart';
import 'package:openroutine/services/storage/drive/drive_sync.dart';
import 'package:openroutine/services/storage/drive/sync_queue.dart';
import 'package:openroutine/services/storage/local_adapter.dart';

import 'fake_drive_api_client.dart';

/// UUIDs because the JSON schemas require them — a pull validates the remote
/// file, so 'r1' would be rejected for the wrong reason.
const _routineId = '019fc553-a96e-7cb7-84e8-93de8598e290';
const _otherRoutineId = '019fc553-a96e-7cb7-84e8-93de8598e291';

final _t0 = DateTime.utc(2026, 8, 1, 9);

Routine _routine({
  String id = _routineId,
  String name = 'morning',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) => Routine(
  id: id,
  name: name,
  triggerId: null,
  schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
  stepIds: const [],
  createdAt: _t0,
  updatedAt: updatedAt ?? _t0,
  deletedAt: deletedAt,
);

String _remoteBundle(List<Routine> routines) {
  return jsonEncode(
    ExportBundle(
      schemaVersion: '1.0.0',
      exportedAt: _t0,
      routines: routines,
      steps: const [],
      triggers: const [],
    ).toJson(),
  );
}

CompletionLog _completion(String id, {DateTime? startedAt}) => CompletionLog(
  id: id,
  routineId: _routineId,
  startedAt: startedAt ?? DateTime.utc(2026, 8, 3, 7),
  endedAt: (startedAt ?? DateTime.utc(2026, 8, 3, 7)).add(
    const Duration(minutes: 10),
  ),
  outcome: CompletionOutcome.completed,
  steps: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalAdapter local;
  late SyncQueue queue;
  late FakeDriveApiClient api;
  late DriveSync sync;
  late SchemaValidator validator;

  setUpAll(() async => validator = await SchemaValidator.load());

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalAdapter(db);
    queue = SyncQueue(db);
    api = FakeDriveApiClient();
    sync = DriveSync(
      api: api,
      local: local,
      queue: queue,
      validator: validator,
      installClientId: 'client-under-test',
    );
  });

  tearDown(() => db.close());

  group('first connect', () {
    test('seeds the folder with routines, meta and a README', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();

      expect(await sync.sync(), SyncOutcome.synced);

      expect(api.exists(DriveLayout.readmeFile), isTrue);
      expect(api.exists(DriveLayout.routinesFile), isTrue);
      expect(api.exists(DriveLayout.metaFile), isTrue);
      expect(api.exists(DriveLayout.completionsFolder), isTrue);

      final remote =
          jsonDecode(api.contentOf(DriveLayout.routinesFile)!)
              as Map<String, dynamic>;
      expect((remote['routines'] as List).single['name'], 'morning');
      // The whole point of the folder being visible: what lands there has to
      // satisfy the published schemas, not just round-trip through our code.
      validator.validateExportBundle(remote);
    });

    test('records which install wrote last', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      await sync.sync();

      final meta =
          jsonDecode(api.contentOf(DriveLayout.metaFile)!)
              as Map<String, dynamic>;
      expect(meta['last_writer_client_id'], 'client-under-test');
      expect(meta['schema_version'], '1.0.0');
    });

    test('clears the dirty flag so the next sync uploads nothing', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      await sync.sync();

      api.uploads.clear();
      expect(await sync.sync(), SyncOutcome.synced);
      expect(api.uploads, isEmpty);
    });

    test('rewrites routines.json instead of creating a second one', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      await sync.sync();

      await local.saveRoutine(_routine(name: 'renamed', updatedAt: _t0));
      await queue.markRoutinesDirty();
      await sync.sync();

      expect(api.countNamed(DriveLayout.routinesFile), 1);
    });
  });

  group('merging', () {
    test('a newer remote edit wins over the local copy', () async {
      await local.saveRoutine(_routine(name: 'local name'));
      api.seed(
        path: DriveLayout.routinesFile,
        content: _remoteBundle([
          _routine(
            name: 'edited in Drive',
            updatedAt: _t0.add(const Duration(hours: 1)),
          ),
        ]),
      );

      expect(await sync.sync(), SyncOutcome.synced);

      expect((await local.getRoutine(_routineId))!.name, 'edited in Drive');
    });

    test('a stale remote edit does not clobber a newer local one', () async {
      await local.saveRoutine(
        _routine(name: 'local name', updatedAt: _t0.add(const Duration(days: 1))),
      );
      api.seed(
        path: DriveLayout.routinesFile,
        content: _remoteBundle([_routine(name: 'old remote')]),
      );

      await sync.sync();

      expect((await local.getRoutine(_routineId))!.name, 'local name');
    });

    test('a stale remote copy cannot resurrect a locally deleted routine',
        () async {
      await local.saveRoutine(_routine());
      await local.deleteRoutine(_routineId);
      // Drive still holds the pre-delete version, which is exactly what a
      // second device that has not synced yet would upload.
      api.seed(
        path: DriveLayout.routinesFile,
        content: _remoteBundle([_routine()]),
      );

      await sync.sync();

      expect(await local.getRoutine(_routineId), isNull);
    });

    test('malformed remote JSON leaves local data alone', () async {
      await local.saveRoutine(_routine(name: 'local name'));
      api.seed(
        path: DriveLayout.routinesFile,
        content: '{ this is not json',
      );

      expect(await sync.sync(), SyncOutcome.failed);

      expect((await local.getRoutine(_routineId))!.name, 'local name');
      expect(await queue.lastError, contains('not usable'));
    });

    test('remote JSON that violates the schema is refused, not imported',
        () async {
      await local.saveRoutine(_routine(name: 'local name'));
      api.seed(
        path: DriveLayout.routinesFile,
        // Valid JSON, invalid bundle: id is not a UUID.
        content: jsonEncode({
          'schema_version': '1.0.0',
          'exported_at': _t0.toIso8601String(),
          'routines': [
            {'id': 'nope', 'name': 'bad'},
          ],
          'steps': <dynamic>[],
          'triggers': <dynamic>[],
        }),
      );

      expect(await sync.sync(), SyncOutcome.failed);
      expect((await local.getRoutine(_routineId))!.name, 'local name');
    });
  });

  group('failure handling', () {
    test('offline keeps the work queued and reports offline', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      api.failNextWith = driveOffline;

      expect(await sync.sync(), SyncOutcome.offline);
      expect(await queue.routinesDirty, isTrue);
      // Not surfaced as an error: being offline is the state this app is
      // designed around.
      expect(await queue.lastError, isNull);
    });

    test('a later attempt succeeds once the network is back', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      api.failNextWith = driveOffline;
      await sync.sync();

      expect(await sync.sync(), SyncOutcome.synced);
      expect(await queue.routinesDirty, isFalse);
      expect(api.exists(DriveLayout.routinesFile), isTrue);
    });

    test('an expired grant asks for reconnection and does not build backoff',
        () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      api.failNextWith = driveAuthExpired;

      expect(await sync.sync(), SyncOutcome.needsReauth);
      // The distinction that matters: waiting fixes a network problem, but
      // never fixes a revoked grant, so this path must not schedule retries.
      expect(queue.consecutiveFailures, 0);
      expect(queue.backoff, Duration.zero);
      expect(await queue.routinesDirty, isTrue);
    });

    test('a server error is retryable and does accumulate backoff', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
      api.failNextWith = const DriveApiException(500, 'boom');

      expect(await sync.sync(), SyncOutcome.failed);
      expect(queue.consecutiveFailures, 1);
      expect(queue.backoff, greaterThan(Duration.zero));
    });

    test('overlapping triggers coalesce into one run', () async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();

      final results = await Future.wait([sync.sync(), sync.sync()]);

      expect(results, [SyncOutcome.synced, SyncOutcome.synced]);
      // One routines.json upload, not two: the second caller joined the first
      // run instead of starting its own with a bundle built mid-merge.
      expect(
        api.uploads.where((n) => n == DriveLayout.routinesFile).length,
        1,
      );
    });
  });

  group('completions', () {
    setUp(() async {
      await local.saveRoutine(_routine());
      await queue.markRoutinesDirty();
    });

    test('a local run is appended to its month shard', () async {
      await local.appendCompletion(_completion('c-local'));
      await queue.markCompletionMonthDirty('2026-08');

      await sync.sync();

      final lines = api.contentOf('2026-08.ndjson')!.trim().split('\n');
      expect(lines, hasLength(1));
      expect(jsonDecode(lines.single)['id'], 'c-local');
    });

    test('two writers keep both runs, deduped by id', () async {
      await local.appendCompletion(_completion('c-local'));
      await queue.markCompletionMonthDirty('2026-08');
      // Same month, written by another device — including a duplicate of ours.
      api.seed(
        path: '${DriveLayout.completionsFolder}/2026-08.ndjson',
        content: [
          jsonEncode(_completion('c-remote').toJson()),
          jsonEncode(_completion('c-local').toJson()),
        ].join('\n'),
      );

      await sync.sync();

      final ids = api
          .contentOf('2026-08.ndjson')!
          .trim()
          .split('\n')
          .map((line) => jsonDecode(line)['id'])
          .toList();
      expect(ids, containsAll(['c-local', 'c-remote']));
      expect(ids, hasLength(2));
    });

    test('a remote run becomes visible locally', () async {
      await queue.markCompletionMonthDirty('2026-08');
      api.seed(
        path: '${DriveLayout.completionsFolder}/2026-08.ndjson',
        content: jsonEncode(_completion('c-remote').toJson()),
      );

      await sync.sync();

      final logs = await local.getCompletions(_routineId);
      expect(logs.single.id, 'c-remote');
    });

    test('a corrupt line costs only itself', () async {
      await queue.markCompletionMonthDirty('2026-08');
      api.seed(
        path: '${DriveLayout.completionsFolder}/2026-08.ndjson',
        content: [
          'half a line {',
          jsonEncode(_completion('c-good').toJson()),
        ].join('\n'),
      );

      expect(await sync.sync(), SyncOutcome.synced);
      expect((await local.getCompletions(_routineId)).single.id, 'c-good');
    });

    test('a completion for a routine we do not have yet is kept, not lost',
        () async {
      await queue.markCompletionMonthDirty('2026-08');
      api.seed(
        path: '${DriveLayout.completionsFolder}/2026-08.ndjson',
        content: jsonEncode(
          CompletionLog(
            id: 'c-orphan',
            routineId: _otherRoutineId,
            startedAt: DateTime.utc(2026, 8, 3, 7),
            endedAt: DateTime.utc(2026, 8, 3, 7, 5),
            outcome: CompletionOutcome.completed,
            steps: const [],
          ).toJson(),
        ),
      );

      expect(await sync.sync(), SyncOutcome.synced);

      // Kept rather than dropped: a pull has no ordering guarantee against a
      // folder an agent is also writing, so a run whose routine has not
      // arrived yet must survive until it does. It stays invisible in the
      // meantime, because every read is scoped by routine.
      expect((await local.getCompletions(_otherRoutineId)).single.id, 'c-orphan');
      expect(await local.getCompletions(_routineId), isEmpty);
    });

    test('only the dirty month is touched', () async {
      await local.appendCompletion(
        _completion('c-july', startedAt: DateTime.utc(2026, 7, 10, 7)),
      );
      await local.appendCompletion(_completion('c-august'));
      await queue.markCompletionMonthDirty('2026-08');

      await sync.sync();

      expect(api.exists('2026-08.ndjson'), isTrue);
      expect(api.exists('2026-07.ndjson'), isFalse);
    });
  });
}
