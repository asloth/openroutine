import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/widgets/accent_picker.dart';
import 'package:openroutine/widgets/palette_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings › Appearance renders [PalettePicker] then [AccentPicker] under
/// one "Appearance" header. Without its own title, the palette picker used to
/// read as an untitled row of swatches followed by the accent picker's
/// labelled section — two pickers that looked like one. These tests pin the
/// header [PalettePicker] now carries, and that it renders above the accent
/// picker's own header in the order Settings actually uses.
Future<void> _pump(WidgetTester tester, SharedPreferences prefs) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [PalettePicker(), AccentPicker()]),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a theme title and helper above the swatches', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);

    final context = tester.element(find.byType(PalettePicker));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
    expect(find.text(l10n.settingsThemeHelper), findsOneWidget);
  });

  testWidgets('theme title renders above the accent title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);

    final context = tester.element(find.byType(PalettePicker));
    final l10n = AppLocalizations.of(context)!;

    final themeTitleY = tester
        .getTopLeft(find.text(l10n.settingsThemeTitle))
        .dy;
    final accentTitleY = tester
        .getTopLeft(find.text(l10n.settingsAccentTitle))
        .dy;

    expect(themeTitleY, lessThan(accentTitleY));
  });
}
