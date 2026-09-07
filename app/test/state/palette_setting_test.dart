import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/theme/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  test('defaults to warm paper when nothing has been chosen', () async {
    final (container, _) = await _boot();
    addTearDown(container.dispose);

    expect(container.read(paletteSettingProvider).id, 'warm_paper');
  });

  test('choosing a built-in persists its id', () async {
    final (container, prefs) = await _boot();
    addTearDown(container.dispose);

    await container
        .read(paletteSettingProvider.notifier)
        .setPalette(Palette.plum);

    expect(prefs.getString('theme_palette'), 'plum');
    expect(container.read(paletteSettingProvider).id, 'plum');
  });

  test('a custom palette survives a restart with its hue intact', () async {
    final (container, prefs) = await _boot();
    addTearDown(container.dispose);

    final custom = Palette.fromSeed(id: Palette.customId, hue: 268);
    await container.read(paletteSettingProvider.notifier).setPalette(custom);
    expect(prefs.getString('theme_palette'), 'custom:268');

    // A fresh container over the same prefs is what relaunching looks like.
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);

    final restored = restarted.read(paletteSettingProvider);
    expect(restored.isCustom, isTrue);
    expect(restored.seedHue, 268);
    expect(restored.light.primary, custom.light.primary);
  });

  test('preview repaints without touching disk', () async {
    final (container, prefs) = await _boot();
    addTearDown(container.dispose);

    final notifier = container.read(paletteSettingProvider.notifier);
    // What a drag across the hue slider does: many previews, no writes.
    for (var hue = 0; hue < 360; hue += 5) {
      notifier.preview(Palette.fromSeed(id: Palette.customId, hue: hue * 1.0));
    }

    expect(container.read(paletteSettingProvider).seedHue, 355);
    expect(
      prefs.getString('theme_palette'),
      isNull,
      reason: 'preview must not write — only onChangeEnd commits',
    );
  });

  test('a stored id from a newer build falls back instead of crashing',
      () async {
    final (container, _) = await _boot({'theme_palette': 'aurora_borealis'});
    addTearDown(container.dispose);

    expect(container.read(paletteSettingProvider).id, 'warm_paper');
  });
}
