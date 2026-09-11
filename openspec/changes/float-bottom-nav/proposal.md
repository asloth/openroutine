## Why

`replace-overflow-with-bottom-nav` put Routines and Statistics in a stock Material
`NavigationBar`. That was the right structure — the wrong surface. The tinted-paper
redesign (`add-tinted-surfaces`) replaces every other piece of Material chrome with a
flat, tinted idiom and explicitly names `NavigationBar` as one of the things going: "no
stock Material chrome — no `AppBar` strip, `TabBar`, `NavigationBar`, or FAB shadow." A
full-width bar with a shadowed top edge is exactly that chrome.

Four other screens are moving to tinted surfaces in parallel. The bar is the one piece
of navigation chrome that isn't a screen, so it gets its own change rather than riding
along with one of theirs.

## What Changes

- Replace the `NavigationBar` in `AppShell` with a floating pill: a flat,
  `surfaceContainerLowest` fill, a 1px `outlineVariant` border, fully rounded, no
  shadow, centered above the bottom safe area.
- Same two destinations, same icons, same labels, same `goBranch` behavior as today.
  Nothing about *where* the user goes or *what* is tapped changes — only how the bar
  renders and animates.
- `Scaffold.extendBody` turns on, so the body scrolls under the floating pill instead of
  stopping above a reserved strip, and screens that pad their lists by
  `MediaQuery.padding.bottom` see the pill's height in that padding.
- The selected destination's fill animates between destinations using
  `app/lib/theme/motion.dart` tokens, through the reduced-motion resolver.
- The bar's labels grow with the system text scale, capped at 1.6x rather than
  Material's 1.3x — see `design.md` for why a cap is needed at all.

## Capabilities

### New Capabilities

- `bottom-navigation` — the floating pill's surface, sizing, motion, and accessibility
  floor: what replaces `NavigationBar` as the concrete widget rendering
  `app-navigation`'s destinations. `app-navigation` (from
  `replace-overflow-with-bottom-nav`, not yet archived into `openspec/specs/`) still
  owns the destinations themselves, their discoverability, and their
  state-preservation guarantee — none of that is restated or changed here. This change
  supersedes only that capability's implied `NavigationBar` rendering; when
  `replace-overflow-with-bottom-nav` archives, its rendering requirement should be read
  as superseded by `bottom-navigation`.

## Impact

**Code.** `app/lib/screens/shell/app_shell.dart` (swap `NavigationBar` for the new
widget, turn on `extendBody`), a new `app/lib/screens/shell/floating_nav_bar.dart`, and
`app/test/screens/app_shell_test.dart`.

**Screens.** None of the four screens the parallel tinted-surface changes touch. This
change owns only the shell.

**Storage and schema.** None.

**i18n.** None. The bar keeps the same two labels (`navRoutines`, `navStats`) `app-navigation`
already added; no new string is introduced.

**Accessibility.** The bar's hit targets stay at the 48px floor. Its labels now grow
past Material's 1.3x clamp, capped at 1.6x — more headroom than before, not less. Each
destination keeps tab semantics carrying the selected state.

**Rollback.** Reverting restores the `NavigationBar` `AppShell` had. Nothing persisted
changes shape, so there's nothing to unwind beyond the widget swap itself.
