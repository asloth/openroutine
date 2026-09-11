## 1. Wide-pill highlight

- [x] 1.1 Add `app/test/screens/floating_nav_bar_test.dart` asserting the selected highlight's rect
      is wider than tall and leaves a margin around the label's rect on both sides, at text scale
      1.0 and 1.6, and verify it fails against the current zero-horizontal-padding layout
- [x] 1.2 Add a named `_horizontalPadding` constant to `_Destination` and apply it via
      `EdgeInsets.symmetric` on the icon-and-label column's padding, and verify 1.1 passes

## 2. Keep the bar on screen in Spanish

- [x] 2.1 Add a test pumping the bar at 360dp width with the Spanish labels at the 1.6x scale cap,
      asserting no exception and that the pill's rect stays within the screen's bounds
- [x] 2.2 Measure "Estadísticas" against the real bundled Lexend font at the 1.6x cap to confirm
      whether the new padding pushes the destination past the existing `maxWidth: 140`
- [x] 2.3 Raise `maxWidth` to 150 to clear the measured requirement with margin, and verify 2.1
      still passes alongside 1.1

## 3. Verification

- [x] 3.1 Run the existing `app/test/screens/app_shell_test.dart` nav bar coverage and verify it
      stays green
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.3 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [x] 3.4 Run `openspec validate fix-nav-highlight --type change --strict` and verify it passes
