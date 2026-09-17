## 1. Equal-width destination slots

- [x] 1.1 Add a test to `app/test/screens/floating_nav_bar_test.dart` measuring all three
      destinations' highlight widths at text scale 1.0 and asserting they're equal, and verify it
      fails against the current `Flexible`-based layout
- [x] 1.2 Add a test asserting the selected highlight stays wider than tall when the shortest label
      ("Today") is the one selected
- [x] 1.3 Wrap the destination `Row` in `IntrinsicWidth` and switch each destination's flex wrapper
      from `Flexible` to `Expanded`, and verify 1.1 and 1.2 pass

## 2. Keep the docs honest

- [x] 2.1 Update the `_horizontalPadding` doc comment, which described the old content-sized
      slot width, to describe the shared-slot-width layout instead
- [x] 2.2 Update the `ConstrainedBox` comment on `_Destination` describing the 360dp-fit math, so it
      accounts for all three slots sharing the widest one's width rather than just the two
      longest-label destinations

## 3. Verification

- [x] 3.1 Run the existing large-text-scale and 360dp-fit tests in
      `app/test/screens/floating_nav_bar_test.dart` and verify they stay green
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.3 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
