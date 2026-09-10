## 1. Tokens

- [x] 1.1 Add `AppRadius.tinted` (20), `AppRadius.hero` (24), and their `BorderRadius`
      constants to `app/lib/theme/spacing.dart`
- [x] 1.2 Add `AppTypography.pageTitle` and `AppTypography.sectionLabel` to
      `app/lib/theme/typography.dart`

## 2. `TintedCard`

- [x] 2.1 Write `app/test/widgets/tinted/tinted_card_test.dart` covering: flat fill
      with no shadow, `foregroundColor` reaching text/icons, tap callback, press
      deform of at most 5%, reduced-motion suppression, button semantics present with
      `onTap` and absent without it, and 2.0x text scale with no overflow; watch it
      fail
- [x] 2.2 Implement `app/lib/widgets/tinted/tinted_card.dart`; verify 2.1 passes

## 3. `SoftCircleButton`

- [x] 3.1 Write `app/test/widgets/tinted/soft_circle_button_test.dart` covering: both
      sizes, both styles' fill/icon colors, icon size per button size, tap callback,
      tooltip semantics, minimum 48px hit target at both sizes, press deform, and
      reduced-motion suppression; watch it fail
- [x] 3.2 Implement `app/lib/widgets/tinted/soft_circle_button.dart`; verify 3.1
      passes

## 4. `PageHeader`

- [x] 4.1 Write `app/test/widgets/tinted/page_header_test.dart` covering: 48px row
      height, no `AppBar`/elevation/shadow in the tree, `leading`/`title`/`actions`
      layout with 8px insets and 8px action spacing, and title wrap without overflow
      at 2.0x text scale; watch it fail
- [x] 4.2 Implement `app/lib/widgets/tinted/page_header.dart`; verify 4.1 passes

## 5. `SectionLabel`

- [x] 5.1 Write `app/test/widgets/tinted/section_label_test.dart` covering:
      uppercasing, style and color, 8px horizontal inset, and 2.0x text scale without
      overflow; watch it fail
- [x] 5.2 Implement `app/lib/widgets/tinted/section_label.dart`; verify 5.1 passes

## 6. `SegmentedProgress`

- [x] 6.1 Write `app/test/widgets/tinted/segmented_progress_test.dart` covering:
      segment count, filled-vs-unfilled opacity, the 6px/4px gap threshold at
      `count` 8 and 9, semantics label, and 2.0x text scale (no text is involved, but
      the widget must not overflow its bounds); watch it fail
- [x] 6.2 Implement `app/lib/widgets/tinted/segmented_progress.dart`; verify 6.1
      passes

## 7. `PillSegmentedControl`

- [x] 7.1 Write `app/test/widgets/tinted/pill_segmented_control_test.dart` covering:
      track and selected-pill styling, tap-to-`animateTo`, tab semantics with
      selected state, swiping a paired `TabBarView` moving the pill mid-gesture,
      2.0x text scale growing the control instead of clipping, and reduced-motion
      suppression of the press deform; watch it fail
- [x] 7.2 Implement `app/lib/widgets/tinted/pill_segmented_control.dart`; verify 7.1
      passes

## 8. Barrel and documentation

- [x] 8.1 Add `app/lib/widgets/tinted/tinted.dart` exporting all six widgets
- [x] 8.2 Add a "Tinted surfaces" subsection under Components in `DESIGN.md`
      describing the widget set and its relationship to the neumorphic idiom

## 9. Verification

- [x] 9.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/`
      and verify no issues
- [x] 9.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full
      suite passes
- [x] 9.3 Run `openspec validate add-tinted-surfaces --type change --strict` and
      verify it passes
