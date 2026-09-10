import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/theme/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `AccentSetting` is modeled on `PaletteSetting`, with one deliberate
/// difference: its default and its fallback are `Palette.inkIris`, never
/// `Palette.defaultPalette` — the accent's default is a separate product
/// decision from the background palette's, and the two must not recouple
/// just because one of them changes later.
Future<(ProviderContainer, SharedPreferences)> _boot([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return (container, prefs);
}

void main() {
  test('defaults to ink iris when nothing has been chosen', () async {
    final (container, _) = await _boot();
    addTearDown(container.dispose);

    expect(container.read(accentSettingProvider).id, Palette.inkIris.id);
  });

  test('an unrecognised stored id falls back to ink iris', () async {
    final (container, _) = await _boot({'accent_color': 'aurora_borealis'});
    addTearDown(container.dispose);

    expect(container.read(accentSettingProvider).id, Palette.inkIris.id);
  });

  test('choosing a built-in persists its id', () async {
    final (container, prefs) = await _boot();
    addTearDown(container.dispose);

    await container
        .read(accentSettingProvider.notifier)
        .setAccent(Palette.plum);

    expect(prefs.getString('accent_color'), 'plum');
    expect(container.read(accentSettingProvider).id, 'plum');
  });

  test('preview repaints without touching disk', () async {
    final (container, prefs) = await _boot();
    addTearDown(container.dispose);

    container.read(accentSettingProvider.notifier).preview(Palette.moss);

    expect(container.read(accentSettingProvider).id, 'moss');
    expect(
      prefs.getString('accent_color'),
      isNull,
      reason: 'preview must not write — only setAccent commits',
    );
  });
}
