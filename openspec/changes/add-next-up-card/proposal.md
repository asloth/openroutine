## Why

`add-upcoming-highlight` turns a routine card green once it's coming up, but a card still only
turns green in place, wherever its moment group happens to sort it. On the Scheduled tab, that
means the one routine someone's about to run isn't necessarily near the top, and isn't any
bigger or more prominent than the ones hours away. Someone opening the app to see what's next
still has to scan the whole list.

## What changes

- On the Scheduled tab only, a hero card sits above the moment groups, showing the next routine
  left to run today: the earliest-starting scheduled routine whose window hasn't ended and that
  isn't already completed today.
- The card shows the moment, the start time, the routine name, up to five step emoji, the step
  count and estimate, and a "Start Timer" pill that jumps straight into the timer.
- It's the fixed upcoming green when `upcomingState` says the routine is coming up, and the
  accent otherwise — the same two fills the list cards already use.
- The routine still appears in its moment group below, unchanged. Nothing else on the screen
  moves.
- No hero card when nothing qualifies (everything's done, or nothing's left today), and none on
  the Flexible tab, which has no start times to rank by.

## Capabilities

### New Capabilities

- `next-up` — which routine, if any, is "next up" today, and how its hero card presents and
  behaves.

## Impact

**Code.** One new pure service, `app/lib/services/routines/next_up.dart`, and
`app/lib/screens/routines_list/routines_list_screen.dart` (a new private widget for the hero
card, plus wiring it above the Scheduled tab's moment groups). No other screen changes.

**Screens.** Only the routines list, and only its Scheduled tab. The Flexible tab, the header,
the segmented control, and every moment-group card are unchanged.

**Storage and schema.** None. This reads existing routine, step, and completion data; nothing
new is persisted.

**i18n.** One new string in both `app_en.arb` and `app_es.arb`: `routinesNextUp`.

**Rollback.** Reverting this change removes the hero card and the new string; every routine
goes back to only appearing in its moment group. Nothing persisted changes shape, so there's
nothing to migrate either direction.
