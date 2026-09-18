## Why

On the running timer, the header row — the back button, the routine name and "1 of 4" title, and
the pause button — scrolls with the rest of the screen. `_Running.build` returns a single
`ListView` whose first child is that row, so any scroll offset slides it up under the `SafeArea`'s
top edge, where the viewport clips it flat. The user described it as "the circles up are not full
circle ... its a line at the top" — `SoftCircleButton` itself draws a correct circle; it's getting
cut off, not misdrawn.

## What Changes

- Restructure `_Running` into a `Column` with the header row fixed above an `Expanded` `ListView`
  holding the rest of the content, the same pattern `routine_detail_screen.dart` already uses.
  Unscrolled spacing is unchanged.
- No change to `_Summary`: it has no circular control that scrolls under the edge.

## Capabilities

### Modified Capabilities

- `timer-run` — the running screen's header no longer scrolls with the rest of the run.

## Impact

**Code.** `app/lib/screens/timer/timer_screen.dart` only. One new widget test in
`app/test/screens/timer/timer_screen_test.dart`.

**Storage and schema.** None.

**i18n.** None — no new strings.

**Rollback.** Revert the widget restructure; nothing persisted changes shape.
