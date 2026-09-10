// The bottom navigation bar and what it guarantees: both destinations are
// visible without opening anything, selecting one shows it, and a destination
// keeps its state while the other is visited.
//
// See openspec/changes/replace-overflow-with-bottom-nav/specs/app-navigation.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/main.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.utc(2026, 8, 27);

/// Mirrors the helper in the other screen tests: forces the widget tree — and
/// the drift stream subscriptions under it — to dispose while we can still
/// pump the resulting timers.
Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

Routine _routine(String id, String name, ScheduleMode mode) => Routine(
  id: id,
  name: name,
  triggerId: null,
  schedule: Schedule(mode: mode, days: const []),
  stepIds: const [],
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late AppDatabase database;
  late LocalAdapter adapter;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    adapter = LocalAdapter(database);
    await adapter.saveRoutine(
      _routine('r1', 'Morning', ScheduleMode.scheduled),
    );
    await adapter.saveRoutine(_routine('r2', 'Stretch', ScheduleMode.flexible));
  });

  /// Boots the real app past onboarding, so the router and its shell are the
  /// ones that ship rather than a stand-in.
  Future<AppLocalizations> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageAdapterProvider.overrideWithValue(adapter),
        ],
        child: const OpenRoutineApp(),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  testWidgets('both destinations are visible without opening a menu', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navRoutines),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navStats),
      ),
      findsOneWidget,
    );
    await _disposeCleanly(tester);
  });

  testWidgets('the routine list carries no overflow menu', (tester) async {
    await pumpApp(tester);

    expect(find.byType(PopupMenuButton<Object?>), findsNothing);
    await _disposeCleanly(tester);
  });

  testWidgets('selecting Statistics shows the statistics screen', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navStats),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.statsTitle), findsWidgets);
    await _disposeCleanly(tester);
  });

  testWidgets('a destination keeps its state while the other is visited', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.text(l10n.routinesTabFlexible));
    await tester.pumpAndSettle();
    expect(find.text('Stretch'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navStats),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.navRoutines),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Stretch'),
      findsOneWidget,
      reason: 'the Flexible tab was open when the list was left',
    );
    await _disposeCleanly(tester);
  });

  testWidgets('the settings control on the routine list opens settings', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.byTooltip(l10n.settingsTitle));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsStorageSection), findsOneWidget);
    await _disposeCleanly(tester);
  });

  testWidgets('import is reached from the data section in settings', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    await tester.tap(find.byTooltip(l10n.settingsTitle));
    await tester.pumpAndSettle();

    final importRow = find.widgetWithText(ListTile, l10n.routinesMenuImport);
    await tester.scrollUntilVisible(importRow, 200);
    await tester.tap(importRow);
    await tester.pumpAndSettle();

    expect(find.text(l10n.importTitle), findsWidgets);
    await _disposeCleanly(tester);
  });

  testWidgets('the bar names no action, only destinations', (tester) async {
    final l10n = await pumpApp(tester);

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.routinesMenuImport),
      ),
      findsNothing,
    );
    await _disposeCleanly(tester);
  });

  // Two destinations rather than three is what keeps these labels readable at
  // the text scale this app is actually used at. See step_template_card_test
  // for what a label looks like when its container does not grow with it.
  //
  // Material clamps navigation bar labels to 1.3x however far the system scale
  // goes, so this asserts against the scale the label actually receives rather
  // than the one the device asked for. The point is that the label is drawn in
  // full, not that it grows without limit.
  testWidgets('both bar labels are drawn in full at a large text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final l10n = await pumpApp(tester);

    for (final label in [l10n.navRoutines, l10n.navStats]) {
      final finder = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );
      expect(finder, findsOneWidget, reason: '$label is missing');

      final element = tester.element(finder);
      final style = Theme.of(element).textTheme.labelMedium!;
      // Floored: a line box lands on whole pixels, so an 18.2pt line measures
      // 18.0 without anything being cut. A sliced label is not off by a
      // fraction — the template card managed 1.0 against 18.0.
      final effective = MediaQuery.textScalerOf(
        element,
      ).scale(style.fontSize!).floorToDouble();

      expect(
        tester.getSize(finder).height,
        greaterThanOrEqualTo(effective),
        reason: '$label is sliced rather than shown',
      );
    }
    await _disposeCleanly(tester);
  });
}
