import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/step_form/step_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';

final _now = DateTime.utc(2026, 9, 21);

final _drafted = RoutineStep(
  id: 'd1',
  routineId: 'r1',
  name: 'Stretch',
  emoji: '🧘',
  durationSeconds: 300,
  order: 2,
  noExplicitTime: false,
  createdAt: _now,
  updatedAt: _now,
);

/// Draft mode belongs to a routine that may not exist yet, so none of these
/// tests save a routine first: storage has to stay empty either way.
GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SizedBox()),
    GoRoute(
      path: '/draft',
      builder: (context, state) => StepFormScreen.draft(
        routineId: 'r1',
        initial: state.extra as RoutineStep?,
      ),
    ),
  ],
);

void main() {
  late AppDatabase database;
  late LocalAdapter adapter;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    adapter = LocalAdapter(database);
  });

  Future<(AppLocalizations, Future<StepDraftResult?>)> pumpDraft(
    WidgetTester tester, {
    RoutineStep? initial,
  }) async {
    final router = _router();
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
    final result = router.push<StepDraftResult>('/draft', extra: initial);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    return (l10n, result);
  }

  // First in the file: it's the only test that loads the template asset.
  testWidgets('a new step comes back to the caller instead of into storage', (
    tester,
  ) async {
    final (l10n, result) = await pumpDraft(tester);

    await tester.tap(find.text(l10n.stepFormChooseTemplate));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        l10n.stepFormTemplateChipLabel(
          '🪥',
          l10n.stepTemplateBrushTeeth,
          l10n.stepDurationMinutes(3),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.commonSave));
    await tester.pumpAndSettle();

    final saved = (await result)! as StepDraftSaved;
    expect(saved.step.routineId, 'r1');
    expect(saved.step.emoji, '🪥');
    expect(saved.step.durationSeconds, 180);
    expect(await adapter.getSteps('r1'), isEmpty);
  });

  testWidgets('editing a drafted step keeps its id and returns the edit', (
    tester,
  ) async {
    final (l10n, result) = await pumpDraft(tester, initial: _drafted);

    expect(find.text('Stretch'), findsOneWidget);
    // A drafted step is being edited, so the template picker stays hidden.
    expect(find.text(l10n.stepFormChooseTemplate), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Stretch'),
      'Yoga',
    );
    await tester.tap(find.byTooltip(l10n.commonSave));
    await tester.pumpAndSettle();

    final saved = (await result)! as StepDraftSaved;
    expect(saved.step.id, 'd1');
    expect(saved.step.name, 'Yoga');
    expect(saved.step.order, 2);
    expect(await adapter.getSteps('r1'), isEmpty);
  });

  testWidgets('deleting a drafted step asks, then reports the removal', (
    tester,
  ) async {
    final (l10n, result) = await pumpDraft(tester, initial: _drafted);

    await tester.tap(find.byTooltip(l10n.commonDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, l10n.commonDelete));
    await tester.pumpAndSettle();

    expect(await result, isA<StepDraftRemoved>());
  });

  testWidgets('backing out returns nothing', (tester) async {
    final (_, result) = await pumpDraft(tester, initial: _drafted);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
