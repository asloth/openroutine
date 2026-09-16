## 1. Spec

- [x] 1.1 Write the `appearance-defaults` and `accent-color` spec deltas describing one palette
      driving the whole theme, and verify `openspec validate unify-app-color --type change --strict`
      passes

## 2. The theme builds from one palette

- [x] 2.1 Add `test/theme/theme_test.dart` asserting `AppTheme.light(Palette.moss)` and
      `AppTheme.dark(Palette.moss)` expose moss's own `MascotPalette` and moss's own
      `ColorScheme.surface`, and that `AppTheme.light()`/`dark()` with no argument are Ink & Iris
      throughout (`theme.colorScheme == Palette.inkIris.light`/`.dark`); verify it fails against the
      two-palette `AppTheme`
- [x] 2.2 Update `test/theme/routine_card_colors_test.dart` for the single-`Palette` `AppTheme`
      signature — `fill`/`onFill` come from the one palette's own container pair — and verify it
      fails
- [x] 2.3 Update `test/theme/appearance_defaults_test.dart`'s segmented-button helper to
      `AppTheme.light(palette)` and delete its `default palette` group (superseded by the
      accent-color spec's own default), and verify the segmented-button assertions still pass
      unchanged
- [x] 2.4 Collapse `AppTheme.light`/`dark` to take one `Palette` (default `Palette.inkIris`) and
      have `_build` read `palette.scheme(brightness)` directly, with no merge step; verify 2.1-2.3
      pass
- [x] 2.5 Delete `Palette.withAccent` and `test/theme/accent_test.dart`, its only caller and its
      only test
- [x] 2.6 Delete `Palette.defaultPalette`, `Palette.fromStorageId`, and the custom-storage plumbing
      (`customPrefix`, `customId`, `isCustom`, `storageId`) now that nothing calls them; move
      `Palette`'s `operator ==`/`hashCode` from `storageId` to `id`; update
      `test/theme/palette_test.dart`'s persistence group and `mascot_slot.dart`'s fallback
      accordingly
- [x] 2.7 Update `main.dart` to watch only `accentSettingProvider` and pass it to both `AppTheme`
      builders

## 3. Remove the background palette setting and its picker

- [x] 3.1 Delete `PaletteSetting`/`paletteSettingProvider` from `app_prefs_provider.dart` and
      `AppPrefs.paletteId`/`setPaletteId` from `app_prefs.dart`; leave the stored `theme_palette`
      key untouched on disk; delete `test/state/palette_setting_test.dart`; rerun `build_runner`
- [x] 3.2 Add `test/screens/settings/settings_screen_test.dart` asserting Settings › Appearance
      shows the accent picker's title and helper and no "Custom" swatch, and verify it fails while
      `PalettePicker` still renders
- [x] 3.3 Move `accentName` into `accent_picker.dart`, with its unrecognized-palette fallback
      changed from `l10n.themeCustom` to `l10n.accentColorIndigo`; delete
      `app/lib/widgets/palette_picker.dart` and `test/widgets/palette_picker_test.dart`; drop
      `PalettePicker` from `settings_screen.dart`; verify 3.2 passes
- [x] 3.4 Update `test/widgets/accent_picker_test.dart`: drop the `paletteName` import and the test
      comparing accent labels against theme names (nothing left to compare against), add a test
      pinning `settingsAccentHelper` to "Colors the whole app."; verify it fails on the helper text
      against the old copy, then passes after 4.1

## 4. Strings

- [x] 4.1 Change `settingsAccentHelper` to "Colors the whole app." / "Colorea toda la app." in both
      ARB files; delete `settingsThemeTitle`, `settingsThemeHelper`, `themeWarmPaper`,
      `themeInkIris`, `themeSeaGlass`, `themePlum`, `themeSlate`, `themeMoss`, `themeCustom`,
      `themeCustomTitle`, and `themeCustomHue` (and their `@key` metadata) from both files; grep
      `app/lib` to confirm each deleted key is unused first; rerun `flutter gen-l10n`

## 5. Documentation

- [x] 5.1 Update `DESIGN.md`: one color choice (the accent) drives the whole theme, warm paper
      stays the normative reference every other palette is generated from, and the shipped default
      is `ink_iris`
- [x] 5.2 Run `npx @google/design.md lint DESIGN.md` and confirm 0 errors, 0 warnings

## 6. Verification

- [x] 6.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 6.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [x] 6.3 Run `openspec validate unify-app-color --type change --strict` and verify it passes
