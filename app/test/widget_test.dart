// M2 smoke test: the app boots with a mocked SharedPreferences, redirects a
// fresh install to onboarding (onboardingComplete defaults to false), and
// the onboarding screen renders its first slide. Per-screen behavior is
// covered by the tests alongside each screen; this just proves the whole
// app wires together — routing, redirect, localization, and Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/main.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
