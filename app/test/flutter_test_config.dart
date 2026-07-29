import 'dart:async';

import 'package:drift/drift.dart';

/// Silences drift's "database class created multiple times" warning, which
/// is a false positive here: each test that touches AppDatabase constructs
/// its own isolated in-memory NativeDatabase, but drift's heuristic checks
/// for repeated construction process-wide, not per-instance — and
/// `flutter test` runs every file in one process.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
