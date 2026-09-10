import 'dart:async';

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
import 'package:openroutine/screens/routine_detail/routine_detail_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/routines_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/tinted/tinted.dart';

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

GoRouter _router({String initialLocation = '/routines/r1'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/routines',
      builder: (context, state) => const Scaffold(body: Text('Routines')),
    ),
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
      builder: (context, state) => const Text('Editing routine'),
    ),
  ],
);

Widget _wrap(
  LocalAdapter adapter, {
  Locale locale = const Locale('en'),
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      routerConfig: router ?? _router(),
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

// Drift streams outlive the widget tree unless it's replaced before the
// database closes in a test's addTearDown — this pumps a plain widget so
// those subscriptions get a chance to unsubscribe cleanly.
Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
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
        const Offset(0, 260),
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
        const Offset(0, -260),
      );
      expect((await adapter.getSteps('r1')).map((step) => step.id), [
        's1',
        's2',
        's3',
      ]);

      await _disposeCleanly(tester);
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

    await _disposeCleanly(tester);
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

    await _disposeCleanly(tester);
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

    await _disposeCleanly(tester);
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

    await _disposeCleanly(tester);
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
    await gesture.moveBy(const Offset(0, 260));
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

    await _disposeCleanly(tester);
  });

  group('header row', () {
    testWidgets('renders with no AppBar', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);

      await _disposeCleanly(tester);
    });

    testWidgets('Back pops to the previous route', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      final router = _router(initialLocation: '/routines');
      await tester.pumpWidget(_wrap(adapter, router: router));
      router.push('/routines/r1');
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailScreen), findsOneWidget);

      final tooltip = MaterialLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      ).backButtonTooltip;
      await tester.tap(find.byTooltip(tooltip));
      await tester.pumpAndSettle();

      expect(find.byType(RoutineDetailScreen), findsNothing);
      expect(find.text('Routines'), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('Share and Edit show today\'s tooltips, and Edit navigates', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      expect(find.byTooltip(l10n.routineDetailShare), findsOneWidget);
      expect(find.byTooltip(l10n.commonEdit), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.commonEdit));
      await tester.pumpAndSettle();
      expect(find.text('Editing routine'), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('More opens Delete, and cancelling keeps the routine', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      final router = _router(initialLocation: '/routines');
      await tester.pumpWidget(_wrap(adapter, router: router));
      router.push('/routines/r1');
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDelete));
      await tester.pumpAndSettle();
      expect(find.text(l10n.routineDetailDeleteConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(find.byType(RoutineDetailScreen), findsOneWidget);
      expect(await adapter.getRoutine('r1'), isNotNull);

      await _disposeCleanly(tester);
    });

    testWidgets('More opens Delete, and confirming deletes and pops', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      final router = _router(initialLocation: '/routines');
      await tester.pumpWidget(_wrap(adapter, router: router));
      router.push('/routines/r1');
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDelete));
      await tester.pumpAndSettle();

      expect(find.text('Routines'), findsOneWidget);
      expect(await adapter.getRoutine('r1'), isNull);

      await _disposeCleanly(tester);
    });
  });

  group('moment chip and summary card', () {
    testWidgets('both fill with the accent color', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final routineCardColors = AppTheme.light()
          .extension<RoutineCardColors>()!;
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      final chip = tester.widget<Container>(
        find.byKey(const Key('routineDetailMomentChip')),
      );
      final chipDecoration = chip.decoration! as BoxDecoration;
      expect(chipDecoration.color, routineCardColors.fill);
      expect(
        find.descendant(
          of: find.byKey(const Key('routineDetailMomentChip')),
          matching: find.text(l10n.routinesNoTrigger),
        ),
        findsOneWidget,
      );

      final card = tester.widget<TintedCard>(find.byType(TintedCard));
      expect(card.color, routineCardColors.fill);
      expect(card.foregroundColor, routineCardColors.onFill);

      await _disposeCleanly(tester);
    });
  });

  group('history dots', () {
    testWidgets('renders filled, ringed, and faint-ringed states', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      final today = DateTime.now();
      DateTime at(int daysAgo) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: daysAgo)).add(const Duration(hours: 8)).toUtc();

      await adapter.appendCompletion(
        CompletionLog(
          id: 'c1',
          routineId: 'r1',
          startedAt: at(0),
          endedAt: at(0).add(const Duration(minutes: 5)),
          outcome: CompletionOutcome.completed,
          steps: const [],
        ),
      );
      await adapter.appendCompletion(
        CompletionLog(
          id: 'c2',
          routineId: 'r1',
          startedAt: at(1),
          endedAt: at(1).add(const Duration(minutes: 2)),
          outcome: CompletionOutcome.abandoned,
          steps: const [],
        ),
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;
      final onFill = AppTheme.light().extension<RoutineCardColors>()!.onFill;

      final completedDot = tester.widget<Container>(
        find.descendant(
          of: find.byTooltip(l10n.routineDetailHistoryCompleted),
          matching: find.byType(Container),
        ),
      );
      final completedDecoration = completedDot.decoration! as BoxDecoration;
      expect(completedDecoration.color, onFill);
      expect(completedDecoration.border, isNull);

      final abandonedDot = tester.widget<Container>(
        find.descendant(
          of: find.byTooltip(l10n.routineDetailHistoryAbandoned),
          matching: find.byType(Container),
        ),
      );
      final abandonedDecoration = abandonedDot.decoration! as BoxDecoration;
      expect((abandonedDecoration.border! as Border).top.color, onFill);
      expect((abandonedDecoration.border! as Border).top.width, 1.5);

      final nothingDots = find.byTooltip(l10n.routineDetailHistoryNothing);
      expect(nothingDots, findsNWidgets(5));
      final nothingDot = tester.widget<Container>(
        find.descendant(
          of: nothingDots.first,
          matching: find.byType(Container),
        ),
      );
      final nothingDecoration = nothingDot.decoration! as BoxDecoration;
      expect(
        (nothingDecoration.border! as Border).top.color,
        onFill.withValues(alpha: 0.3),
      );

      await _disposeCleanly(tester);
    });
  });

  group('start timer and add step', () {
    testWidgets('disables Start Timer with no steps and shows helper text', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, const []);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text(l10n.routineDetailNeedsStepsToStart), findsOneWidget);

      await _disposeCleanly(tester);
    });

    testWidgets('enables Start Timer with steps and navigates to the timer', (
      tester,
    ) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      expect(find.text(l10n.routineDetailNeedsStepsToStart), findsNothing);
      await tester.tap(find.text(l10n.routineDetailStartTimer));
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailScreen), findsNothing);

      await _disposeCleanly(tester);
    });

    testWidgets('Add step navigates to the new-step route', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [_step('s1', 0)]);
      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(RoutineDetailScreen)),
      )!;

      await tester.tap(find.text(l10n.routineDetailAddStep));
      await tester.pumpAndSettle();
      expect(find.byType(RoutineDetailScreen), findsNothing);

      await _disposeCleanly(tester);
    });
  });

  group('step list container', () {
    testWidgets('draws a divider between rows but none after the last', (
      tester,
    ) async {
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

      final rows = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.minHeight == 72,
      );
      expect(rows, findsNWidgets(3));

      final elements = rows.evaluate().toList()
        ..sort(
          (a, b) => tester
              .getTopLeft(find.byWidget(a.widget))
              .dy
              .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy),
        );
      final borders = elements
          .map(
            (e) =>
                ((e.widget as Container).decoration! as BoxDecoration).border,
          )
          .toList();
      expect(
        borders.sublist(0, borders.length - 1).every((b) => b != null),
        isTrue,
      );
      expect(borders.last, isNull);

      await _disposeCleanly(tester);
    });
  });

  group('text scale', () {
    testWidgets('renders without overflow at 1.5x and 2.0x text scale', (
      tester,
    ) async {
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final adapter = await _seed(db, [
        _step('s1', 0),
        _step('s2', 1),
        _step('s3', 2),
      ]);

      for (final scale in [1.5, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(_wrap(adapter));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await _disposeCleanly(tester);
    });
  });
}
