## 1. Theme header on the background palette picker

- [x] 1.1 Add `settingsThemeTitle` and `settingsThemeHelper` to both ARB files and regenerate
      localizations
- [x] 1.2 Add a widget test asserting `PalettePicker` shows the theme title and helper above its
      swatches, and verify it fails while `PalettePicker` has no header
- [x] 1.3 Add a widget test asserting the theme title renders above the accent picker's title when
      both are shown in Settings' own order, and verify it fails
- [x] 1.4 Add the title and helper `Padding` blocks to `PalettePicker`, matching `AccentPicker`'s
      padding, and verify 1.2 and 1.3 pass

## 2. Accent swatches named by color

- [x] 2.1 Add six `accentColor*` strings (Terracotta, Indigo, Teal, Magenta, Blue, Green) to both
      ARB files and regenerate localizations
- [x] 2.2 Update `test/widgets/accent_picker_test.dart`'s swatch-label assertions to expect the new
      color words, and add an assertion that an accent swatch's label differs from
      `paletteName()`'s theme name, and verify both fail against the current `accentName`-less
      `AccentPicker`
- [x] 2.3 Add `accentName(AppLocalizations, Palette)` next to `paletteName()` in
      `palette_picker.dart`
- [x] 2.4 Use `accentName()` in `AccentPicker` for the swatch label, tooltip, and "{name} selected"
      caption, and verify 2.2 passes

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [x] 3.3 Run `openspec validate fix-appearance-section --type change --strict` and verify it
      passes
