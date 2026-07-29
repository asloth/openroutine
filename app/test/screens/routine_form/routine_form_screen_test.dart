import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/routine_form/routine_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart';
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';

// Wrapped in a real GoRouter, not a bare MaterialApp, because the screen
// calls context.pop() on save — that throws without a GoRouter ancestor.
// GoRouter also throws ("nothing to pop") if the form screen is the only
// stack entry, so the test navigates '/' -> '/form' itself to give pop()
// somewhere to land.
GoRouter _routerTo() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(
        path: '/form',
        builder: (context, state) => const RoutineFormScreen(),
      ),
    ],
  );
}

Widget _wrap(GoRouter router, StorageAdapter adapter) {
  return ProviderScope(
    overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets(
    'submitting with an empty name shows a validation error and does not save',
    (tester) async {
      // A one-shot .get() query, not adapter.watchRoutines() — that opens a
      // drift Stream whose async cancellation leaves a pending Timer that
      // flutter_test's teardown check flags, since nothing in this test
      // keeps the stream alive long enough to settle it cleanly.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = LocalAdapter(db);
      final router = _routerTo();
      await tester.pumpWidget(_wrap(router, adapter));
      router.push('/form');
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      expect(find.text(l10n.routineFormNameRequired), findsOneWidget);
      expect(await db.select(db.routines).get(), isEmpty);
    },
  );

  testWidgets(
    'submitting with a name persists a new routine via the storage adapter',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = LocalAdapter(db);
      final router = _routerTo();
      await tester.pumpWidget(_wrap(router, adapter));
      router.push('/form');
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      await tester.enterText(
        find.byType(TextFormField).first,
        'Evening Routine',
      );
      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      final rows = await db.select(db.routines).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Evening Routine');
    },
  );
}
