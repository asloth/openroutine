import 'dart:async';
import 'dart:convert';

import '../../../models/completion_log.dart';
import '../../../models/export_bundle.dart';
import '../../auth/drive_auth.dart';
import '../../import_export/schema_validator.dart';
import '../local_adapter.dart';
import '../storage_adapter.dart' show nowUtc;
import 'drive_api_client.dart';
import 'drive_layout.dart';
import 'sync_queue.dart';

/// How a sync attempt ended. Everything the UI shows about sync derives from
/// this, so `offline` and `needsReauth` are first-class results rather than
/// flavours of failure — neither is something the user did wrong, and only one
/// of them is worth retrying on a timer.
enum SyncOutcome { synced, offline, needsReauth, failed }

/// Reconciles the local drift database with the `OpenRoutine` folder in the
/// user's Drive (docs/SPEC.md §5).
///
/// Direction of trust: local SQLite is the source of truth for reads, always.
/// This worker never serves a screen; it merges Drive into local and then
/// uploads the result. A screen that would have to wait on the network is a
/// screen that breaks the offline-first promise in §1.
class DriveSync {
  DriveSync({
    required DriveApiClient api,
    required LocalAdapter local,
    required SyncQueue queue,
    required SchemaValidator validator,
    required String installClientId,
  }) : _api = api,
       _local = local,
       _queue = queue,
       _validator = validator,
       _installClientId = installClientId;

  final DriveApiClient _api;
  final LocalAdapter _local;
  final SyncQueue _queue;
  final SchemaValidator _validator;
  final String _installClientId;

  /// Serialises overlapping triggers. A foreground event and a debounced write
  /// can land together; without this they would both pull, both merge, and the
  /// slower one would upload a bundle built before the other's merge.
  Future<SyncOutcome>? _inFlight;

  String? _folderId;
  String? _completionsFolderId;

  Future<SyncOutcome> sync() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<SyncOutcome> _run() async {
    try {
      await _ensureFolders();
      await _pullRoutines();
      await _pushRoutines();
      await _syncCompletions();
      await _queue.recordSuccess(nowUtc());
      return SyncOutcome.synced;
    } on DriveAuthExpired catch (e) {
      await _queue.recordAuthExpired(e.toString());
      return SyncOutcome.needsReauth;
    } on DriveOffline {
      // Not recorded as a failure: being offline is the expected state this
      // app is built around, and it should not show up as an error the user
      // has to interpret.
      return SyncOutcome.offline;
    } on DriveApiException catch (e) {
      await _queue.recordRetryableFailure(e.toString());
      return SyncOutcome.failed;
    } on FormatException catch (e) {
      // Malformed remote JSON. Recorded so Settings can say something true,
      // but local data is untouched — see _pullRoutines.
      await _queue.recordRetryableFailure('Invalid remote data: $e');
      return SyncOutcome.failed;
    }
  }

  Future<void> _ensureFolders() async {
    final folderId = _folderId ??= await _api.ensureFolder(
      DriveLayout.folderName,
    );

    // Written once, when the folder is new. It explains the format to whoever
    // opens the folder without the app — the reason the folder is visible at
    // all (docs/SPEC.md §1).
    final readmeId = await _api.findFile(
      parentId: folderId,
      name: DriveLayout.readmeFile,
    );
    if (readmeId == null) {
      await _api.uploadText(
        parentId: folderId,
        name: DriveLayout.readmeFile,
        content: driveFolderReadme,
        mimeType: 'text/markdown',
      );
    }

    _completionsFolderId ??= await _ensureChildFolder(
      folderId,
      DriveLayout.completionsFolder,
    );
  }

  Future<String> _ensureChildFolder(String parentId, String name) async {
    final existing = await _api.findFile(parentId: parentId, name: name);
    if (existing != null) return existing;
    return _api.uploadText(
      parentId: parentId,
      name: name,
      content: '',
      mimeType: 'application/vnd.google-apps.folder',
    );
  }

