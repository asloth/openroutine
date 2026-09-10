## 1. Header (slice 1)

- [x] 1.1 Add a test asserting the routines list renders no `AppBar` and shows the app title,
      and verify it fails against the current screen
- [x] 1.2 Add a test asserting the settings control navigates to `/settings` when tapped
      (`SoftCircleButton` by tooltip), and verify it fails
- [x] 1.3 Replace the `AppBar` with a `PageHeader` (title `l10n.appTitle`, one action: a
      neutral `SoftCircleButton` with the existing settings icon, tooltip, and `onPressed`),
      wrap the `Scaffold` body in `AnnotatedRegion<SystemUiOverlayStyle>` (dark status-bar
      icons in light theme, light in dark theme, transparent status bar) and
      `SafeArea(bottom: false)`, and verify 1.1 and 1.2 pass

## 2. Segmented control (slice 2)

- [x] 2.1 Add a test asserting no `TabBar` is present and a `PillSegmentedControl` with labels
      "Scheduled"/"Flexible" is, and verify it fails
- [x] 2.2 Add a test tapping the "Flexible" segment and asserting the Flexible tab's content
      becomes visible, and verify it fails
- [x] 2.3 Add a test swiping the tab content and asserting the segmented control's selection
      follows, and verify it fails
- [x] 2.4 Replace `TabBar` with `PillSegmentedControl`, sharing the existing
      `DefaultTabController`'s controller with the `TabBarView` (via `Builder` +
      `DefaultTabController.of(context)`), and verify 2.1-2.3 pass

## 3. Section labels and card rhythm (slice 3)

- [x] 3.1 Add a test asserting a moment group heading renders as a `SectionLabel`, and verify
      it fails
- [x] 3.2 Replace the group heading `Text` with `SectionLabel`; retune the list's spacing to
      12px between a label and its first card, 12px between cards in the same group, and 28px
      between groups, and verify 3.1 passes

## 4. Tinted routine cards (slice 4)

- [x] 4.1 Add a test asserting a routine card's fill and foreground colors equal
      `context.routineCardColors.fill`/`onFill`, and verify it fails
- [x] 4.2 Add a test asserting the start time renders inside the existing 62px column in
      `onFill`, and verify it fails
- [x] 4.3 Add a test asserting "Start Low Mode" still starts Low Mode for the routine's core
      steps when pressed, and verify it fails (behavior should already pass; keep the
      assertion as a regression guard through the surface change)
- [x] 4.4 Replace `NeumorphicCard` with `TintedCard` (`color`/`foregroundColor` from
      `routineCardColors`, 12px right padding when the card carries the Low Mode pill), style
      the start time and secondary text (step count, Low Mode guidance) in `onFill`
      (secondary text at 80% opacity), and turn "Start Low Mode" into a 48px pill (10%-opacity
      `onFill` fill, Lexend 14 w500 label in `onFill`), and verify 4.1-4.3 pass

## 5. FAB and bottom clearance (slice 5)

- [x] 5.1 Add a test asserting `floatingActionButtonTheme.elevation` is 0 and its shape is a
      `CircleBorder`, and verify it fails
- [x] 5.2 Update `floatingActionButtonTheme` in `app/lib/theme/theme.dart` (elevation 0 for
      every state, `CircleBorder`), and verify 5.1 passes
- [x] 5.3 Add the list's bottom padding: `MediaQuery.paddingOf(context).bottom` plus the
      existing FAB clearance

## 6. Text scale and overflow (slice 6)

- [x] 6.1 Add a test pumping the screen at 1.5x and one at 2.0x text scale
      (`tester.platformDispatcher.textScaleFactorTestValue`, cleared in a `tearDown`) with a
      routine present, asserting no overflow error is reported, and verify it fails if the
      current layout clips
- [x] 6.2 Fix any overflow the tests in 6.1 surface (none needed — the layout already held at
      2.0x)

## 7. Verification

- [x] 7.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify
      no issues
- [x] 7.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite
      passes (496 pass)
- [x] 7.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')`
