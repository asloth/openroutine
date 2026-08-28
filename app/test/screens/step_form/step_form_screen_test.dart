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

RoutineStep _step(String id, int order, {required bool isCore}) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: 'Step $id',
  emoji: '✅',
  durationSeconds: 60,
  order: order,
  noExplicitTime: false,
  isCore: isCore,
  createdAt: _now,
  updatedAt: _now,
);

GoRouter _routerToStepForm() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SizedBox()),
    GoRoute(
      path: '/step',
      builder: (context, state) =>
          const StepFormScreen(routineId: 'r1', stepId: 's4'),
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

void main() {
  testWidgets('a fourth essential step can be saved and read from storage', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final adapter = LocalAdapter(database);
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
    for (var index = 0; index < 4; index++) {
      await adapter.saveStep(_step('s${index + 1}', index, isCore: index < 3));
    }

    final router = _routerToStepForm();
    await tester.pumpWidget(_wrap(adapter, router));
    router.push('/step');
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
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
}
