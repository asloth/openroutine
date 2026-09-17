## Why

Sara asked for "a setting that lets me have the light theme even if my phone has dark theme by
default." `MaterialApp.router` in `app/lib/main.dart` passes `theme` and `darkTheme` but no
`themeMode`, so the app always follows the phone's own brightness. There's no way to override that
today.

## What changes

- Add a **theme** setting — System, Light, or Dark — independent of the accent color and the
  background palette. Defaults to System, so every existing install keeps behaving exactly as it
  does today until someone opens Settings and changes it.
- Add a "Theme" row to Settings › Appearance, above the accent picker, that opens a dialog to pick
  one of the three.

## Capabilities

### New Capabilities

- `theme-mode` — the app's light/dark appearance follows a stored choice (System, Light, or Dark)
  instead of always mirroring the phone's brightness.

## Impact

**Code.** `app/lib/services/app_prefs.dart` (new `theme_mode` pref key), `app/lib/state/app_prefs_provider.dart`
(new `ThemeModeSetting` notifier), `app/lib/main.dart` (passes `themeMode:` to `MaterialApp.router`),
`app/lib/screens/settings/settings_screen.dart` (new Theme row and picker dialog), and both ARB
files.

**Storage.** A new `shared_preferences` key, `theme_mode`, storing `'system'`, `'light'`, or
`'dark'`. Missing or unrecognized values read as `'system'`. No `schemas/*.json` changes — this is
device-level presentation, not routine data.

**Existing users.** Everyone keeps following the phone's brightness after the update, since nothing
is stored yet and unset resolves to System. Anyone who later picks Light or Dark keeps it.

**Out of scope.** The Android home screen widget and notifications aren't `MaterialApp` consumers,
so they keep following the system theme regardless of this setting. The theme *colors* themselves
(accent, palette) are unaffected — this setting only picks which of the two existing schemes shows.

**i18n.** Four new strings (`settingsTheme`, `settingsThemeSystem`, `settingsThemeLight`,
`settingsThemeDark`) in `app_en.arb` and `app_es.arb`. No existing strings change.

**Rollback.** Reverting drops the pref key, the notifier, and the row. The stored `theme_mode`
value (if any) is simply never read again — nothing to migrate either direction.
