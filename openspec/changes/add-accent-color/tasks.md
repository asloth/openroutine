## 1. Prefs, provider, and the accent merge (slice 1)

- [x] 1.1 Add a test round-tripping `AppPrefs.accentId` through `shared_preferences` (null by
      default, set-then-get returns what was set, matching `paletteId`'s pattern), and verify it
      fails against the current `AppPrefs`
- [x] 1.2 Add `accentId`/`setAccentId` to `AppPrefs` under the `accent_color` key, modeled on
      `paletteId`, and verify 1.1 passes
- [x] 1.3 Add a test asserting `AccentSetting` defaults to `Palette.inkIris` when nothing is stored,
      and falls back to it for an unrecognized stored id, and verify it fails (no `AccentSetting`
      exists yet)
- [x] 1.4 Add `AccentSetting` to `app_prefs_provider.dart` (`build`/`setAccent`/`preview`, modeled on
      `PaletteSetting`, `keepAlive: true`), run code generation, and verify 1.3 passes
- [x] 1.5 Add the contrast matrix test in `test/theme/palette_test.dart` (or a new
      `test/theme/accent_test.dart`): for every background palette × every built-in accent, light
      and dark, the accented primary clears 4.5:1 against the background's surface and
      `onPrimaryContainer` clears 4.5:1 against `primaryContainer`, and verify it fails (no merge
      helper exists yet)
- [x] 1.6 Add `Palette.withAccent(base, accent)` to `palette.dart`, pushing the accent's `primary`
      through `_meet` against the base `surface`, replacing `primary`/`onPrimary`/
      `primaryContainer`/`onPrimaryContainer`/`inversePrimary`, and leaving `surfaceTint` and
      everything else from `base`, and verify 1.5 passes
- [x] 1.7 Add fixed tokens to `colors.dart`: `upcoming`/`onUpcoming` (light), `upcomingDark`/
      `onUpcomingDark`, `timerGround` (light only; dark uses the scheme's `surface`)
- [x] 1.8 Add a test asserting the built theme carries a `RoutineCardColors` extension whose `fill`/
      `onFill` equal the accent's `primaryContainer`/`onPrimaryContainer` and whose `upcomingFill`/
      `onUpcomingFill`/`timerGround` equal the fixed tokens, for both brightnesses, and verify it
      fails (no extension exists yet)
- [x] 1.9 Add the `RoutineCardColors` `ThemeExtension` (`copyWith`/`lerp`/`BuildContext` accessor) to
      `theme.dart`; give `AppTheme.light`/`dark` an optional `accent` parameter defaulting to
      `Palette.inkIris`, build the scheme through `Palette.withAccent`, and register the extension;
      verify 1.8 passes
- [x] 1.10 Watch `accentSettingProvider` in `main.dart` next to `paletteSettingProvider` and pass it
      into both `AppTheme.light`/`dark` calls
- [x] 1.11 Run `flutter analyze --fatal-infos` and `flutter test` from `app/`; fix anything this
      slice breaks (fixed `test/theme/appearance_defaults_test.dart` — see commit message)

## 2. Settings picker (slice 2)

- [x] 2.1 Add ARB strings (`settingsAccentTitle`/description "Accent color", `settingsAccentHelper`/
      description "Colors your routine cards and main buttons.") to `app_en.arb` **and**
      `app_es.arb`, run `flutter gen-l10n`
- [x] 2.2 Add a widget test for `AccentPicker`: it renders a swatch per `Palette.builtIns` showing
      each one's light `primary`, and tapping a swatch updates `accentSettingProvider`; verify it
      fails (no widget exists yet)
- [x] 2.3 Add `app/lib/widgets/accent_picker.dart`, following `palette_picker.dart`'s swatch and
      semantics pattern (no custom-hue entry), and verify 2.2 passes
- [x] 2.4 Add the picker to Settings › Appearance, under the existing `PalettePicker`, with the new
      title/helper strings
- [x] 2.5 Update `DESIGN.md`'s Colors section with a short paragraph on the accent concept and the
      fixed "coming up" green
- [x] 2.6 Run `flutter analyze --fatal-infos` and `flutter test` from `app/`; fix anything this slice
      breaks (nothing broke)

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
      above the current 354 baseline (443 pass)
- [x] 3.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')`
