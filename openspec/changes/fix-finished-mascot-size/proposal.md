## Why

A report came in from the Pixel 9a: "the mascot here more big like in the routine run." On the
finished screen ("That's the whole thing."), the mascot reads noticeably smaller than it does while
a routine is running. In `app/lib/screens/timer/timer_screen.dart`, the running screen's
`MascotSlot` passes `size: 168`, and the finished screen's `MascotSlot` passes `size: 124`. Nothing
ties the two together, so they've drifted apart, and the same pet reads as a different size
depending on which screen it's on.

## What Changes

- Add one private constant, `_mascotSize`, at 168 — the running screen's existing size — and read it
  from both the running and the finished screen's `MascotSlot`. One source keeps the two screens
  from drifting apart again.

## Capabilities

### Modified Capabilities

- `timer-run` — the finished screen's mascot requirement now also guarantees the mascot is the same
  size there as on the running screen, on top of the existing cheering/resting mood guarantee from
  `redesign-timer-run`.

## Impact

**Code.** `app/lib/screens/timer/timer_screen.dart` only: one new constant, and the two `size:`
arguments that already existed on the running and finished `MascotSlot`s now read it.
`app/lib/widgets/mascot_slot.dart` is untouched — another change owns it.

**Tests.** Adds a widget test to `app/test/screens/timer/timer_screen_test.dart` that finishes a run
and asserts the finished screen's mascot is at least 160 and matches the running screen's size.
Making the finished mascot bigger pushes `Back to today` further down the finished screen's
`ListView`, past its default lazy-build extent, so the existing `finishing the run shows the summary
and writes a log` test now scrolls to it before asserting it's there. Nothing else in that test
changed.

**Storage and schema.** None.

**i18n.** None. No new user-facing strings.

**UI.** The finished screen's title, summary line, Adjust estimate card, Back to today, mood
(cheering, or resting on an abandoned run), and all padding and spacing are unchanged. Only the
mascot's rendered size grows to match the running screen. The running screen is visually unchanged.

**Rollback.** Reverting restores the two independent size literals (168 and 124). Nothing persisted
changes shape, so there's nothing to unwind.
