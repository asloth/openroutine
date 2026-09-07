import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../services/auth/drive_auth.dart';
import '../services/storage/drive/drive_api_client.dart';
import '../services/storage/drive/drive_sync.dart';
import '../services/storage/drive/sync_queue.dart';
import 'app_prefs_provider.dart';
import 'import_export_provider.dart';
import 'storage_provider.dart';

part 'sync_provider.g.dart';

/// What Settings shows, and what decides whether a retry is worth scheduling.
///
/// `offline` and `needsReauth` are separate states rather than error strings
/// because they mean opposite things to the app: offline resolves itself and
/// should retry; a lapsed grant never resolves on its own and must stop
/// retrying and ask the user. While the Cloud project sits in Testing, Google
/// expires refresh tokens weekly, so `needsReauth` is a routine occurrence.
/// `remoteSchemaNewer` joins them for the same reason: the folder was written
/// by a newer build, this one must not write it back (docs/SPEC.md §4), and
/// the user's edits are sitting on the device until they update. That is not
/// an error, it is a fact about their install, and retrying will not change
/// it.
enum SyncStatus {
  idle,
  syncing,
  offline,
  needsReauth,
  remoteSchemaNewer,
  error,
  disconnected,
}

class SyncSnapshot {
  const SyncSnapshot({
    required this.status,
    this.lastSyncAt,
    this.pendingChanges = false,
  });

  final SyncStatus status;
  final DateTime? lastSyncAt;
  final bool pendingChanges;

  SyncSnapshot copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    bool? pendingChanges,
  }) => SyncSnapshot(
    status: status ?? this.status,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    pendingChanges: pendingChanges ?? this.pendingChanges,
  );
}

@Riverpod(keepAlive: true)
DriveAuth driveAuth(Ref ref) {
  final auth = DriveAuth();
  ref.onDispose(auth.dispose);
  return auth;
}

@Riverpod(keepAlive: true)
SyncQueue syncQueue(Ref ref) => SyncQueue(ref.watch(appDatabaseProvider));

/// Drive is unavailable — not broken — in builds without OAuth client IDs.
/// That is the state a fresh clone of the public repo is in, so both storage
/// pickers key off this rather than assuming Drive always exists.
@Riverpod(keepAlive: true)
bool driveAvailable(Ref ref) => DriveConfig.isConfigured;

/// Owns the sync lifecycle: when to run, when to retry, what the UI shows.
///
/// Writes do not go through here — DriveAdapter commits them locally and then
/// calls [onLocalChange], which is the only thing this controller debounces.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  Timer? _debounce;
  Timer? _retry;
  DriveSync? _sync;

  /// Long enough that renaming a step letter by letter is one upload, short
  /// enough that closing the app right after an edit still catches it.
  static const _debounceWindow = Duration(seconds: 2);

  @override
  SyncSnapshot build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _retry?.cancel();
    });
    return const SyncSnapshot(status: SyncStatus.disconnected);
  }

  /// Restores a previous grant silently at startup. Never shows UI, so it is
  /// safe to call before the first frame.
  Future<void> restore() async {
    if (!ref.read(driveAvailableProvider)) return;
    final auth = ref.read(driveAuthProvider);
    final restored = await auth.restore();
    if (!restored) {
      state = const SyncSnapshot(status: SyncStatus.disconnected);
      return;
    }
    state = state.copyWith(status: SyncStatus.idle);
    unawaited(syncNow());
  }

  /// Interactive. Must come from a user gesture.
  Future<void> connect() async {
    final auth = ref.read(driveAuthProvider);
    try {
      await auth.connect();
    } on Object catch (e) {
      // Any failure to obtain the grant lands in the same place: the user has
      // to try again. Cancelling the account picker arrives here too, which is
      // why this is not treated as an error state.
      debugPrint('Drive connect failed: $e');
      state = state.copyWith(status: SyncStatus.needsReauth);
      return;
    }
    state = state.copyWith(status: SyncStatus.idle);
    // This method is reached only from the explicit Drive-connect gesture.
    // Preparing records the user's confirmation that every known old writer is
    // upgraded, disconnected, or revoked before any folder/data mutation.
    if (!await (await _syncer()).prepareCutover()) {
      state = state.copyWith(status: SyncStatus.error);
      return;
    }
    await ref.read(syncQueueProvider).markRoutinesDirty();
    await syncNow();
  }

  Future<void> disconnect() async {
    _debounce?.cancel();
    _retry?.cancel();
    await ref.read(driveAuthProvider).disconnect();
    _sync = null;
    state = const SyncSnapshot(status: SyncStatus.disconnected);
  }

  /// Called by DriveAdapter after every local write.
  void onLocalChange() {
    if (state.status == SyncStatus.disconnected) return;
    state = state.copyWith(pendingChanges: true);
    _debounce?.cancel();
    _debounce = Timer(_debounceWindow, () => unawaited(syncNow()));
  }

  /// Called when the app returns to the foreground, and after connecting.
  Future<void> syncNow() async {
    if (state.status == SyncStatus.disconnected) return;
    if (state.status == SyncStatus.syncing) return;

    _debounce?.cancel();
    _retry?.cancel();
    state = state.copyWith(status: SyncStatus.syncing);

    final queue = ref.read(syncQueueProvider);
    final outcome = await (await _syncer()).sync();

    switch (outcome) {
      case SyncOutcome.synced:
        final pendingChanges = await queue.hasWork;
        state = SyncSnapshot(
          status: SyncStatus.idle,
          lastSyncAt: await queue.lastSyncAt,
          pendingChanges: pendingChanges,
        );
        // A debounce can fire while this run is still uploading. Generational
        // acknowledgment keeps that write dirty; this immediate follow-up is
        // what guarantees it is uploaded without waiting for another event.
        if (pendingChanges) unawaited(syncNow());
      case SyncOutcome.offline:
        state = state.copyWith(status: SyncStatus.offline);
        _scheduleRetry(queue.backoff);
      case SyncOutcome.remoteSchemaNewer:
        // No retry, for the same reason as needsReauth: this resolves when the
        // app is updated, never on a timer. pendingChanges is left as it is —
        // the edits really are still waiting, and saying so is the point.
        state = state.copyWith(status: SyncStatus.remoteSchemaNewer);
      case SyncOutcome.needsReauth:
        // No retry on purpose: the grant will not come back on its own, and a
        // timer would only spend battery rediscovering that.
        state = state.copyWith(status: SyncStatus.needsReauth);
      case SyncOutcome.failed:
        state = state.copyWith(status: SyncStatus.error);
        _scheduleRetry(queue.backoff);
    }
  }

  void _scheduleRetry(Duration delay) {
    _retry?.cancel();
    final wait = delay == Duration.zero ? const Duration(seconds: 30) : delay;
    _retry = Timer(wait, () => unawaited(syncNow()));
  }

  Future<DriveSync> _syncer() async {
    final existing = _sync;
    if (existing != null) return existing;

    final auth = ref.read(driveAuthProvider);
    final prefs = ref.read(appPrefsProvider);
    return _sync = DriveSync(
      api: HttpDriveApiClient(headers: auth.headers),
      local: ref.read(localAdapterProvider),
      queue: ref.read(syncQueueProvider),
      validator: await ref.read(schemaValidatorProvider.future),
      installClientId: prefs.installClientId(() => const Uuid().v4()),
      folderReadme: await rootBundle.loadString(
        'assets/drive_folder_readme.md',
      ),
      readApproval: () async => prefs.driveCutoverApproval,
      saveApproval: prefs.setDriveCutoverApproval,
    );
  }
}
