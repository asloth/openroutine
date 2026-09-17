import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/screens/routine_form/routine_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    hide Routine;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';

// Wrapped in a real GoRouter, not a bare MaterialApp, because the screen
// calls context.pop() on save — that throws without a GoRouter ancestor.
// GoRouter also throws ("nothing to pop") if the form screen is the only
// stack entry, so the test navigates '/' -> '/form' itself to give pop()
// somewhere to land.
GoRouter _routerTo({String? routineId, ScheduleMode? initialMode}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(
        path: '/form',
        builder: (context, state) =>
            RoutineFormScreen(routineId: routineId, initialMode: initialMode),
      ),
    ],
  );
}

/// `alwaysUse24HourFormat` overrides the ambient MediaQuery so a test can pin
/// the clock format the way `_StartTime` on the routines list does, instead
/// of depending on whatever the test host's locale happens to produce.
Widget _wrap(
  GoRouter router,
  StorageAdapter adapter, {
  bool? alwaysUse24HourFormat,
}) {
  return ProviderScope(
    overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: alwaysUse24HourFormat == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: alwaysUse24HourFormat),
              child: child!,
            ),
    ),
  );
}

Future<AppDatabase> _seededDb(Routine routine) async {
  final db = AppDatabase(NativeDatabase.memory());
  final adapter = LocalAdapter(db);
  await adapter.saveRoutine(routine);
  return db;
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

  // Onboarding ends by opening the builder on the kind of routine the user
  // picked, so the choice they just made isn't lost on arrival.
  testWidgets('a new routine can start on Scheduled', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final router = _routerTo(initialMode: ScheduleMode.scheduled);
    await tester.pumpWidget(_wrap(router, LocalAdapter(db)));
    router.push('/form');
    await tester.pumpAndSettle();

    final segments = tester.widget<SegmentedButton<ScheduleMode>>(
      find.byType(SegmentedButton<ScheduleMode>),
    );
    expect(segments.selected, {ScheduleMode.scheduled});
    expect(find.byType(FilterChip), findsNWidgets(DayOfWeek.values.length));
  });

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

  testWidgets('the form asks for no moment', (tester) async {
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

    // Moments are gone: a routine is reached through its schedule alone.
    expect(find.text(l10n.routineFormNameLabel), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String?>), findsNothing);
    expect(find.textContaining('oment'), findsNothing);
  });

  group('start time', () {
    testWidgets(
      'editing a routine with a stored start time opens the picker at that time',
      (tester) async {
        final now = DateTime.utc(2026, 1, 1);
        final db = await _seededDb(
          Routine(
            id: 'r1',
            name: 'Morning',
            schedule: const Schedule(
              mode: ScheduleMode.scheduled,
              days: [DayOfWeek.mon],
              startTime: '07:30',
            ),
            stepIds: const [],
            createdAt: now,
            updatedAt: now,
          ),
        );
        addTearDown(db.close);
        final adapter = LocalAdapter(db);
        final router = _routerTo(routineId: 'r1');
        await tester.pumpWidget(_wrap(router, adapter));
        router.push('/form');
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        )!;
        await tester.tap(find.text(l10n.routineFormStartTimeLabel));
        await tester.pumpAndSettle();

        final dialog = tester.widget<TimePickerDialog>(
          find.byType(TimePickerDialog),
        );
        expect(dialog.initialTime, const TimeOfDay(hour: 7, minute: 30));
      },
    );

    testWidgets(
      'displays the stored start time formatted for a 12-hour clock',
      (tester) async {
        final now = DateTime.utc(2026, 1, 1);
        final db = await _seededDb(
          Routine(
            id: 'r1',
            name: 'Morning',
            schedule: const Schedule(
              mode: ScheduleMode.scheduled,
              days: [DayOfWeek.mon],
              startTime: '07:30',
            ),
            stepIds: const [],
            createdAt: now,
            updatedAt: now,
          ),
        );
        addTearDown(db.close);
        final adapter = LocalAdapter(db);
        final router = _routerTo(routineId: 'r1');
        await tester.pumpWidget(
          _wrap(router, adapter, alwaysUse24HourFormat: false),
        );
        router.push('/form');
        await tester.pumpAndSettle();

        expect(find.text('7:30 AM'), findsOneWidget);
        expect(find.text('07:30'), findsNothing);
      },
    );

    testWidgets(
      'displays the stored start time formatted for a 24-hour clock',
      (tester) async {
        final now = DateTime.utc(2026, 1, 1);
        final db = await _seededDb(
          Routine(
            id: 'r1',
            name: 'Morning',
            schedule: const Schedule(
              mode: ScheduleMode.scheduled,
              days: [DayOfWeek.mon],
              startTime: '07:30',
            ),
            stepIds: const [],
            createdAt: now,
            updatedAt: now,
          ),
        );
        addTearDown(db.close);
        final adapter = LocalAdapter(db);
        final router = _routerTo(routineId: 'r1');
        await tester.pumpWidget(
          _wrap(router, adapter, alwaysUse24HourFormat: true),
        );
        router.push('/form');
        await tester.pumpAndSettle();

        expect(find.text('07:30'), findsOneWidget);
        expect(find.text('7:30 AM'), findsNothing);
      },
    );
  });

  group('Scheduled requires days and a start time', () {
    testWidgets(
      'saving with a time but no days shows the days error and does not save',
      (tester) async {
        final now = DateTime.utc(2026, 1, 1);
        final db = await _seededDb(
          Routine(
            id: 'r1',
            name: 'Morning',
            schedule: const Schedule(
              mode: ScheduleMode.scheduled,
              days: [],
              startTime: '07:30',
            ),
            stepIds: const [],
            createdAt: now,
            updatedAt: now,
          ),
        );
        addTearDown(db.close);
        final adapter = LocalAdapter(db);
        final router = _routerTo(routineId: 'r1');
        await tester.pumpWidget(_wrap(router, adapter));
        router.push('/form');
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        )!;
        await tester.tap(find.byTooltip(l10n.commonSave));
        await tester.pumpAndSettle();

        expect(find.text(l10n.routineFormDaysRequired), findsOneWidget);
        expect(find.text(l10n.routineFormStartTimeRequired), findsNothing);

        final rows = await db.select(db.routines).get();
        expect(rows, hasLength(1));
        expect(rows.single.updatedAt.isAtSameMomentAs(now), isTrue);
      },
    );

    testWidgets(
      'saving with days but no time shows the start-time error and does not save',
      (tester) async {
        final now = DateTime.utc(2026, 1, 1);
        final db = await _seededDb(
          Routine(
            id: 'r1',
            name: 'Morning',
            schedule: const Schedule(
              mode: ScheduleMode.scheduled,
              days: [DayOfWeek.mon],
              startTime: null,
            ),
            stepIds: const [],
            createdAt: now,
            updatedAt: now,
          ),
        );
        addTearDown(db.close);
        final adapter = LocalAdapter(db);
        final router = _routerTo(routineId: 'r1');
        await tester.pumpWidget(_wrap(router, adapter));
        router.push('/form');
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        )!;
        await tester.tap(find.byTooltip(l10n.commonSave));
        await tester.pumpAndSettle();

        expect(find.text(l10n.routineFormStartTimeRequired), findsOneWidget);
        expect(find.text(l10n.routineFormDaysRequired), findsNothing);

        final rows = await db.select(db.routines).get();
        expect(rows, hasLength(1));
        expect(rows.single.updatedAt.isAtSameMomentAs(now), isTrue);
      },
    );

    testWidgets('fixing the missing day clears the days error', (tester) async {
      final now = DateTime.utc(2026, 1, 1);
      final db = await _seededDb(
        Routine(
          id: 'r1',
          name: 'Morning',
          schedule: const Schedule(
            mode: ScheduleMode.scheduled,
            days: [],
            startTime: '07:30',
          ),
          stepIds: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );
      addTearDown(db.close);
      final adapter = LocalAdapter(db);
      final router = _routerTo(routineId: 'r1');
      await tester.pumpWidget(_wrap(router, adapter));
      router.push('/form');
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      )!;
      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();
      expect(find.text(l10n.routineFormDaysRequired), findsOneWidget);

      await tester.tap(find.text(l10n.dayMon));
      await tester.pumpAndSettle();

      expect(find.text(l10n.routineFormDaysRequired), findsNothing);
    });

    testWidgets('a Flexible save still works with no days and no time', (
      tester,
    ) async {
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
      await tester.enterText(find.byType(TextFormField).first, 'Reading');
      // Flexible is the default mode — no day chips or start-time tile
      // even appear, so there is nothing to fill in before saving.
      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      final rows = await db.select(db.routines).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Reading');
    });
  });
}
