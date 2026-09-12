import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/settings/settings_screen.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings › Appearance used to show two pickers: a background palette
/// picker, then the accent picker. There is only one choice now — the
/// accent, which colours the whole app — so this pins that the section
/// renders the accent picker's own title and helper and nothing shaped like
/// the old palette picker (no "Custom" swatch, no second "{name} selected"
/// caption).
Future<void> _pump(WidgetTester tester, SharedPreferences prefs) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Appearance shows the accent picker and no theme picker or custom swatch',
    (tester) async {
      // The screen's ListView is taller than the default 600px test
      // surface, and a sliver list only builds the children within its
      // viewport — a tall enough surface keeps every section built so it can
      // be found, rather than the assertions depending on scroll position.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pump(tester, prefs);

      final context = tester.element(find.byType(SettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.settingsAccentTitle), findsOneWidget);
      expect(find.text(l10n.settingsAccentHelper), findsOneWidget);
      // The old palette picker's free-hue swatch had no built-in palette
      // behind it and was always labelled "Custom".
      expect(find.bySemanticsLabel('Custom'), findsNothing);
      // Ink iris is the default accent, and — with the palette picker gone —
      // this is the only "{name} selected" caption Appearance renders.
      expect(
        find.text(l10n.settingsThemeCurrent(l10n.accentColorIndigo)),
        findsOneWidget,
      );
    },
  );
}
