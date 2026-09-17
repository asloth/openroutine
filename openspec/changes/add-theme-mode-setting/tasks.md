## 1. Prefs and provider

- [x] 1.1 Add tests to `test/services/app_prefs_test.dart` for `AppPrefs.themeMode`: unset reads as
      `'system'`, an unrecognized stored value reads as `'system'`, and `setThemeMode('light')` /
      `setThemeMode('dark')` round-trip through `shared_preferences`; verify they fail (no
      `themeMode` on `AppPrefs` yet)
- [x] 1.2 Add `theme_mode` / `themeMode` / `setThemeMode` to `AppPrefs`, modeled on `accentId` /
      `setAccentId`; verify 1.1 passes
- [x] 1.3 Add tests to `test/state/app_prefs_provider_test.dart` for `ThemeModeSetting`: defaults to
      `ThemeMode.system` with nothing stored, and `setMode` persists the right string and updates
      state for all three values; verify they fail (no `ThemeModeSetting` yet)
- [x] 1.4 Add `ThemeModeSetting` to `app_prefs_provider.dart` (`build`/`setMode`, `keepAlive: true`,
      modeled on `AccentSetting`), run code generation, and verify 1.3 passes

## 2. Wiring and settings UI

- [x] 2.1 Watch `themeModeSettingProvider` in `main.dart` and pass it as `themeMode:` to
      `MaterialApp.router`
- [x] 2.2 Add ARB strings (`settingsTheme`, `settingsThemeSystem`, `settingsThemeLight`,
      `settingsThemeDark`) to `app_en.arb` **and** `app_es.arb`, next to `settingsAccentTitle`, and
      run `flutter gen-l10n`
- [x] 2.3 Add a widget test to `test/screens/settings/settings_screen_test.dart`: the Theme row
      shows "Match my phone" by default, and picking Light in the dialog saves `theme_mode=light`
      and updates the row's subtitle; verify it fails (no Theme row yet)
- [x] 2.4 Add the Theme `ListTile` to Settings › Appearance, above `AccentPicker`, with a picker
      dialog following `_pickLocale`'s pattern; verify 2.3 passes
- [x] 2.5 Add a widget test to `test/widget_test.dart`: with `theme_mode` stored as `'light'` and
      the platform brightness set to dark, `Theme.of(context).brightness` is light

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
      above the 552-test baseline (560 pass)
- [x] 3.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')`
