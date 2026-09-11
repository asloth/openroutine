import 'dart:ui' show Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/models/trigger.dart';
import 'package:openroutine/screens/routines_list/routines_list_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/clock_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/tinted/tinted.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screen arms routine reminders whenever the list resolves, which reads
/// the reminder lead time out of prefs. Nothing here asserts on notifications
/// — `NotificationService.init` fails harmlessly with no platform channel, so
/// no reminder is ever actually scheduled — but the prefs it reads on the way
/// there still have to exist.
late SharedPreferences _prefs;

/// Records the last path this test's router navigated to, so a test can
/// assert a control's destination without a real screen behind each route.
class _RouteRecorder {
  String? last;
}

GoRouter _router(_RouteRecorder recorder) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const RoutinesListScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        recorder.last = '/settings';
        return const Scaffold(body: Text('Settings screen'));
      },
    ),
    GoRoute(
      path: '/routines/new',
      builder: (context, state) {
        recorder.last = '/routines/new';
        return const Scaffold(body: Text('New routine screen'));
      },
    ),
    GoRoute(
      path: '/routines/:routineId',
      builder: (context, state) {
        recorder.last = '/routines/${state.pathParameters['routineId']}';
        return Scaffold(
          body: Text('Routine ${state.pathParameters['routineId']}'),
        );
      },
    ),
    GoRoute(
      path: '/routines/:routineId/timer',
      builder: (context, state) {
        recorder.last =
            '/routines/${state.pathParameters['routineId']}/timer'
            '?mode=${state.uri.queryParameters['mode']}';
        return const Scaffold(body: Text('Timer screen'));
      },
    ),
  ],
);

