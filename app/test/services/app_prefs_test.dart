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
}
