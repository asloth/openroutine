// The template picker opens as a bottom sheet from a full-width "Start from a
// template" button, shown only when creating a step. Each template renders as
// one line of text in a chip — an emoji, its full name, and its duration when
// it has one — with no line limit, so nothing about the name ever truncates
// or gets clipped, at any text scale.
//
// This lives apart from step_form_screen_test so it can pump the form at a
// text scale of its own without leaking that scale into the behavioural
// tests. It replaces step_template_card_test.dart, which tested the inline
// carousel this screen no longer has.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/models/step_template.dart';
import 'package:openroutine/screens/step_form/step_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/reference_data_provider.dart';
import 'package:openroutine/state/storage_provider.dart';

final _now = DateTime.utc(2026, 8, 27);

RoutineStep _step(String id, int order) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: 'Step $id',
  emoji: '✅',
  durationSeconds: 60,
  order: order,
  noExplicitTime: false,
  isCore: false,
  remindDuring: false,
  createdAt: _now,
  updatedAt: _now,
);

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SizedBox()),
    GoRoute(
      path: '/step-new',
      builder: (context, state) => const StepFormScreen(routineId: 'r1'),
    ),
    GoRoute(
      path: '/step',
      builder: (context, state) =>
          const StepFormScreen(routineId: 'r1', stepId: 's1'),
    ),
  ],
);

/// The real provider reads `assets/step_templates.json` through `rootBundle`.
/// That load resolves once per test file and then leaves the button
/// permanently disabled on its loading state, so the second `pumpAndSettle`
/// never settles. The sheet's layout is what's under test here, not where its
/// data comes from — so hand it the templates the assertions name.
final _templates = [
  const StepTemplateCategory(
    id: 'morning',
    steps: [
      StepTemplate(
        id: 'brushTeeth',
        emoji: '🪥',
        durationSeconds: 180,
        noExplicitTime: false,
      ),
      StepTemplate(
        id: 'shower',
        emoji: '🚿',
        durationSeconds: 300,
        noExplicitTime: false,
      ),
    ],
  ),
  const StepTemplateCategory(
    id: 'evening',
    steps: [
      StepTemplate(
        id: 'read',
        emoji: '📖',
        durationSeconds: null,
        noExplicitTime: true,
      ),
    ],
  ),
];

Widget _wrap(LocalAdapter adapter, GoRouter router) => ProviderScope(
  overrides: [
    storageAdapterProvider.overrideWithValue(adapter),
    stepTemplateCategoriesProvider.overrideWith((ref) async => _templates),
  ],
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ),
);

/// Mirrors the helper in the other screen tests: forces the widget tree — and
/// the drift stream subscription under it — to dispose while we can still pump
/// the resulting timer. Without it the next `pumpAndSettle` in the file never
/// settles.
Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

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
        schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
        stepIds: const ['s1'],
        createdAt: _now,
        updatedAt: _now,
      ),
    );
    await adapter.saveStep(_step('s1', 0));
  });

  /// Pumps "Add step" at [scale], opens the template sheet, and returns the
  /// `Text` widget rendering the brush-teeth chip's label in full.
  Future<Text> chipTextAtScale(WidgetTester tester, double scale) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final router = _router();
    await tester.pumpWidget(_wrap(adapter, router));
    router.push('/step-new');
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.stepFormChooseTemplate));
    await tester.pumpAndSettle();

    final label = l10n.stepFormTemplateChipLabel(
      '🪥',
      l10n.stepTemplateBrushTeeth,
      l10n.stepDurationMinutes(3),
    );
    final finder = find.text(label);
    expect(finder, findsOneWidget, reason: 'the full chip label should render');
    return tester.widget<Text>(finder);
  }

  testWidgets(
    'a template chip shows its full label at the default text scale',
    (tester) async {
      final text = await chipTextAtScale(tester, 1.0);

      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      await _disposeCleanly(tester);
    },
  );

  testWidgets('a template chip shows its full label at a large text scale', (
    tester,
  ) async {
    // Without a sheet that gives chips as much room as they need, the old
    // fixed-height card sliced a scaled-up name through the middle of its
    // glyphs. A chip in a Wrap has no such ceiling.
    final text = await chipTextAtScale(tester, 1.5);

    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    await _disposeCleanly(tester);
  });

  testWidgets('a template with no duration shows only its emoji and name', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_wrap(adapter, router));
    router.push('/step-new');
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.stepFormChooseTemplate));
    await tester.pumpAndSettle();

    final label = l10n.stepFormTemplateChipLabelNoDuration(
      '📖',
      l10n.stepTemplateRead,
    );
    expect(find.text(label), findsOneWidget);
    await _disposeCleanly(tester);
  });

  testWidgets(
    'picking a template fills the name and emoji and closes the sheet',
    (tester) async {
      final router = _router();
      await tester.pumpWidget(_wrap(adapter, router));
      router.push('/step-new');
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      await tester.tap(find.text(l10n.stepFormChooseTemplate));
      await tester.pumpAndSettle();

      final label = l10n.stepFormTemplateChipLabel(
        '🚿',
        l10n.stepTemplateShower,
        l10n.stepDurationMinutes(5),
      );
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      // The sheet is gone: its category heading no longer exists.
      expect(
        find.text(stepTemplateCategoryLabel(l10n, 'evening')),
        findsNothing,
      );

      final nameField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(
        nameField.controller!.text,
        l10n.stepTemplateShower,
        reason: 'picking a template fills the name field',
      );
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.text('🚿'),
        ),
        findsOneWidget,
        reason: 'picking a template fills the emoji avatar',
      );
      await _disposeCleanly(tester);
    },
  );

  testWidgets('the template entry point does not exist when editing', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(_wrap(adapter, router));
    router.push('/step');
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l10n.stepFormChooseTemplate), findsNothing);
    await _disposeCleanly(tester);
  });
}
