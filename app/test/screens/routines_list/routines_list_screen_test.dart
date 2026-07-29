import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/screens/routines_list/routines_list_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';

Widget _wrap(StorageAdapter adapter) {
  return ProviderScope(
    overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RoutinesListScreen(),
    ),
  );
}

/// The screen watches routinesProvider, a drift Stream. Flutter_test's
/// automatic end-of-test teardown disposes the widget tree — and with it
/// the stream subscription — *after* the test body returns, too late for
/// any pump() inside the test to flush the resulting internal timer.
/// Replacing the tree with something trivial and pumping once, before the
/// test body ends, forces that disposal (and its timer) to happen somewhere
/// we can still flush it.
Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets(
    'empty state shows the empty-scheduled message with no routines',
    (tester) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.routinesEmptyScheduled), findsOneWidget);

      await _disposeCleanly(tester);
    },
  );

  testWidgets('a saved routine renders in the list', (tester) async {
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    final now = DateTime.utc(2026, 1, 1);
    await adapter.saveRoutine(
      Routine(
        id: 'r1',
        name: 'Morning Routine',
        triggerId: null,
        schedule: const Schedule(
          mode: ScheduleMode.scheduled,
          days: [DayOfWeek.mon],
        ),
        stepIds: const [],
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.text('Morning Routine'), findsOneWidget);

    await _disposeCleanly(tester);
  });
}
