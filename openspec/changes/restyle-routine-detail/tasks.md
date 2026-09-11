## 1. Header row

- [x] 1.1 Update `routine_detail_screen_test.dart`'s test router so a route exists to pop back to,
      write a test asserting no `AppBar` renders and Back pops to it, and watch it fail
- [x] 1.2 Write tests asserting Share and Edit render as neutral `SoftCircleButton`s with today's
      tooltips, Edit navigates to the edit route, and More still opens Delete's confirmation dialog
      (both confirm and cancel), and watch them fail
- [x] 1.3 Remove the `AppBar`; add the 48px header row (Back, Share, Edit, More) wrapped in
      `SafeArea(bottom: false)` and an `AnnotatedRegion<SystemUiOverlayStyle>`; verify 1.1 and 1.2 pass

## 2. Name, chip, and summary card

- [x] 2.1 Write a test asserting the moment chip and the summary card both read
      `context.routineCardColors.fill`/`onFill`, and that a routine with no moment still shows the
      existing fallback text, and watch it fail
- [x] 2.2 Render the routine name in `AppTypography.pageTitle`, the moment chip, and the summary
      card as a `TintedCard`; verify 2.1 passes

## 3. History dots

- [x] 3.1 Write tests covering the three dot states (filled, ringed, faint-ringed) and their
      tooltips against `context.routineCardColors.onFill`, and watch them fail
- [x] 3.2 Restyle `_HistoryDots` to 12px circles reading `context.routineCardColors.onFill`; verify
      3.1 passes

## 4. Start Timer and Add step

- [x] 4.1 Write tests asserting Start Timer's enabled rule and helper text are unchanged, and Add
      step still navigates to the new-step route; watch them fail if the restyle broke either
- [x] 4.2 Confirm both still pass after the surrounding layout changes (no behavioral change
      expected here)

## 5. Step list container

- [x] 5.1 Write a test asserting the steps render inside one bordered, clipped container with
      exactly `steps.length - 1` dividers and none after the last row, and watch it fail
- [x] 5.2 Replace the per-step `NeumorphicCard` with one outer container and a divider between rows;
      keep `ReorderableListView`, `buildDefaultDragHandles: false`, the transparent
      `proxyDecorator`, the saving-order lock, and the single-step/empty-list branches; verify 5.1
      passes. The rows are shorter without their old margin, so the two existing drag tests needed
      their hard-coded drag distance raised (180px to 260px) to still cross two rows — the
      interaction they cover is unchanged

## 6. Text scale

- [x] 6.1 Write a test pumping the screen at 1.5x and 2.0x text-scale factors (via
      `tester.platformDispatcher.textScaleFactorTestValue`, cleared after) and asserting no overflow
      error is reported; watch it fail if anything clips
- [x] 6.2 Fix any overflow found; verify 6.1 passes

## 7. Verification

- [x] 7.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 7.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [x] 7.3 Run `openspec validate restyle-routine-detail --type change --strict` and verify it passes
