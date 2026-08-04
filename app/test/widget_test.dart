// M2 smoke test: the app boots with a mocked SharedPreferences, redirects a
// fresh install to onboarding (onboardingComplete defaults to false), and
// the onboarding screen renders its first slide. Per-screen behavior is
// covered by the tests alongside each screen; this just proves the whole
// app wires together — routing, redirect, localization, and Riverpod.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/main.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// See routines_list_screen_test: the list screen watches a drift stream, and
/// its subscription must be torn down inside the test body so the resulting
/// internal timer can be flushed.
Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  testWidgets(
    'a fresh install redirects to onboarding and shows the first slide',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const OpenRoutineApp(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.onboardingSlide1Title), findsOneWidget);
    },
  );

  // The onboarding → routines hand-off, end to end. It broke on-device
  // without any test noticing: the flag was written but the navigation was
  // swallowed (see app_prefs_provider_test for the cause and the test that
  // actually reproduces it). The mocked SharedPreferences resolves
  // synchronously, so this one cannot reproduce that race — it guards the
  // hand-off itself, which nothing covered before.
  testWidgets('finishing onboarding navigates to the routines list', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageAdapterProvider.overrideWithValue(
            LocalAdapter(AppDatabase(NativeDatabase.memory())),
          ),
        ],
        child: const OpenRoutineApp(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    )!;

    await tester.tap(find.text(l10n.onboardingSkip));
    await tester.pumpAndSettle();

    expect(find.text(l10n.onboardingSlide1Title), findsNothing);
    expect(find.text(l10n.appTitle), findsOneWidget);
    expect(prefs.getBool('onboarding_complete'), isTrue);

    await _disposeCleanly(tester);
  });
}