Widget _wrap(
  StorageAdapter adapter, {
  _RouteRecorder? recorder,
  DateTime? now,
}) {
  return ProviderScope(
    overrides: [
      storageAdapterProvider.overrideWithValue(adapter),
      sharedPreferencesProvider.overrideWithValue(_prefs),
      if (now != null) clockProvider.overrideWithValue(now),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      routerConfig: _router(recorder ?? _RouteRecorder()),
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

Future<LocalAdapter> _adapterWithRoutine({
  required String id,
  required String name,
  ScheduleMode mode = ScheduleMode.scheduled,
  String? triggerId,
  String? startTime,
  List<DayOfWeek> days = const [DayOfWeek.mon],
  List<RoutineStep> steps = const [],
}) async {
  final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
  final now = DateTime.utc(2026, 1, 1);
  await adapter.saveRoutine(
    Routine(
      id: id,
      name: name,
      triggerId: triggerId,
      schedule: Schedule(mode: mode, days: days, startTime: startTime),
      stepIds: [for (final step in steps) step.id],
      createdAt: now,
      updatedAt: now,
    ),
  );
  for (final step in steps) {
    await adapter.saveStep(step);
  }
  return adapter;
}

/// The inverse of `ScheduleTime.weekday`, so a test can schedule a routine on
/// whatever weekday its fixed clock actually falls on.
DayOfWeek _dayOfWeek(DateTime date) => switch (date.weekday) {
  DateTime.monday => DayOfWeek.mon,
  DateTime.tuesday => DayOfWeek.tue,
  DateTime.wednesday => DayOfWeek.wed,
  DateTime.thursday => DayOfWeek.thu,
  DateTime.friday => DayOfWeek.fri,
  DateTime.saturday => DayOfWeek.sat,
  _ => DayOfWeek.sun,
};

/// "HH:MM" per schemas/routine.schema.json.
String _hhmm(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// Noon today (real "today," not a fixed calendar date): late enough in the
/// day that adding or subtracting a handful of minutes never crosses
/// midnight, and "today" so it lines up with `routineCompletionsProvider`,
/// which always reads the real device clock for its own "today."
DateTime _fixedNow() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 12);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets(
    'empty state shows the empty-scheduled message with no routines',
    (tester) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      expect(find.text(l10n.routinesEmptyScheduled), findsOneWidget);

      await _disposeCleanly(tester);
    },
  );

  testWidgets('a saved routine renders in the list', (tester) async {
    final adapter = await _adapterWithRoutine(
      id: 'r1',
      name: 'Morning Routine',
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.text('Morning Routine'), findsOneWidget);

    await _disposeCleanly(tester);
  });

  testWidgets('guides setup without selecting steps when no core steps exist', (
    tester,
  ) async {
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    final now = DateTime.utc(2026, 1, 1);
    await adapter.saveRoutine(
      Routine(
        id: 'r1',
        name: 'Morning Routine',
        triggerId: null,
        schedule: const Schedule(mode: ScheduleMode.scheduled, days: []),
        stepIds: const ['s1'],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await adapter.saveRoutine(
      Routine(
        id: 'r2',
        name: 'Other Routine',
        triggerId: null,
        schedule: const Schedule(mode: ScheduleMode.scheduled, days: []),
        stepIds: const ['s2'],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await adapter.saveStep(
      RoutineStep(
        id: 's1',
        routineId: 'r1',
        name: 'Core',
        emoji: '✅',
        durationSeconds: 60,
        order: 0,
        noExplicitTime: false,
        isCore: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await adapter.saveStep(
      RoutineStep(
        id: 's2',
        routineId: 'r2',
        name: 'Regular',
        emoji: '✅',
        durationSeconds: 60,
        order: 0,
        noExplicitTime: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RoutinesListScreen)),
    )!;
    expect(find.text(l10n.routinesStartLowMode), findsOneWidget);
    expect(find.text(l10n.routinesLowModeSetupGuidance), findsOneWidget);
    expect((await adapter.getSteps('r2')).single.isCore, isFalse);

    await _disposeCleanly(tester);
  });

  group('header', () {
    testWidgets('shows the app title with no AppBar', (tester) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      expect(find.text(l10n.appTitle), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(PageHeader), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('the settings control navigates to /settings', (tester) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      final recorder = _RouteRecorder();
      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      await tester.tap(find.byTooltip(l10n.settingsTitle));
      await tester.pumpAndSettle();

      expect(recorder.last, '/settings');

      await _disposeCleanly(tester);
    });
  });

  group('segmented control', () {
    testWidgets('replaces the TabBar and switches tabs on tap', (tester) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(PillSegmentedControl), findsOneWidget);
      expect(find.text(l10n.routinesEmptyScheduled), findsOneWidget);

      await tester.tap(find.text(l10n.routinesTabFlexible));
      await tester.pumpAndSettle();

      expect(find.text(l10n.routinesEmptyFlexible), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('swiping the tab content moves the segmented control', (
      tester,
    ) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;

      await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      expect(find.text(l10n.routinesEmptyFlexible), findsOneWidget);
      final segmentSemantics = tester.getSemantics(
        find.text(l10n.routinesTabFlexible),
      );
      expect(
        segmentSemantics.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );

      await _disposeCleanly(tester);
    });
  });

  group('section labels', () {
    testWidgets('a moment group heading renders as a SectionLabel', (
      tester,
    ) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      final now = DateTime.utc(2026, 1, 1);
      await adapter.saveTrigger(
        Trigger(
          id: 't1',
          name: 'Waking up',
          kind: TriggerKind.manual,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await adapter.saveTrigger(
        Trigger(
          id: 't2',
          name: 'Before bed',
          kind: TriggerKind.manual,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await adapter.saveRoutine(
        Routine(
          id: 'r1',
          name: 'Morning Routine',
          triggerId: 't1',
          schedule: const Schedule(mode: ScheduleMode.scheduled, days: []),
          stepIds: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await adapter.saveRoutine(
        Routine(
          id: 'r2',
          name: 'Evening Routine',
          triggerId: 't2',
          schedule: const Schedule(mode: ScheduleMode.scheduled, days: []),
          stepIds: const [],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      expect(find.byType(SectionLabel), findsNWidgets(2));

      await _disposeCleanly(tester);
    });
  });

  group('tinted routine cards', () {
    testWidgets('a card is filled with the accent colors', (tester) async {
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: '07:30',
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;

      final card = tester.widget<TintedCard>(find.byType(TintedCard));
      expect(card.color, colors.fill);
      expect(card.foregroundColor, colors.onFill);

      await _disposeCleanly(tester);
    });

    testWidgets('the start time renders inside the 62px column in onFill', (
      tester,
    ) async {
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: '07:30',
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;

      final timeText = tester.widget<Text>(find.text('7:30 AM'));
      expect(timeText.style?.color, colors.onFill);

      final column = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((box) => box.width == 62)
          .toList();
      expect(column, isNotEmpty);

      await _disposeCleanly(tester);
    });

    testWidgets('Start Low Mode still starts Low Mode for core steps', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 1, 1);
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        steps: [
          RoutineStep(
            id: 's1',
            routineId: 'r1',
            name: 'Core',
            emoji: '✅',
            durationSeconds: 60,
            order: 0,
            noExplicitTime: false,
            isCore: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      final recorder = _RouteRecorder();

      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      await tester.tap(find.text(l10n.routinesStartLowMode));
      await tester.pumpAndSettle();

      expect(recorder.last, '/routines/r1/timer?mode=low');

      await _disposeCleanly(tester);
    });

    testWidgets('tapping a card opens the routine', (tester) async {
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
      );
      final recorder = _RouteRecorder();

      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Morning Routine'));
      await tester.pumpAndSettle();

      expect(recorder.last, '/routines/r1');

      await _disposeCleanly(tester);
    });
  });

  group('FAB', () {
    testWidgets('creates a routine when tapped', (tester) async {
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      final recorder = _RouteRecorder();
      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      await tester.tap(find.byTooltip(l10n.routinesNewRoutine));
      await tester.pumpAndSettle();

      expect(recorder.last, '/routines/new');

      await _disposeCleanly(tester);
    });

    test('is a flat circle with no elevation in every state', () {
      final theme = AppTheme.light().floatingActionButtonTheme;
      expect(theme.shape, const CircleBorder());
      expect(theme.elevation, 0);
      expect(theme.focusElevation, 0);
      expect(theme.hoverElevation, 0);
      expect(theme.highlightElevation, 0);
      expect(theme.disabledElevation, 0);
    });
  });

  group('text scale', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders without overflow at ${scale}x text scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final adapter = await _adapterWithRoutine(
          id: 'r1',
          name: 'A Fairly Long Morning Routine Name',
          startTime: '07:30',
          steps: [
            RoutineStep(
              id: 's1',
              routineId: 'r1',
              name: 'Core',
              emoji: '✅',
              durationSeconds: 60,
              order: 0,
              noExplicitTime: false,
              isCore: true,
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          ],
        );

        await tester.pumpWidget(_wrap(adapter));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        await _disposeCleanly(tester);
      });
    }

    testWidgets('an upcoming card does not overflow at 2.0x text scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final fixedNow = _fixedNow();
      final start = fixedNow.add(const Duration(minutes: 10));
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'A Fairly Long Morning Routine Name',
        startTime: _hhmm(start),
        days: [_dayOfWeek(fixedNow)],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await _disposeCleanly(tester);
    });
  });

  group('upcoming state', () {
    testWidgets('a routine starting soon is green and shows a countdown', (
      tester,
    ) async {
      final fixedNow = _fixedNow();
      final start = fixedNow.add(const Duration(minutes: 10));
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(start),
        days: [_dayOfWeek(fixedNow)],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;
      final l10n = AppLocalizations.of(context)!;

      // This single scheduled routine also qualifies as "next up," which
      // renders as its own hero `TintedCard` above the moment group — so
      // this test targets the *last* `TintedCard`, the routine's own card in
      // its moment group, the same one this test covered before that hero
      // card existed.
      final card = tester.widget<TintedCard>(find.byType(TintedCard).last);
      expect(card.color, colors.upcomingFill);
      expect(card.foregroundColor, colors.onUpcomingFill);
      expect(
        find.descendant(
          of: find.byType(TintedCard).last,
          matching: find.textContaining(l10n.routinesUpcomingIn(10)),
        ),
        findsOneWidget,
      );

      await _disposeCleanly(tester);
    });

    testWidgets('a routine in progress is green and shows "Now"', (
      tester,
    ) async {
      final fixedNow = _fixedNow();
      final start = fixedNow.subtract(const Duration(minutes: 10));
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(start),
        days: [_dayOfWeek(fixedNow)],
        steps: [
          RoutineStep(
            id: 's1',
            routineId: 'r1',
            name: 'Core',
            emoji: '✅',
            durationSeconds: const Duration(minutes: 30).inSeconds,
            order: 0,
            noExplicitTime: false,
            isCore: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;
      final l10n = AppLocalizations.of(context)!;

      // Same reasoning as the previous test: this routine also qualifies as
      // "next up," so its moment-group card is the *last* `TintedCard`.
      final card = tester.widget<TintedCard>(find.byType(TintedCard).last);
      expect(card.color, colors.upcomingFill);
      expect(card.foregroundColor, colors.onUpcomingFill);
      expect(
        find.descendant(
          of: find.byType(TintedCard).last,
          matching: find.textContaining(l10n.routinesUpcomingNow),
        ),
        findsOneWidget,
      );

      await _disposeCleanly(tester);
    });

    testWidgets('a routine already completed today keeps the accent', (
      tester,
    ) async {
      final fixedNow = _fixedNow();
      final start = fixedNow.subtract(const Duration(minutes: 10));
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(start),
        days: [_dayOfWeek(fixedNow)],
        steps: [
          RoutineStep(
            id: 's1',
            routineId: 'r1',
            name: 'Core',
            emoji: '✅',
            durationSeconds: const Duration(minutes: 30).inSeconds,
            order: 0,
            noExplicitTime: false,
            isCore: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final today = DateTime.now();
      final completedAt = DateTime(
        today.year,
        today.month,
        today.day,
        8,
      ).toUtc();
      await adapter.appendCompletion(
        CompletionLog(
          id: 'c1',
          routineId: 'r1',
          startedAt: completedAt,
          endedAt: completedAt.add(const Duration(minutes: 5)),
          outcome: CompletionOutcome.completed,
          steps: const [],
        ),
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;
      final l10n = AppLocalizations.of(context)!;

      final card = tester.widget<TintedCard>(find.byType(TintedCard));
      expect(card.color, colors.fill);
      expect(card.foregroundColor, colors.onFill);
      expect(find.textContaining(l10n.routinesUpcomingNow), findsNothing);

      await _disposeCleanly(tester);
    });

    testWidgets('an upcoming card still navigates and Low Mode still works', (
      tester,
    ) async {
      final fixedNow = _fixedNow();
      final start = fixedNow.subtract(const Duration(minutes: 10));
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(start),
        days: [_dayOfWeek(fixedNow)],
        steps: [
          RoutineStep(
            id: 's1',
            routineId: 'r1',
            name: 'Core',
            emoji: '✅',
            durationSeconds: const Duration(minutes: 30).inSeconds,
            order: 0,
            noExplicitTime: false,
            isCore: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final recorder = _RouteRecorder();

      await tester.pumpWidget(
        _wrap(adapter, now: fixedNow, recorder: recorder),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;
      // This routine also qualifies as "next up," so its moment-group card
      // is the *last* `TintedCard` — the hero card above it is a separate
      // one with its own "Start Timer" action, not "Start Low Mode".
      final card = tester.widget<TintedCard>(find.byType(TintedCard).last);
      expect(card.color, colors.upcomingFill);

      final l10n = AppLocalizations.of(context)!;
      await tester.tap(find.text(l10n.routinesStartLowMode));
      await tester.pumpAndSettle();
      expect(recorder.last, '/routines/r1/timer?mode=low');

      await _disposeCleanly(tester);
    });

    testWidgets('an upcoming card still opens the routine on tap', (
      tester,
    ) async {
      final fixedNow = _fixedNow();
      final start = fixedNow.add(const Duration(minutes: 10));
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(start),
        days: [_dayOfWeek(fixedNow)],
      );
      final recorder = _RouteRecorder();

      await tester.pumpWidget(
        _wrap(adapter, now: fixedNow, recorder: recorder),
      );
      await tester.pumpAndSettle();

      // This routine also qualifies as "next up," so its name now appears
      // twice — once on the hero card, once on its moment-group card below.
      // Both open the same routine; this test taps the moment-group copy,
      // the *last* one, matching what it tapped before the hero card
      // existed.
      await tester.tap(find.text('Morning Routine').last);
      await tester.pumpAndSettle();

      expect(recorder.last, '/routines/r1');

      await _disposeCleanly(tester);
    });
  });

  group('next up card', () {
    testWidgets(
      'shows the earliest-remaining routine, which still appears in its '
      'moment group',
      (tester) async {
        final fixedNow = _fixedNow();
        final scheduledToday = [_dayOfWeek(fixedNow)];
        final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
        final createdAt = DateTime.utc(2026, 1, 1);
        await adapter.saveRoutine(
          Routine(
            id: 'later',
            name: 'Later Routine',
            triggerId: null,
            schedule: Schedule(
              mode: ScheduleMode.scheduled,
              days: scheduledToday,
              startTime: _hhmm(fixedNow.add(const Duration(minutes: 60))),
            ),
            stepIds: const [],
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
        await adapter.saveRoutine(
          Routine(
            id: 'earlier',
            name: 'Earlier Routine',
            triggerId: null,
            schedule: Schedule(
              mode: ScheduleMode.scheduled,
              days: scheduledToday,
              startTime: _hhmm(fixedNow.add(const Duration(minutes: 30))),
            ),
            stepIds: const [],
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );

        await tester.pumpWidget(_wrap(adapter, now: fixedNow));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(RoutinesListScreen)),
        )!;
        expect(find.text(l10n.routinesNextUp.toUpperCase()), findsOneWidget);
        // The hero card names the earlier routine; the moment group below
        // still lists both, so the earlier routine's name appears twice.
        expect(find.text('Earlier Routine'), findsNWidgets(2));
        expect(find.text('Later Routine'), findsOneWidget);

        await _disposeCleanly(tester);
      },
    );

    testWidgets('is green when upcoming and accent otherwise', (tester) async {
      final fixedNow = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(fixedNow.add(const Duration(minutes: 10))),
        days: [_dayOfWeek(fixedNow)],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;
      final l10n = AppLocalizations.of(context)!;

      final heroCard = tester.widget<TintedCard>(
        find.byKey(const Key('nextUpCard')),
      );
      expect(heroCard.color, colors.upcomingFill);
      expect(heroCard.foregroundColor, colors.onUpcomingFill);
      expect(
        find.descendant(
          of: find.byKey(const Key('nextUpCard')),
          matching: find.textContaining(l10n.routinesUpcomingIn(10)),
        ),
        findsOneWidget,
      );

      await _disposeCleanly(tester);
    });

    testWidgets('is the accent color when not inside its upcoming window', (
      tester,
    ) async {
      final fixedNow = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(fixedNow.add(const Duration(hours: 2))),
        days: [_dayOfWeek(fixedNow)],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(RoutinesListScreen));
      final colors = context.routineCardColors;

      final heroCard = tester.widget<TintedCard>(
        find.byKey(const Key('nextUpCard')),
      );
      expect(heroCard.color, colors.fill);
      expect(heroCard.foregroundColor, colors.onFill);

      await _disposeCleanly(tester);
    });

    testWidgets('Start Timer navigates to the timer route', (tester) async {
      final fixedNow = _fixedNow();
      final now = DateTime.utc(2026, 1, 1);
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(fixedNow.add(const Duration(minutes: 10))),
        days: [_dayOfWeek(fixedNow)],
        steps: [
          RoutineStep(
            id: 's1',
            routineId: 'r1',
            name: 'Stretch',
            emoji: '🧘',
            durationSeconds: 60,
            order: 0,
            noExplicitTime: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      final recorder = _RouteRecorder();

      await tester.pumpWidget(
        _wrap(adapter, now: fixedNow, recorder: recorder),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      await tester.tap(find.text(l10n.routineDetailStartTimer));
      await tester.pumpAndSettle();

      expect(recorder.last, '/routines/r1/timer?mode=null');

      await _disposeCleanly(tester);
    });

    testWidgets('tapping the card elsewhere opens the routine', (tester) async {
      final fixedNow = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(fixedNow.add(const Duration(minutes: 10))),
        days: [_dayOfWeek(fixedNow)],
      );
      final recorder = _RouteRecorder();

      await tester.pumpWidget(
        _wrap(adapter, now: fixedNow, recorder: recorder),
      );
      await tester.pumpAndSettle();

      // The hero card's copy of the routine's name is the *first* match —
      // the moment group's copy comes after it.
      await tester.tap(find.text('Morning Routine').first);
      await tester.pumpAndSettle();

      expect(recorder.last, '/routines/r1');

      await _disposeCleanly(tester);
    });

    testWidgets('no card when nothing is left today', (tester) async {
      final fixedNow = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning Routine',
        startTime: _hhmm(fixedNow.subtract(const Duration(minutes: 10))),
        days: [_dayOfWeek(fixedNow)],
      );
      final completedAt = fixedNow.subtract(const Duration(minutes: 5)).toUtc();
      await adapter.appendCompletion(
        CompletionLog(
          id: 'c1',
          routineId: 'r1',
          startedAt: completedAt,
          endedAt: completedAt,
          outcome: CompletionOutcome.completed,
          steps: const [],
        ),
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      expect(find.text(l10n.routinesNextUp.toUpperCase()), findsNothing);
      expect(find.byKey(const Key('nextUpCard')), findsNothing);
      // The routine itself still renders in its moment group.
      expect(find.text('Morning Routine'), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('never shown on the Flexible tab', (tester) async {
      final fixedNow = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Evening Wind-down',
        mode: ScheduleMode.flexible,
        days: const [],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutinesListScreen)),
      )!;
      await tester.tap(find.text(l10n.routinesTabFlexible));
      await tester.pumpAndSettle();

      expect(find.text(l10n.routinesNextUp.toUpperCase()), findsNothing);
      expect(find.byKey(const Key('nextUpCard')), findsNothing);

      await _disposeCleanly(tester);
    });

    testWidgets('does not overflow at 2.0x text scale', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final fixedNow = _fixedNow();
      final now = DateTime.utc(2026, 1, 1);
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'A Fairly Long Morning Wake-up Routine',
        startTime: _hhmm(fixedNow.add(const Duration(minutes: 10))),
        days: [_dayOfWeek(fixedNow)],
        steps: [
          for (var i = 0; i < 6; i++)
            RoutineStep(
              id: 's$i',
              routineId: 'r1',
              name: 'Step $i',
              emoji: '✅',
              durationSeconds: 60,
              order: i,
              noExplicitTime: false,
              createdAt: now,
              updatedAt: now,
            ),
        ],
      );

      await tester.pumpWidget(_wrap(adapter, now: fixedNow));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await _disposeCleanly(tester);
    });
  });
}
