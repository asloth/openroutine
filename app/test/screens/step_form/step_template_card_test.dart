// The template cards in "Add step" size themselves to a fixed height. At a
// larger text scale the name no longer fits the space the emoji and duration
// leave it, and because the name sits in a `Flexible` it is sliced through the
// middle of the letters rather than overflowing where anyone would notice.
//
// This lives apart from step_form_screen_test so it can pump the form at a
// text scale of its own without leaking that scale into the behavioural tests.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step_template.dart';
import 'package:openroutine/screens/step_form/step_form_screen.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/reference_data_provider.dart';
import 'package:openroutine/state/storage_provider.dart';

final _now = DateTime.utc(2026, 8, 27);

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SizedBox()),
    GoRoute(
      path: '/step-new',
      builder: (context, state) => const StepFormScreen(routineId: 'r1'),
    ),
  ],
);

/// The real provider reads `assets/step_templates.json` through `rootBundle`.
/// That load resolves once per test file and then leaves the carousel stuck on
/// its spinner, so the second `pumpAndSettle` never settles. The card's layout
/// is what's under test here, not where its data comes from — so hand it the
/// one template the assertions name.
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
        triggerId: null,
        schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
        stepIds: const [],
        createdAt: _now,
        updatedAt: _now,
      ),
    );
  });

  /// Pumps "Add step" at [scale] and reports the height the template name got
  /// to draw itself in, alongside one unscaled line of the style it uses.
  Future<({double height, double fontSize})> nameAtScale(
    WidgetTester tester,
    double scale,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final router = _router();
    await tester.pumpWidget(_wrap(adapter, router));
    router.push('/step-new');
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    final name = find.text(l10n.stepTemplateBrushTeeth);
    expect(name, findsOneWidget);
    final style = Theme.of(tester.element(name)).textTheme.bodySmall!;
    return (height: tester.getSize(name).height, fontSize: style.fontSize!);
  }

  testWidgets('a template name gets a full line at the default text scale', (
    tester,
  ) async {
    final name = await nameAtScale(tester, 1.0);

    expect(name.height, greaterThanOrEqualTo(name.fontSize));
    await _disposeCleanly(tester);
  });

  testWidgets('a template name is not sliced at a large text scale', (
    tester,
  ) async {
    // Without a card that grows with the text, the name is squeezed to about a
    // pixel here — the glyphs are cut through the middle and unreadable.
    final name = await nameAtScale(tester, 1.5);

    expect(
      name.height,
      greaterThanOrEqualTo(const TextScaler.linear(1.5).scale(name.fontSize)),
    );
    await _disposeCleanly(tester);
  });
}
