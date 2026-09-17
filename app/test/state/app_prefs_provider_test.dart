// Regression: onboardingCompleteProvider is never watched — the router's
// redirect only ref.reads it, on purpose, so the GoRouter instance stays
// stable. As an auto-dispose provider that meant the notifier was torn down
// during the `await` inside complete(), and the `state = true` after the gap
// threw "Cannot use the Ref ... after it has been disposed". The exception
// propagated out of OnboardingScreen._finish() and swallowed the
// context.go('/routines'), stranding the user on onboarding until relaunch.

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'an unlistened onboardingComplete notifier outlives an event-loop turn',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // No listen()/watch() — exactly how the router's redirect uses it.
      final notifier = container.read(onboardingCompleteProvider.notifier);
      // complete() awaits the prefs write; anything that yields here would
      // dispose an auto-dispose provider out from under the `state =` below.
      await Future<void>.delayed(Duration.zero);

      expect(
        identical(
          container.read(onboardingCompleteProvider.notifier),
          notifier,
        ),
        isTrue,
        reason:
            'onboardingCompleteProvider must be keepAlive: nothing watches '
            'it, so auto-dispose would tear it down mid-complete()',
      );

      await notifier.complete();

      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(container.read(onboardingCompleteProvider), isTrue);
    },
  );

  group('ThemeModeSetting', () {
    test('defaults to ThemeMode.system when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });

    test('setMode persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(themeModeSettingProvider.notifier)
          .setMode(ThemeMode.light);

      expect(prefs.getString('theme_mode'), 'light');
      expect(container.read(themeModeSettingProvider), ThemeMode.light);

      await container
          .read(themeModeSettingProvider.notifier)
          .setMode(ThemeMode.dark);

      expect(prefs.getString('theme_mode'), 'dark');
      expect(container.read(themeModeSettingProvider), ThemeMode.dark);

      await container
          .read(themeModeSettingProvider.notifier)
          .setMode(ThemeMode.system);

      expect(prefs.getString('theme_mode'), 'system');
      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });
  });
}
