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
import 'package:openroutine/screens/routines_list/routines_list_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/clock_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:intl/intl.dart';
import 'package:openroutine/theme/theme.dart';
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
      path: '/stats',
      builder: (context, state) {
        recorder.last = '/stats';
        return const Scaffold(body: Text('Stats screen'));
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
  String? startTime,
  List<DayOfWeek> days = const [DayOfWeek.mon],
  List<RoutineStep> steps = const [],
}) async {
  final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
  await _addRoutine(
    adapter,
    id: id,
    name: name,
    mode: mode,
    startTime: startTime,
    days: days,
    steps: steps,
  );
  return adapter;
}

Future<void> _addRoutine(
  LocalAdapter adapter, {
  required String id,
  required String name,
  ScheduleMode mode = ScheduleMode.scheduled,
  String? startTime,
  List<DayOfWeek> days = const [DayOfWeek.mon],
  List<RoutineStep> steps = const [],
}) async {
  final now = DateTime.utc(2026, 1, 1);
  await adapter.saveRoutine(
    Routine(
      id: id,
      name: name,
      triggerId: null,
      schedule: Schedule(mode: mode, days: days, startTime: startTime),
      stepIds: [for (final step in steps) step.id],
      createdAt: now,
      updatedAt: now,
    ),
  );
  for (final step in steps) {
    await adapter.saveStep(step);
  }
}

