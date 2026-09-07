import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/step_form/step_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';

final _now = DateTime.utc(2026, 8, 27);

RoutineStep _step(
  String id,
  int order, {
  required bool isCore,
  bool remindDuring = false,
}) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: 'Step $id',
  emoji: '✅',
  durationSeconds: 60,
  order: order,
  noExplicitTime: false,
  isCore: isCore,
  remindDuring: remindDuring,
  createdAt: _now,
  updatedAt: _now,
);

/// `/step` edits s4; `/step-new` creates. Both routes exist on every router so
/// each test can push the one it needs.
GoRouter _routerToStepForm() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SizedBox()),
    GoRoute(
      path: '/step',
      builder: (context, state) =>
          const StepFormScreen(routineId: 'r1', stepId: 's4'),
    ),
    GoRoute(
      path: '/step-new',
      builder: (context, state) => const StepFormScreen(routineId: 'r1'),
    ),
  ],
);

Widget _wrap(LocalAdapter adapter, GoRouter router) => ProviderScope(
  overrides: [storageAdapterProvider.overrideWithValue(adapter)],
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ),
);

/// Both switches on this screen are `SwitchListTile`s, so every finder has to
/// name the one it means — a bare `find.byType` matches two widgets and fails.
Finder _switch(String label) => find.widgetWithText(SwitchListTile, label);

void main() {
  late AppDatabase database;
  late LocalAdapter adapter;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    adapter = LocalAdapter(database);
    await adapter.saveRoutine(
      Routine(
        id: 'r1',
        name: 'Morning',
        triggerId: null,
        schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
        stepIds: const ['s1', 's2', 's3', 's4'],
        createdAt: _now,
        updatedAt: _now,
      ),
    );
  });

  Future<AppLocalizations> pumpForm(WidgetTester tester, String route) async {
    final router = _routerToStepForm();
    await tester.pumpWidget(_wrap(adapter, router));
    router.push(route);
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  }

  testWidgets('a fourth essential step can be saved and read from storage', (
    tester,
  ) async {
    for (var index = 0; index < 4; index++) {
      await adapter.saveStep(_step('s${index + 1}', index, isCore: index < 3));
    }

    final l10n = await pumpForm(tester, '/step');
    final checkbox = find.byType(CheckboxListTile);
    expect(tester.widget<CheckboxListTile>(checkbox).onChanged, isNotNull);
    await tester.tap(checkbox);
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);

    await tester.tap(find.byTooltip(l10n.commonSave));
    await tester.pumpAndSettle();

    final savedStep = (await adapter.getSteps(
      'r1',
    )).singleWhere((step) => step.id == 's4');
    expect(savedStep.isCore, isTrue);
  });

  group('the mid-step reminder toggle', () {
    testWidgets('starts on for a new step and is stored that way', (
      tester,
    ) async {
      final l10n = await pumpForm(tester, '/step-new');

      final toggle = _switch(l10n.stepFormRemindDuringLabel);
      expect(
        tester.widget<SwitchListTile>(toggle).value,
        isTrue,
        reason: 'the form suggests the reminder, even though storage does not',
      );

      // A template fills in the name and the emoji, both of which `_save`
      // insists on, without opening the emoji sheet.
      await tester.tap(find.text(l10n.stepTemplateBrushTeeth));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      final saved = await adapter.getSteps('r1');
      expect(saved, hasLength(1));
      expect(saved.single.remindDuring, isTrue);
    });

    testWidgets('reflects what an existing step stored, not the form default', (
      tester,
    ) async {
      await adapter.saveStep(_step('s4', 3, isCore: false));

      final l10n = await pumpForm(tester, '/step');

      expect(
        tester
            .widget<SwitchListTile>(_switch(l10n.stepFormRemindDuringLabel))
            .value,
        isFalse,
        reason: 'a step stored before this existed must stay silent',
      );
    });

    testWidgets('round-trips through storage when it is turned on', (
      tester,
    ) async {
      await adapter.saveStep(_step('s4', 3, isCore: false));

      final l10n = await pumpForm(tester, '/step');
      await tester.tap(_switch(l10n.stepFormRemindDuringLabel));
      await tester.pump();
      expect(
        tester
            .widget<SwitchListTile>(_switch(l10n.stepFormRemindDuringLabel))
            .value,
        isTrue,
      );

      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      final saved = (await adapter.getSteps(
        'r1',
      )).singleWhere((step) => step.id == 's4');
      expect(saved.remindDuring, isTrue);
    });

    testWidgets('round-trips an already-on step back off', (tester) async {
      await adapter.saveStep(_step('s4', 3, isCore: false, remindDuring: true));

      final l10n = await pumpForm(tester, '/step');
      expect(
        tester
            .widget<SwitchListTile>(_switch(l10n.stepFormRemindDuringLabel))
            .value,
        isTrue,
      );
      await tester.tap(_switch(l10n.stepFormRemindDuringLabel));
      await tester.pump();

      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      final saved = (await adapter.getSteps(
        'r1',
      )).singleWhere((step) => step.id == 's4');
      expect(saved.remindDuring, isFalse);
    });

    testWidgets('is unavailable for a step with no explicit time', (
      tester,
    ) async {
      await adapter.saveStep(_step('s4', 3, isCore: false, remindDuring: true));

      final l10n = await pumpForm(tester, '/step');
      expect(_switch(l10n.stepFormRemindDuringLabel), findsOneWidget);

      await tester.tap(_switch(l10n.stepFormNoExplicitTime));
      await tester.pumpAndSettle();

      expect(
        _switch(l10n.stepFormRemindDuringLabel),
        findsNothing,
        reason: 'a fraction of no estimate is not a moment to be nudged at',
      );
      expect(
        find.text(l10n.stepFormRemindDuringGuidance),
        findsNothing,
        reason: 'the guidance goes with the control it explains',
      );

      await tester.tap(find.byTooltip(l10n.commonSave));
      await tester.pumpAndSettle();

      final saved = (await adapter.getSteps(
        'r1',
      )).singleWhere((step) => step.id == 's4');
      expect(
        saved.remindDuring,
        isFalse,
        reason:
            'the estimate is dropped on save, so the reminder that depended '
            'on it is dropped with it rather than left on invisibly',
      );
      expect(saved.durationSeconds, isNull);
    });
  });
}
