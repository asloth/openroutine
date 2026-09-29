## Why

Finishing a routine is the one moment the app gets to be warm about, but the finished screen
stacks Ochi and the summary against the top of the screen and leaves the bottom half empty. It
reads more like a receipt than a win. Sara asked for Ochi in the middle of the screen with
confetti, like a small party.

## What Changes

- Center the finished screen's content vertically when it fits. When the Adjust estimate card or a
  large text size makes it taller than the screen, it scrolls as before.
- Add `ConfettiBurst`, a one-shot confetti pop out of Ochi's center that arcs up, drifts down, and
  fades in about 2.6 seconds. It uses the palette's own colours, never loops, and never takes a tap.
- Play it only on a finished run. A stopped run keeps its resting Ochi and gets no confetti, and
  reduced motion (`disableAnimations`) drops the confetti but keeps Ochi.

## Capabilities

### Modified Capabilities

- `timer-run` — the finished screen centers its content and celebrates a finished run with confetti.

## Impact

**Code.** `app/lib/screens/timer/timer_screen.dart` swaps the summary's `ListView` for a centered,
scrollable `Column`, and wraps the finished mascot in the new
`app/lib/widgets/confetti_burst.dart`. No new packages.

**Tests.** Four widget tests in `app/test/screens/timer/timer_screen_test.dart`: the content is
centered, a finished run shows confetti and still settles, a stopped run shows none, and reduced
motion shows none.

**Storage, schema, and i18n.** None. There are no new strings.

**UI.** The order of the controls is unchanged: Ochi, title, summary, skipped count, Adjust
estimate, and Back to today. Only their vertical position moves, and the confetti is new.

**Rollback.** Revert the change. Nothing persisted changes shape.
