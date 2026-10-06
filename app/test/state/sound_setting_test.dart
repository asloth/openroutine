import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/sounds/app_sounds.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/sound_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('sounds are on by default', () async {
    final container = await containerWith({});

    expect(container.read(soundsEnabledSettingProvider), isTrue);
    expect(container.read(appSoundsProvider), isNot(isA<SilentAppSounds>()));
  });

  test('turning sounds off sticks and silences the app', () async {
    final container = await containerWith({});

    await container
        .read(soundsEnabledSettingProvider.notifier)
        .setEnabled(false);

    expect(container.read(soundsEnabledSettingProvider), isFalse);
    expect(container.read(appSoundsProvider), isA<SilentAppSounds>());
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sounds_enabled'), isFalse);
  });
}
