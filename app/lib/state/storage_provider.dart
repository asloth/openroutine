import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_prefs.dart';
import '../services/storage/drift/app_database.dart' show AppDatabase;
import '../services/storage/drive/drive_adapter.dart';
import '../services/storage/local_adapter.dart';
import '../services/storage/storage_adapter.dart';
import 'app_prefs_provider.dart';
import 'sync_provider.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

/// The drift-backed adapter, always available regardless of storage mode.
///
/// Drive does not replace it — DriveAdapter wraps it — so the sync worker
/// needs it directly, and screens still get theirs through
/// [storageAdapterProvider].
final localAdapterProvider = Provider<LocalAdapter>((ref) {
  return LocalAdapter(ref.watch(appDatabaseProvider));
});

/// The seam M2 left for M4. Switching modes swaps a wrapper, not a backend:
/// the same rows back both, so turning Drive on or off never moves data and
/// never risks losing it.
final storageAdapterProvider = Provider<StorageAdapter>((ref) {
  final local = ref.watch(localAdapterProvider);
  final mode = ref.watch(storageModeSettingProvider);
  if (mode == StorageMode.local) return local;

  return DriveAdapter(
    local: local,
    queue: ref.watch(syncQueueProvider),
    onLocalChange: () =>
        ref.read(syncControllerProvider.notifier).onLocalChange(),
  );
});
