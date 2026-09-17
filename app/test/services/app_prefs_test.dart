import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `accentId` is modeled exactly on `paletteId`: an opaque, nullable string
/// key so a build that doesn't recognize a stored value can fall back safely
/// instead of crashing.
void main() {
  test('accentId is null until something is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPrefs(await SharedPreferences.getInstance());

    expect(prefs.accentId, isNull);
  });

  test('setAccentId round-trips through shared_preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final raw = await SharedPreferences.getInstance();
    final prefs = AppPrefs(raw);

    await prefs.setAccentId('plum');

    expect(prefs.accentId, 'plum');
    expect(raw.getString('accent_color'), 'plum');
  });

  test('setAccentId(null) clears the stored value', () async {
    SharedPreferences.setMockInitialValues({'accent_color': 'plum'});
    final prefs = AppPrefs(await SharedPreferences.getInstance());

    await prefs.setAccentId(null);

    expect(prefs.accentId, isNull);
  });

  group('themeMode', () {
    test('reads as system until something is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPrefs(await SharedPreferences.getInstance());

      expect(prefs.themeMode, 'system');
    });

    test('reads as system for a value this build does not recognize', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
      final prefs = AppPrefs(await SharedPreferences.getInstance());

      expect(prefs.themeMode, 'system');
    });

    test(
      'setThemeMode(light) round-trips through shared_preferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final raw = await SharedPreferences.getInstance();
        final prefs = AppPrefs(raw);

        await prefs.setThemeMode('light');

        expect(prefs.themeMode, 'light');
        expect(raw.getString('theme_mode'), 'light');
      },
    );

    test('setThemeMode(dark) round-trips through shared_preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      final prefs = AppPrefs(raw);

      await prefs.setThemeMode('dark');

      expect(prefs.themeMode, 'dark');
      expect(raw.getString('theme_mode'), 'dark');
    });
  });
}