  /// Downloads `routines.json` and merges it in.
  ///
  /// The merge is [LocalAdapter.confirmImport] — the very same last-writer-wins
  /// pass that the Import screen runs. Drive is just another source of a
  /// bundle, so it must not get its own merge rules to drift out of sync with.
  Future<void> _pullRoutines() async {
    final fileId = await _api.findFile(
      parentId: _folderId!,
      name: DriveLayout.routinesFile,
    );
    if (fileId == null) return; // Nothing remote yet; the push below seeds it.

    final raw = await _api.downloadText(fileId);
    if (raw == null || raw.trim().isEmpty) return;

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
      // This file may have been hand-edited by a human or an agent, which is
      // the point of the format. Validate before trusting it, exactly as the
      // Import screen does with a file off the filesystem.
      _validator.validateExportBundle(json);
    } on Object catch (e) {
      // Deliberately swallowed into a FormatException: a broken remote file
      // must never take local data with it. The README promises this.
      throw FormatException('${DriveLayout.routinesFile} is not usable: $e');
    }

    await _local.confirmImport(ExportBundle.fromJson(json));
  }

  Future<void> _pushRoutines() async {
    if (!await _queue.routinesDirty) return;

    final bundle = await _local.exportAll();
    final existing = await _api.findFile(
      parentId: _folderId!,
      name: DriveLayout.routinesFile,
    );
    await _api.uploadText(
      parentId: _folderId!,
      name: DriveLayout.routinesFile,
      content: const JsonEncoder.withIndent('  ').convert(bundle.toJson()),
      fileId: existing,
    );

    await _writeMeta(bundle.schemaVersion);
    await _queue.clearRoutines();
  }

  Future<void> _writeMeta(String schemaVersion) async {
    final existing = await _api.findFile(
      parentId: _folderId!,
      name: DriveLayout.metaFile,
    );
    await _api.uploadText(
      parentId: _folderId!,
      name: DriveLayout.metaFile,
      content: const JsonEncoder.withIndent('  ').convert({
        'schema_version': schemaVersion,
        'last_writer_client_id': _installClientId,
        'last_sync_at': nowUtc().toIso8601String(),
      }),
      fileId: existing,
    );
  }

  /// Rebuilds each stale monthly shard as the union of what Drive has and what
  /// we have, keyed by `id`.
  ///
  /// Drive has no append, so "append-only" is enforced by the merge rather
  /// than the transport: we never drop a line we did not write, which is what
  /// lets two devices write the same file without a lock (docs/SPEC.md §5).
  Future<void> _syncCompletions() async {
    for (final month in await _queue.dirtyCompletionMonths) {
      final parts = month.split('-');
      final from = DateTime.utc(int.parse(parts[0]), int.parse(parts[1]));
      final to = DateTime.utc(from.year, from.month + 1);
      final name = '$month.ndjson';

      final fileId = await _api.findFile(
        parentId: _completionsFolderId!,
        name: name,
      );
      final remoteRaw = fileId == null ? null : await _api.downloadText(fileId);

      final byId = <String, CompletionLog>{};
      for (final log in _parseNdjson(remoteRaw)) {
        byId[log.id] = log;
      }
      // Remote lines this device has never seen — another phone, or an agent.
      await _local.importCompletions(byId.values);

      for (final log in await _local.completionsInRange(from, to)) {
        byId[log.id] = log;
      }

      final merged = byId.values.toList()
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      await _api.uploadText(
        parentId: _completionsFolderId!,
        name: name,
        content: merged.map((l) => jsonEncode(l.toJson())).join('\n'),
        fileId: fileId,
        mimeType: 'application/x-ndjson',
      );

      await _queue.clearCompletionMonth(month);
    }
  }

  /// Skips lines that don't parse instead of failing the shard. One corrupt
  /// line — a half-written append, a hand edit gone wrong — should cost that
  /// line's history, not the whole month's.
  Iterable<CompletionLog> _parseNdjson(String? raw) sync* {
    if (raw == null) return;
    for (final line in const LineSplitter().convert(raw)) {
      if (line.trim().isEmpty) continue;
      try {
        yield CompletionLog.fromJson(jsonDecode(line) as Map<String, dynamic>);
      } on Object {
        continue;
      }
    }
  }
}
