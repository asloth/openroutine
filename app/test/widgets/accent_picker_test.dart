import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/theme/palette.dart';
import 'package:openroutine/widgets/accent_picker.dart';
import 'package:openroutine/widgets/palette_picker.dart' show paletteName;
import 'package:shared_preferences/shared_preferences.dart';

/// Follows `palette_picker.dart`'s swatch and semantics pattern (see
/// design.md), but with no custom-hue entry: the accent only ever names a
/// built-in.
Future<void> _pump(WidgetTester tester, SharedPreferences prefs) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AccentPicker()),
      ),
    ),
  );
}

void main() {
  testWidgets('renders one swatch per built-in palette, no custom entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);

    for (final palette in Palette.builtIns) {
      expect(find.bySemanticsLabel(_labelFor(palette)), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Custom'), findsNothing);
  });

  testWidgets('ink iris is selected by default, named as a color', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);

    final context = tester.element(find.byType(AccentPicker));
    final l10n = AppLocalizations.of(context)!;
    expect(
      find.text(l10n.settingsThemeCurrent(l10n.accentColorIndigo)),
      findsOneWidget,
    );
  });

  testWidgets('swatch labels are color words, not palette names', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);

    final context = tester.element(find.byType(AccentPicker));
    final l10n = AppLocalizations.of(context)!;

    for (final palette in Palette.builtIns) {
      expect(find.bySemanticsLabel(_labelFor(palette)), findsOneWidget);
      expect(
        find.bySemanticsLabel(paletteName(l10n, palette)),
        findsNothing,
        reason:
            'accent swatch for ${palette.id} should not carry the theme '
            'name ${paletteName(l10n, palette)}',
      );
    }
  });

  testWidgets('tapping a swatch updates accentSettingProvider', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const AccentPicker();
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel(_labelFor(Palette.plum)));
    await tester.pumpAndSettle();

    expect(capturedRef.read(accentSettingProvider).id, 'plum');
  });
}

String _labelFor(Palette palette) => switch (palette.id) {
  'warm_paper' => 'Terracotta',
  'ink_iris' => 'Indigo',
  'sea_glass' => 'Teal',
  'plum' => 'Magenta',
  'slate' => 'Blue',
  'moss' => 'Green',
  _ => palette.id,
};
