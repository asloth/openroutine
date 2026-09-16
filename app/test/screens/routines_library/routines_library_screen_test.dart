import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/routines_library/routines_library_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/theme/theme.dart';

class _RouteRecorder {
  String? last;
}

Widget _wrap(LocalAdapter adapter, _RouteRecorder recorder) {
  GoRoute stub(String path) => GoRoute(
    path: path,
    builder: (context, state) {
      recorder.last = state.uri.toString();
      return const Scaffold(body: Text('Elsewhere'));
    },
  );
  return ProviderScope(
    overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      routerConfig: GoRouter(
        initialLocation: '/library',
        routes: [
          GoRoute(
            path: '/library',
            builder: (context, state) => const RoutinesLibraryScreen(),
          ),
          stub('/routines/new'),
          stub('/routines/:routineId'),
        ],
      ),
    ),
  );
}

Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

Future<void> _add(
  LocalAdapter adapter, {
  required String id,
  required String name,
  ScheduleMode mode = ScheduleMode.scheduled,
  String? startTime,
  List<DayOfWeek> days = const [DayOfWeek.mon],
  int stepMinutes = 5,
}) async {
  final t0 = DateTime.utc(2026, 1, 1);
  await adapter.saveRoutine(
    Routine(
      id: id,
      name: name,
      triggerId: null,
      schedule: Schedule(mode: mode, days: days, startTime: startTime),
      stepIds: ['$id-s'],
      createdAt: t0,
      updatedAt: t0,
    ),
  );
  await adapter.saveStep(
    RoutineStep(
      id: '$id-s',
      routineId: id,
      name: 'Step',
      emoji: '✅',
      durationSeconds: stepMinutes * 60,
      order: 0,
      noExplicitTime: false,
      createdAt: t0,
      updatedAt: t0,
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(RoutinesLibraryScreen)))!;

void main() {
  testWidgets('lists every routine, scheduled by time and then anytime', (
    tester,
  ) async {
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    await _add(
      adapter,
      id: 'f',
      name: 'Deep work',
      mode: ScheduleMode.flexible,
      days: const [],
    );
    await _add(
      adapter,
      id: 'late',
      name: 'Wind down',
      startTime: '21:30',
      days: const [DayOfWeek.sun],
    );
    await _add(adapter, id: 'early', name: 'Morning reset', startTime: '07:00');

    await tester.pumpWidget(_wrap(adapter, _RouteRecorder()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.navRoutines), findsOneWidget);
    final ys = [
      for (final name in ['Morning reset', 'Wind down', 'Deep work'])
        tester.getTopLeft(find.text(name)).dy,
    ];
    expect(ys[0], lessThan(ys[1]));
    expect(ys[1], lessThan(ys[2]));
    expect(find.textContaining(l10n.routinesAnytime), findsOneWidget);

    await _disposeCleanly(tester);
  });

  testWidgets('a row opens its routine', (tester) async {
    final recorder = _RouteRecorder();
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
    await _add(adapter, id: 'r1', name: 'Morning reset', startTime: '07:00');

    await tester.pumpWidget(_wrap(adapter, recorder));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning reset'));
    await tester.pumpAndSettle();
    expect(recorder.last, '/routines/r1');

    await _disposeCleanly(tester);
  });

  testWidgets('Add a routine opens the new routine form', (tester) async {
    final recorder = _RouteRecorder();
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));

    await tester.pumpWidget(_wrap(adapter, recorder));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_l10n(tester).homeAddRoutine));
    await tester.pumpAndSettle();
    expect(recorder.last, '/routines/new');

    await _disposeCleanly(tester);
  });

  testWidgets('with no routines, shows the empty state', (tester) async {
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));

    await tester.pumpWidget(_wrap(adapter, _RouteRecorder()));
    await tester.pumpAndSettle();

    expect(find.text(_l10n(tester).routinesEmptyScheduled), findsOneWidget);

    await _disposeCleanly(tester);
  });
}
