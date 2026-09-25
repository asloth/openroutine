import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/routine_form/routine_form_screen.dart';
import 'package:openroutine/screens/step_form/step_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    hide Routine, RoutineStep;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';

final _then = DateTime.utc(2026, 1, 1);

const _saveKey = Key('routine-form-save');

RoutineStep _step(
  String id, {
  String routineId = 'r1',
  int order = 0,
  int? minutes = 3,
}) => RoutineStep(
  id: id,
  routineId: routineId,
  name: 'Step $id',
  emoji: '✅',
  durationSeconds: minutes == null ? null : minutes * 60,
  order: order,
  noExplicitTime: minutes == null,
  createdAt: _then,
  updatedAt: _then,
);

/// Stands in for the step form's draft mode, so these tests cover the routine
/// form alone. "fake-save" hands back the next queued step (with the form's
/// routine id), or the edited step when one was passed in.
class _FakeDraftPage extends StatelessWidget {
  const _FakeDraftPage({
    required this.routineId,
    required this.initial,
    required this.queue,
  });

  final String routineId;
  final RoutineStep? initial;
  final List<RoutineStep> queue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => context.pop(
              StepDraftSaved(
                initial ?? queue.removeAt(0).copyWith(routineId: routineId),
              ),
            ),
            child: const Text('fake-save'),
          ),
          TextButton(
            onPressed: () => context.pop(const StepDraftRemoved()),
            child: const Text('fake-remove'),
          ),
        ],
      ),
    );
  }
}

void main() {
  late AppDatabase db;
  late LocalAdapter adapter;
  late List<RoutineStep> queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    adapter = LocalAdapter(db);
    queue = [];
  });

  Future<AppLocalizations> pumpForm(
    WidgetTester tester, {
    String? routineId,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('home')),
        GoRoute(
          path: '/form',
          builder: (context, state) => RoutineFormScreen(routineId: routineId),
        ),
        GoRoute(
          path: '/routines/:routineId/steps/draft',
          builder: (context, state) => _FakeDraftPage(
            routineId: state.pathParameters['routineId']!,
            initial: state.extra as RoutineStep?,
            queue: queue,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageAdapterProvider.overrideWithValue(adapter)],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    router.push('/form');
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  Future<void> addStep(WidgetTester tester, AppLocalizations l10n) async {
    await tester.scrollUntilVisible(
      find.text(l10n.routineDetailAddStep),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.routineDetailAddStep));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fake-save'));
    await tester.pumpAndSettle();
  }

  Future<void> nameAndDay(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'Morning');
    await tester.tap(find.byKey(const Key('day-mon')));
    await tester.pumpAndSettle();
  }

  String saveLabel(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(of: find.byKey(_saveKey), matching: find.byType(Text)),
      )
      .single
      .data!;

  Future<void> disposeCleanly(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('with no steps, Save is off and says why', (tester) async {
    final l10n = await pumpForm(tester);
    await nameAndDay(tester);

    expect(find.text(l10n.routineFormStepsEmpty), findsOneWidget);
    await tester.tap(find.byKey(_saveKey));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineFormScreen), findsOneWidget);
    expect(await db.select(db.routines).get(), isEmpty);
    await disposeCleanly(tester);
  });

  testWidgets('Save counts the steps and their minutes', (tester) async {
    queue.addAll([_step('a'), _step('b', minutes: 2)]);
    final l10n = await pumpForm(tester);

    await addStep(tester, l10n);
    expect(saveLabel(tester), 'Save · 1 step, 3 min');
    await addStep(tester, l10n);
    expect(saveLabel(tester), 'Save · 2 steps, 5 min');
    expect(find.text('Step a'), findsOneWidget);
    expect(find.text('Step b'), findsOneWidget);
    await disposeCleanly(tester);
  });

  testWidgets('untimed steps leave the minutes out', (tester) async {
    queue.add(_step('a', minutes: null));
    final l10n = await pumpForm(tester);

    await addStep(tester, l10n);

    expect(saveLabel(tester), 'Save · 1 step');
    await disposeCleanly(tester);
  });

  testWidgets('saving writes the routine and its steps, then closes', (
    tester,
  ) async {
    queue.addAll([_step('a'), _step('b', minutes: 2)]);
    final l10n = await pumpForm(tester);
    await nameAndDay(tester);
    await addStep(tester, l10n);
    await addStep(tester, l10n);

    await tester.tap(find.byKey(_saveKey));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    final routines = await db.select(db.routines).get();
    expect(routines.single.name, 'Morning');
    final steps = await adapter.getSteps(routines.single.id);
    expect(steps.map((s) => s.id), ['a', 'b']);
    expect(steps.map((s) => s.order), [0, 1]);
    await disposeCleanly(tester);
  });

  group('backing out', () {
    testWidgets('an untouched form closes without asking', (tester) async {
      final l10n = await pumpForm(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(l10n.routineFormDiscardNewTitle), findsNothing);
      expect(find.text('home'), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('a half-built routine asks, and Discard leaves nothing', (
      tester,
    ) async {
      queue.add(_step('a'));
      final l10n = await pumpForm(tester);
      await nameAndDay(tester);
      await addStep(tester, l10n);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(l10n.routineFormDiscardNewTitle), findsOneWidget);

      await tester.tap(find.text(l10n.routineFormKeepEditing));
      await tester.pumpAndSettle();
      expect(find.byType(RoutineFormScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.routineFormDiscard));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(await db.select(db.routines).get(), isEmpty);
      expect(await db.select(db.routineSteps).get(), isEmpty);
      await disposeCleanly(tester);
    });
  });

  group('editing a stored routine', () {
    setUp(() async {
      await adapter.saveRoutine(
        Routine(
          id: 'r1',
          name: 'Morning',
          schedule: const Schedule(
            mode: ScheduleMode.flexible,
            days: [DayOfWeek.mon],
          ),
          stepIds: const [],
          createdAt: _then,
          updatedAt: _then,
        ),
      );
      await adapter.saveStep(_step('s1'));
      await adapter.saveStep(_step('s2', order: 1, minutes: 2));
    });

    testWidgets('lists the stored steps and counts them', (tester) async {
      await pumpForm(tester, routineId: 'r1');

      expect(find.text('Step s1'), findsOneWidget);
      expect(find.text('Step s2'), findsOneWidget);
      expect(saveLabel(tester), 'Save · 2 steps, 5 min');
      await disposeCleanly(tester);
    });

    testWidgets(
      'removing a step deletes it on Save and leaves the other untouched',
      (tester) async {
        await pumpForm(tester, routineId: 'r1');

        await tester.tap(find.text('Step s2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('fake-remove'));
        await tester.pumpAndSettle();
        expect(find.text('Step s2'), findsNothing);

        await tester.tap(find.byKey(_saveKey));
        await tester.pumpAndSettle();

        final steps = await adapter.getSteps('r1');
        expect(steps.map((s) => s.id), ['s1']);
        // Unchanged, so it keeps its timestamp and can't win a sync merge
        // it has no business winning.
        expect(steps.single.updatedAt.isAtSameMomentAs(_then), isTrue);
        await disposeCleanly(tester);
      },
    );

    testWidgets('an unchanged routine closes without asking', (tester) async {
      final l10n = await pumpForm(tester, routineId: 'r1');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(l10n.routineFormDiscardEditTitle), findsNothing);
      expect(find.text('home'), findsOneWidget);
      await disposeCleanly(tester);
    });
  });
}
