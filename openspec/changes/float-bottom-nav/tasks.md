# Tasks: Float the bottom nav bar on a tinted-paper pill

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 230–280 |
| 400-line budget risk | Low |
| 400-line budget at risk | No |
| Chained PRs recommended | No |
| Suggested split | — |
| Delivery strategy | single |
| Chain strategy | — |

Decision needed before apply: No
Chained PRs recommended: No
400-line budget risk: Low

## 1. The bar itself

- [x] 1.1 RED — Rewrite `app/test/screens/app_shell_test.dart` against a
      `FloatingNavBar` that doesn't exist yet: both destinations render, the
      stock `NavigationBar` is gone, and the existing overflow-menu, Statistics,
      state-preservation, Settings, and Import coverage carries over against
      the new bar. Verify it fails to compile because `floating_nav_bar.dart`
      doesn't exist
- [x] 1.2 GREEN — Add `app/lib/screens/shell/floating_nav_bar.dart`: a flat
      pill (`surfaceContainerLowest` fill, 1px `outlineVariant` border, fully
      rounded, no shadow, 5px padding, 4px gap) holding one destination per
      entry (22px icon above a 12px Lexend label, `primaryContainer` fill and
      `onPrimaryContainer` foreground when selected). Wire it into
      `AppShell` in place of `NavigationBar`, keeping the same
      `goBranch(index, initialLocation: index == currentIndex)` behavior.
      Verify 1.1 passes
- [x] 1.3 Confirm `PopupMenuButton`, Settings, and Import coverage still
      passes against the new bar (they don't depend on which widget renders
      the destinations)

## 2. Motion, semantics, and hit targets

- [x] 2.1 RED — Assert the selected destination reports `selected` semantics
      and the other does not; verify it fails against a bar with no semantics
      wired up
- [x] 2.2 GREEN — Wrap each destination in one `Semantics(selected:,
      button: true, label:, excludeSemantics: true)` node. Verify 2.1 passes
- [x] 2.3 Confirm each destination's fill is driven by an `AnimatedContainer`
      using `AppMotion.standard`/`AppMotion.transition` through
      `context.motion`, not a literal duration or curve
- [x] 2.4 Confirm each destination's `ConstrainedBox` floor keeps it at or
      above the 48px hit-target minimum in both dimensions

## 3. The body sees the pill

- [x] 3.1 RED — Assert the body's `MediaQuery.padding.bottom` is at least the
      pill's measured height; verify it fails while `extendBody` is off
- [x] 3.2 GREEN — Set `Scaffold.extendBody: true` in `AppShell`. Verify 3.1
      passes

## 4. Text scale

- [x] 4.1 RED — Assert neither destination's label overflows at 1.5x and
      2.0x text scale on a 360×780 surface; verify it fails (a `RenderFlex`
      overflow at 2.0x, confirmed before adding any clamp)
- [x] 4.2 GREEN — Clamp the label's `textScaler` at a 1.6x ceiling and cap
      each destination's width at 140 logical pixels, so a label that still
      doesn't fit wraps instead of overflowing. Verify 4.1 passes. Document
      the clamp's rationale in `design.md` and in a code comment, per the
      brief for this change
- [x] 4.3 Confirm the `Icon` itself needs no clamp, since `Icon` sizes in
      logical pixels rather than scaling with text

## 5. Verification

- [x] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from
      `app/` and verify no issues
- [x] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify
      the full suite passes
- [x] 5.3 Measure the pill's rendered height at 1.0x, 1.5x, and 2.0x text
      scale and record it in the change's report
- [x] 5.4 Run `openspec validate float-bottom-nav --type change --strict` and
      verify it passes