RoutineStep _step(
  String id,
  String routineId, {
  int order = 0,
  int minutes = 5,
  bool isCore = false,
}) => RoutineStep(
  id: id,
  routineId: routineId,
  name: 'Step $id',
  emoji: '✅',
  durationSeconds: minutes * 60,
  order: order,
  noExplicitTime: false,
  isCore: isCore,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

/// A run of [routineId] today at 8 AM local time.
Future<void> _runToday(
  LocalAdapter adapter,
  String routineId, {
  required CompletionOutcome outcome,
  List<String> stepIds = const [],
}) async {
  final today = DateTime.now();
  final startedAt = DateTime(today.year, today.month, today.day, 8).toUtc();
  await adapter.appendCompletion(
    CompletionLog(
      id: 'c-$routineId-${outcome.name}',
      routineId: routineId,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 5)),
      outcome: outcome,
      steps: [
        for (final id in stepIds)
          CompletionStep(
            stepId: id,
            state: CompletionStepState.completed,
            actualDurationSeconds: 60,
          ),
      ],
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(RoutinesListScreen)))!;

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

  testWidgets('with no routines, shows the empty state', (tester) async {
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.text(_l10n(tester).routinesEmptyScheduled), findsOneWidget);

    await _disposeCleanly(tester);
  });

  group('header', () {
    testWidgets('shows the date and a morning greeting before noon', (
      tester,
    ) async {
      final today = DateTime.now();
      final morning = DateTime(today.year, today.month, today.day, 9);
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter, now: morning));
      await tester.pumpAndSettle();

      expect(
        find.text(DateFormat.MMMMEEEEd('en').format(morning).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(_l10n(tester).homeGreetingMorning), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('the greeting gets the full width on a narrow phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final today = DateTime.now();
      final afternoon = DateTime(today.year, today.month, today.day, 15);
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter, now: afternoon));
      await tester.pumpAndSettle();

      final greeting = find.text(_l10n(tester).homeGreetingAfternoon);
      final gear = find.byTooltip(_l10n(tester).settingsTitle);
      expect(
        tester.getTopLeft(greeting).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(gear).dy),
        reason: 'the header actions sit above the greeting, not beside it',
      );

      await _disposeCleanly(tester);
    });

    testWidgets('greets the evening from 6 PM', (tester) async {
      final today = DateTime.now();
      final evening = DateTime(today.year, today.month, today.day, 19);
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter, now: evening));
      await tester.pumpAndSettle();

      expect(find.text(_l10n(tester).homeGreetingEvening), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('the streak pill shows the streak and opens statistics', (
      tester,
    ) async {
      final recorder = _RouteRecorder();
      final adapter = await _adapterWithRoutine(id: 'r1', name: 'Morning');
      await _runToday(adapter, 'r1', outcome: CompletionOutcome.completed);

      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      final pill = find.byKey(const Key('streakPill'));
      expect(
        find.descendant(of: pill, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(pill);
      await tester.pumpAndSettle();
      expect(recorder.last, '/stats');

      await _disposeCleanly(tester);
    });

    testWidgets('the settings gear opens settings', (tester) async {
      final recorder = _RouteRecorder();
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(_l10n(tester).settingsTitle));
      await tester.pumpAndSettle();
      expect(recorder.last, '/settings');

      await _disposeCleanly(tester);
    });
  });

  group('nudge card', () {
    testWidgets('names the next routine and when it starts', (tester) async {
      final now = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning reset',
        startTime: _hhmm(now.add(const Duration(minutes: 12))),
        days: [_dayOfWeek(now)],
        steps: [_step('s1', 'r1')],
      );

      await tester.pumpWidget(_wrap(adapter, now: now));
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      final card = find.byKey(const Key('nudgeCard'));
      expect(
        find.descendant(
          of: card,
          matching: find.text(l10n.homeNudgeStartsIn('Morning reset', 12)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(l10n.homeNudgeCompanion)),
        findsOneWidget,
      );

      await _disposeCleanly(tester);
    });

    testWidgets('says the routine is on once it has started', (tester) async {
      final now = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning reset',
        startTime: _hhmm(now.subtract(const Duration(minutes: 2))),
        days: [_dayOfWeek(now)],
        steps: [_step('s1', 'r1', minutes: 30)],
      );

      await tester.pumpWidget(_wrap(adapter, now: now));
      await tester.pumpAndSettle();

      expect(
        find.text(_l10n(tester).homeNudgeOnNow('Morning reset')),
        findsOneWidget,
      );

      await _disposeCleanly(tester);
    });

    testWidgets('Start opens the timer', (tester) async {
      final now = _fixedNow();
      final recorder = _RouteRecorder();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning reset',
        startTime: _hhmm(now.add(const Duration(minutes: 5))),
        days: [_dayOfWeek(now)],
        steps: [_step('s1', 'r1')],
      );

      await tester.pumpWidget(_wrap(adapter, now: now, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('nudgeCard')),
          matching: find.text(_l10n(tester).homeStart),
        ),
      );
      await tester.pumpAndSettle();
      expect(recorder.last, '/routines/r1/timer?mode=null');

      await _disposeCleanly(tester);
    });

    testWidgets('hidden when nothing is coming up', (tester) async {
      final now = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Evening',
        startTime: _hhmm(now.add(const Duration(hours: 3))),
        days: [_dayOfWeek(now)],
        steps: [_step('s1', 'r1')],
      );

      await tester.pumpWidget(_wrap(adapter, now: now));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nudgeCard')), findsNothing);

      await _disposeCleanly(tester);
    });
  });

  group('anytime today', () {
    testWidgets('lists flexible routines and collapses', (tester) async {
      final adapter = await _adapterWithRoutine(
        id: 'f1',
        name: 'Deep work',
        mode: ScheduleMode.flexible,
        days: const [],
        steps: [_step('s1', 'f1', minutes: 45), _step('s2', 'f1', order: 1)],
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final l10n = _l10n(tester);
      expect(find.text(l10n.homeAnytimeToday), findsOneWidget);
      expect(find.text('Deep work'), findsOneWidget);
      expect(
        find.text(
          '${l10n.homeStepsAndMinutes(2, 50)} · ${l10n.homeStartWhenYouWant}',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.homeAnytimeHide));
      await tester.pumpAndSettle();
      expect(find.text('Deep work'), findsNothing);
      expect(find.text(l10n.homeAnytimeReady(1)), findsOneWidget);

      await tester.tap(find.text(l10n.homeAnytimeReady(1)));
      await tester.pumpAndSettle();
      expect(find.text('Deep work'), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('Start opens the timer and the row opens the routine', (
      tester,
    ) async {
      final recorder = _RouteRecorder();
      final adapter = await _adapterWithRoutine(
        id: 'f1',
        name: 'Deep work',
        mode: ScheduleMode.flexible,
        days: const [],
        steps: [_step('s1', 'f1')],
      );

      await tester.pumpWidget(_wrap(adapter, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('anytimeToday')),
          matching: find.text(_l10n(tester).homeStart),
        ),
      );
      await tester.pumpAndSettle();
      expect(recorder.last, '/routines/f1/timer?mode=null');

      GoRouter.of(tester.element(find.text('Timer screen'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deep work'));
      await tester.pumpAndSettle();
      expect(recorder.last, '/routines/f1');

      await _disposeCleanly(tester);
    });
  });

  group('timeline', () {
    testWidgets("shows today's routines in start-time order", (tester) async {
      final now = _fixedNow();
      final today = [_dayOfWeek(now)];
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await _addRoutine(
        adapter,
        id: 'late',
        name: 'Wind down',
        startTime: '21:30',
        days: today,
      );
      await _addRoutine(
        adapter,
        id: 'early',
        name: 'Morning reset',
        startTime: '07:00',
        days: today,
      );

      await tester.pumpWidget(_wrap(adapter, now: now));
      await tester.pumpAndSettle();

      final timeline = find.byKey(const Key('timeline'));
      final early = find.descendant(
        of: timeline,
        matching: find.text('Morning reset'),
      );
      final late = find.descendant(
        of: timeline,
        matching: find.text('Wind down'),
      );
      expect(early, findsOneWidget);
      expect(late, findsOneWidget);
      expect(tester.getTopLeft(early).dy, lessThan(tester.getTopLeft(late).dy));

      await _disposeCleanly(tester);
    });

    testWidgets('a card opens its routine', (tester) async {
      final now = _fixedNow();
      final recorder = _RouteRecorder();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Wind down',
        startTime: '21:30',
        days: [_dayOfWeek(now)],
      );

      await tester.pumpWidget(_wrap(adapter, now: now, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wind down'));
      await tester.pumpAndSettle();
      expect(recorder.last, '/routines/r1');

      await _disposeCleanly(tester);
    });

    testWidgets('a run finished today shows Done', (tester) async {
      final now = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning reset',
        startTime: '07:00',
        days: [_dayOfWeek(now)],
        steps: [_step('s1', 'r1')],
      );
      await _runToday(adapter, 'r1', outcome: CompletionOutcome.completed);

      await tester.pumpWidget(_wrap(adapter, now: now));
      await tester.pumpAndSettle();

      expect(find.text(_l10n(tester).homeDone), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('a run stopped partway shows how far it got', (tester) async {
      final now = _fixedNow();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Morning reset',
        startTime: '07:00',
        days: [_dayOfWeek(now)],
        steps: [
          _step('s1', 'r1'),
          _step('s2', 'r1', order: 1),
          _step('s3', 'r1', order: 2),
        ],
      );
      await _runToday(
        adapter,
        'r1',
        outcome: CompletionOutcome.abandoned,
        stepIds: const ['s1', 's2'],
      );

      await tester.pumpWidget(_wrap(adapter, now: now));
      await tester.pumpAndSettle();

      expect(find.text(_l10n(tester).homeProgress(2, 3)), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('Low Mode starts the core steps', (tester) async {
      final now = _fixedNow();
      final recorder = _RouteRecorder();
      final adapter = await _adapterWithRoutine(
        id: 'r1',
        name: 'Wind down',
        startTime: '21:30',
        days: [_dayOfWeek(now)],
        steps: [_step('s1', 'r1', isCore: true), _step('s2', 'r1', order: 1)],
      );

      await tester.pumpWidget(_wrap(adapter, now: now, recorder: recorder));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_l10n(tester).routinesStartLowMode));
      await tester.pumpAndSettle();
      expect(recorder.last, '/routines/r1/timer?mode=low');

      await _disposeCleanly(tester);
    });
  });

  testWidgets('routines not due today wait under Other days', (tester) async {
    final now = _fixedNow();
    final tomorrow = _dayOfWeek(now.add(const Duration(days: 1)));
    final adapter = await _adapterWithRoutine(
      id: 'r1',
      name: 'Long run',
      startTime: '07:00',
      days: [tomorrow],
    );

    await tester.pumpWidget(_wrap(adapter, now: now));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.byKey(const Key('timeline')), findsNothing);
    expect(find.text('Long run'), findsNothing);

    await tester.tap(find.textContaining(l10n.homeOtherDays));
    await tester.pumpAndSettle();
    expect(find.text('Long run'), findsOneWidget);

    await _disposeCleanly(tester);
  });

  testWidgets('Add a routine opens the new routine form', (tester) async {
    final recorder = _RouteRecorder();
    final adapter = await _adapterWithRoutine(id: 'r1', name: 'Morning');
    await tester.pumpWidget(_wrap(adapter, recorder: recorder));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_l10n(tester).homeAddRoutine));
    await tester.pumpAndSettle();
    expect(recorder.last, '/routines/new');

    await _disposeCleanly(tester);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('renders without overflow at ${scale}x text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      final now = _fixedNow();
      final today = [_dayOfWeek(now)];
      final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
      await _addRoutine(
        adapter,
        id: 'soon',
        name: 'Morning reset with a long name',
        startTime: _hhmm(now.add(const Duration(minutes: 10))),
        days: today,
        steps: [_step('s1', 'soon', isCore: true)],
      );
      await _addRoutine(
        adapter,
        id: 'flex',
        name: 'Deep work',
        mode: ScheduleMode.flexible,
        days: const [],
        steps: [_step('s2', 'flex')],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: _wrap(adapter, now: now),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await _disposeCleanly(tester);
    });
  }
}
