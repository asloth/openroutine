## Why

The second screen of the redesign from `OpenRoutine.dc.html` is the timer, which the design calls Run. Today the running screen centres a big step emoji inside a progress ring, with round Pause and Restart step controls and a segmented bar for the whole run. The design is calmer and easier to read at a glance: the mascot keeping you company, the step and its clock, one bar for the step, a clear next action, and the rest of the run listed underneath so you always know what's left.

As with home, the design's green and blob mascot don't ship. Colours come from the palette, and the mascot is the Rive pet.

## What Changes

- Replace the header with a back control, the routine's name, a short step counter ("1 of 3"), and a small Pause/Resume control.
- Show the mascot, resting calmly, in place of the step emoji.
- Keep the count-up clock and its estimate colour change, and replace the ring with a single bar that fills to the step's estimate.
- Show a halfway banner during a step that opted into mid-step reminders.
- Make the actions **Done — next step** (or **Finish**), with **Do it last** and **Skip** beneath it. Skip is new on screen; the timer already supported it.
- Add **Rest of the run**: every step in the run with its state and minutes, and the minutes left.
- Remove the Restart step control and the segmented run bar.
- Restyle the finished screen: the mascot cheering, "That's the whole thing.", the estimate adjustment prompt, and **Back to today**.

This supersedes the `restyle-timer` requirements for the segmented progress, the progress ring, the close control, and the Pause and Restart step circle controls.

## Capabilities

### New Capabilities

- `timer-run` — what the running and finished timer screens show and which actions they offer.

## Impact

**Code.** `app/lib/screens/timer/` and its widget tests. The timer state machine doesn't change.

**Storage and schema.** None.

**i18n.** New and changed strings for the counter, the actions, the halfway banner, Rest of the run, and the finished screen, in both `app_en.arb` and `app_es.arb`.

**Rollback.** Reverting restores the previous timer screen. Nothing is persisted differently.
