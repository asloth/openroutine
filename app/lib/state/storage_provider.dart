import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage/drift/app_database.dart' show AppDatabase;
import '../services/storage/local_adapter.dart';
import '../services/storage/storage_adapter.dart';

/// The seam M4 swaps: today this always resolves to LocalAdapter, backed by
/// a single AppDatabase for the app's lifetime. Adding a DriveAdapter later
/// means changing this provider, not any screen.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final storageAdapterProvider = Provider<StorageAdapter>((ref) {
  return LocalAdapter(ref.watch(appDatabaseProvider));
});
