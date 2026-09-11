// The floating pill nav bar and what it guarantees: both destinations are
// visible without opening anything, selecting one shows it, a destination
// keeps its state while the other is visited, the selected destination
// reports itself as selected, the body sees room for the pill, and neither
// destination's label overflows at a large system text scale.
//
// See openspec/changes/float-bottom-nav/specs/bottom-navigation.

import 'dart:ui' show Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/main.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/screens/shell/floating_nav_bar.dart';
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

  Finder destinationLabel(String label) => find.descendant(
    of: find.byType(FloatingNavBar),
    matching: find.text(label),
  );

  testWidgets('both destinations are visible without opening a menu', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(destinationLabel(l10n.navRoutines), findsOneWidget);
    expect(destinationLabel(l10n.navStats), findsOneWidget);
    await _disposeCleanly(tester);
  });

  testWidgets('the stock NavigationBar is gone', (tester) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsNothing);
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

    await tester.tap(destinationLabel(l10n.navStats));
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

    await tester.tap(destinationLabel(l10n.navStats));
    await tester.pumpAndSettle();

    await tester.tap(destinationLabel(l10n.navRoutines));
    await tester.pumpAndSettle();

    expect(
      find.text('Stretch'),
      findsOneWidget,
      reason: 'the Flexible tab was open when the list was left',
    );
    await _disposeCleanly(tester);
  });

  // `/routines/<id>` is a plain pushed route rather than nested inside the
  // Routines branch (see main.dart), so there's no in-app scenario where the
  // bar is still on screen with a non-root state to return from. What
  // `AppShell` actually depends on is narrower: that tapping the
  // already-selected destination still fires the callback, so it can call
  // `goBranch(index, initialLocation: true)` and send the branch back to its
  // root. That's what this asserts, against the bar alone rather than the
  // whole app.
  testWidgets('tapping the already-selected destination still calls back', (
    tester,
  ) async {
    var lastTapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingNavBar(
            currentIndex: 0,
            destinations: const [
              FloatingNavDestination(
                icon: Icons.checklist_outlined,
                selectedIcon: Icons.checklist,
                label: 'Routines',
              ),
              FloatingNavDestination(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights,
                label: 'Statistics',
              ),
            ],
            onDestinationSelected: (index) => lastTapped = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Routines'));
    await tester.pump();

    expect(lastTapped, 0);
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

    expect(destinationLabel(l10n.routinesMenuImport), findsNothing);
    await _disposeCleanly(tester);
  });

  testWidgets('the selected destination reports selected semantics', (
    tester,
  ) async {
    final l10n = await pumpApp(tester);

    final selected = tester.getSemantics(destinationLabel(l10n.navRoutines));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);

    final unselected = tester.getSemantics(destinationLabel(l10n.navStats));
    expect(unselected.flagsCollection.isSelected, isNot(Tristate.isTrue));
    await _disposeCleanly(tester);
  });

  testWidgets('the body sees enough bottom padding to clear the pill', (
    tester,
  ) async {
    await pumpApp(tester);

    final pill = tester.getSize(
      find.descendant(
        of: find.byType(FloatingNavBar),
        matching: find.byKey(FloatingNavBar.pillKey),
      ),
    );
    final bodyElement = tester.element(find.text('Morning'));
    final bodyBottomPadding = MediaQuery.paddingOf(bodyElement).bottom;

    expect(bodyBottomPadding, greaterThanOrEqualTo(pill.height));
    await _disposeCleanly(tester);
  });

  // Two destinations rather than three is what keeps these labels readable at
  // the text scale this app is actually used at. See step_template_card_test
  // for what a label looks like when its container does not grow with it.
  //
  // Unlike Material's `NavigationBar`, which clamps its own labels at 1.3x
  // regardless of what the caller asks for, this bar has no built-in ceiling
  // — so the test that matters here is that nothing overflows once a system
  // text scale actually gets large, on the narrowest phone width this app
  // supports.
  for (final scale in [1.5, 2.0]) {
    testWidgets('neither destination overflows at ${scale}x on a 360px phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final l10n = await pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(destinationLabel(l10n.navRoutines), findsOneWidget);
      expect(destinationLabel(l10n.navStats), findsOneWidget);
      await _disposeCleanly(tester);
    });
  }
}
