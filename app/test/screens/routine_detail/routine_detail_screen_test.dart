import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/routine_detail/routine_detail_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/routines_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/theme/theme.dart';

final _createdAt = DateTime.utc(2026, 8, 1);

RoutineStep _step(String id, int order) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: 'Step $id',
  emoji: '•',
  durationSeconds: 60,
  order: order,
  noExplicitTime: false,
  createdAt: _createdAt,
  updatedAt: _createdAt,
);

Future<LocalAdapter> _seed(
  AppDatabase db,
  List<RoutineStep> steps, {
  LocalAdapter? adapter,
}) async {
  final storage = adapter ?? LocalAdapter(db);
  await storage.saveRoutine(
    Routine(
      id: 'r1',
      name: 'Morning',
      triggerId: null,
      schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
      stepIds: const [],
      createdAt: _createdAt,
      updatedAt: _createdAt,
    ),
  );
  for (final step in steps) {
    await storage.saveStep(step);
  }
  return storage;
}

GoRouter _router() => GoRouter(
  initialLocation: '/routines/r1',
  routes: [
    GoRoute(
      path: '/routines/:routineId',
      builder: (context, state) =>
          RoutineDetailScreen(routineId: state.pathParameters['routineId']!),
    ),
    GoRoute(
      path: '/routines/:routineId/steps/:stepId/edit',
      builder: (context, state) =>
          Scaffold(body: Text('Editing ${state.pathParameters['stepId']}')),
    ),
    GoRoute(
      path: '/routines/:routineId/steps/new',
      builder: (context, state) => const SizedBox(),
    ),
    GoRoute(
      path: '/routines/:routineId/timer',
      builder: (context, state) => const SizedBox(),
    ),
    GoRoute(
      path: '/routines/:routineId/edit',
      builder: (context, state) => const SizedBox(),
    ),
  ],
);

Widget _wrap(LocalAdapter adapter, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      routerConfig: _router(),
    ),
  );
}

List<String> _visibleOrder(WidgetTester tester) {
  final names = ['Step s1', 'Step s2', 'Step s3'];
  final visible = names.where((name) => find.text(name).evaluate().isNotEmpty);
  return visible.toList()..sort(
    (a, b) => tester
        .getTopLeft(find.text(a))
        .dy
        .compareTo(tester.getTopLeft(find.text(b)).dy),
  );
}

Future<void> _drag(WidgetTester tester, Finder handle, Offset offset) async {
  await tester.ensureVisible(handle);
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await tester.pump();
  await gesture.moveBy(offset);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

class _ControlledReorderAdapter extends LocalAdapter {
  _ControlledReorderAdapter(super.db);

  final reorderGate = Completer<void>();

  @override
  Future<void> reorderSteps(
    String routineId,
    List<String> orderedStepIds, {
    required DateTime updatedAt,
  }) async {
    await reorderGate.future;
    throw StateError('reorder failed');
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets(
    'drags downward and upward and keeps order after provider reload',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [
        _step('s1', 0),
        _step('s2', 1),
        _step('s3', 2),
      ]);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(RoutineDetailScreen));
      final l10n = AppLocalizations.of(context)!;

      await _drag(
        tester,
        find.byTooltip(l10n.routineDetailReorderHandle).first,
        const Offset(0, 180),
      );
      expect((await adapter.getSteps('r1')).map((step) => step.id), [
        's2',
        's3',
        's1',
      ]);

      final container = ProviderScope.containerOf(context);
      container.invalidate(routineStepsProvider('r1'));
      await tester.pumpAndSettle();
      expect(_visibleOrder(tester), ['Step s2', 'Step s3', 'Step s1']);

      await _drag(
        tester,
        find.byTooltip(l10n.routineDetailReorderHandle).last,
        const Offset(0, -180),
      );
      expect((await adapter.getSteps('r1')).map((step) => step.id), [
        's1',
        's2',
        's3',
      ]);
    },
  );

  testWidgets('uses stable keys and keeps card edit taps separate', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final adapter = await _seed(db, [_step('s1', 0), _step('s2', 1)]);
    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('s1')), findsOneWidget);
    expect(find.byKey(const ValueKey('s2')), findsOneWidget);
    await tester.tap(find.text('Step s1'));
    await tester.pumpAndSettle();
    expect(find.text('Editing s1'), findsOneWidget);
  });

  testWidgets('shows the empty state and no reorder handle', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final adapter = await _seed(db, const []);
    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RoutineDetailScreen)),
    )!;

    expect(find.text(l10n.routineDetailNoSteps), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNothing);
  });

  testWidgets('does not expose a meaningless handle for one step', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final adapter = await _seed(db, [_step('s1', 0)]);
    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_handle), findsNothing);
    expect(find.text('Step s1'), findsOneWidget);
  });

  testWidgets('localizes 48px accessible handles for multiple steps', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final adapter = await _seed(db, [_step('s1', 0), _step('s2', 1)]);
    await tester.pumpWidget(_wrap(adapter, locale: const Locale('es')));
    await tester.pumpAndSettle();
    const label = 'Arrastra para reordenar';
    final handles = find.byTooltip(label);

    expect(handles, findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      ),
      findsNWidgets(2),
    );
    for (final element in handles.evaluate()) {
      expect(tester.getSize(find.byWidget(element.widget)), const Size(48, 48));
    }
  });

  testWidgets('rolls back optimistic order and shows a localized save error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final adapter = _ControlledReorderAdapter(db);
    await _seed(db, [
      _step('s1', 0),
      _step('s2', 1),
      _step('s3', 2),
    ], adapter: adapter);
    await tester.pumpWidget(_wrap(adapter, locale: const Locale('es')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.drag_handle).first);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_handle).first),
    );
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(_visibleOrder(tester), ['Step s2', 'Step s3', 'Step s1']);

    adapter.reorderGate.complete();
    await tester.pumpAndSettle();

    expect(_visibleOrder(tester), ['Step s1', 'Step s2', 'Step s3']);
    expect(
      find.text(
        'No se pudo guardar el orden de los pasos. Inténtalo de nuevo.',
      ),
      findsOneWidget,
    );
    expect((await adapter.getSteps('r1')).map((step) => step.id), [
      's1',
      's2',
      's3',
    ]);
  });
}
