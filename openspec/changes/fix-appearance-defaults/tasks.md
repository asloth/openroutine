## 1. Segmented button theme

- [x] 1.1 Add a widget test asserting a selected `SegmentedButton` segment paints with the palette's `primaryContainer`, the same role the chip theme uses, and verify it fails because no `segmentedButtonTheme` exists
- [x] 1.2 Add `segmentedButtonTheme` to `AppTheme._build` using the chip theme's roles, and verify 1.1 passes
- [x] 1.3 Add a test running the same assertion against a generated palette whose secondary diverges sharply in hue, so the defect this fixes cannot return unnoticed, and verify it passes

## 2. Named default palette

- [x] 2.1 Add a test asserting `Palette.fromStorageId(null)` returns the default palette and that the default is `sea_glass`, and verify it fails while the default is warm paper
- [x] 2.2 Introduce `Palette.defaultPalette`, point `fromStorageId`'s null and orElse fallbacks and both `AppTheme` builders at it, set it to `sea_glass`, and verify 2.1 passes
- [x] 2.3 Add a test asserting an unrecognised stored identifier also resolves to the default, and verify it passes
- [x] 2.4 Add a test asserting a stored `warm_paper` still resolves to warm paper, proving an existing choice survives the default changing, and verify it passes
- [x] 2.5 Verify no `warmPaper` fallback remains by grepping `app/lib` and confirming the only references are its own definition, the generated-palette documentation, and the builtIns list

## 3. Documentation

- [x] 3.1 Update `DESIGN.md` to state that warm paper is the normative reference every palette is generated from while the shipped default is sea glass, with no value inventory
- [x] 3.2 Verify `npx @google/design.md lint DESIGN.md` still reports 0 errors and 0 warnings

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or above the current 263 baseline
- [x] 4.3 Run `openspec validate fix-appearance-defaults --type change --strict` and verify it passes
