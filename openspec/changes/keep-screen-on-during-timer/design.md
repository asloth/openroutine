## Context

See `proposal.md`. `_TimerScreenState` already reacts to every timer state change in `_react`, which is where Ochi's coffee sips start and stop.

## Goals and non-goals

**Goals:**

- Keep the display awake only while a step is actually running.

**Non-goals:**

- A setting to turn it off. Add one if testers ask.
- Keeping the screen on anywhere other than the timer.

## Decisions

### Running only, not paused

A paused routine means you stepped away, so the screen sleeps and saves battery. Resuming turns it back on.

### A service behind a provider, not direct plugin calls

`ScreenWake` mirrors `AppSounds`: an interface, a real implementation, and a provider tests override. The real implementation catches plugin errors, so a missing platform (tests, the Linux build) never breaks a timer.

### The instance is read once and kept

`dispose` has to release the screen, and `ref` can't be used there. The state reads the provider into a `late final` field on first use and calls it from `dispose`.

## Risks and trade-offs

**Battery on long steps.** → A 20-minute step keeps the screen on for 20 minutes. Accepted for now, and it's the reason for the running-only rule.

**The phone in a pocket.** → An awake screen in a pocket can register touches. Android's own pocket detection covers most of this. If testers report it, a setting is the fix.
