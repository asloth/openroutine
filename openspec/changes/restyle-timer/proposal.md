## Why

The timer screen still wears the neumorphic idiom `add-tinted-surfaces` and `add-accent-color`
built the replacement for. It's the single screen the owner cares most about keeping simple, so
this change restyles it in place: same buttons, same positions, same behavior — only the surfaces
and colors move to tinted paper.

## What Changes

- The running screen's background becomes `context.routineCardColors.timerGround` instead of the
  theme's default `scaffoldBackgroundColor`.
- The `LinearProgressIndicator` under "Step N of M" becomes a `SegmentedProgress`, one segment per
  step, filled through the current step, colored `onSurface`.
- Close becomes a neutral 48px `SoftCircleButton` (was a plain `IconButton`).
- Pause/Resume and Restart step become 64px `SoftCircleButton`s in the `accent` style (was
  `NeumorphicCircleButton`).
- Do later's label switches from the theme's default `TextButton` color to an explicit
  `onSurface`, so it doesn't compete with the accent-colored Done button.
- Everything else — the emoji, step name, `TimerClock` ring, Done/Finish, the completion summary,
  and every existing interaction — is untouched.

The ring keeps riding the accent (`CircularProgressIndicator` reads `colorScheme.primary`, which
`add-accent-color` pointed at the user's chosen accent). It deliberately does not turn green:
green is reserved for "a routine is coming up soon" on the home screen, so a running timer using it
too would blur that meaning.

## Capabilities

### New Capabilities

- `timer-mode` — the running timer screen's visual surface: a tinted ground, flat circular
  controls, and segmented step progress, with the same control layout and behavior the screen
  already has.

## Impact

**Code.** `app/lib/screens/timer/timer_screen.dart` only. No changes to
`app/lib/services/timer/timer_machine.dart`, `app/lib/state/timer_provider.dart`,
`app/lib/theme/theme.dart`, or any shared widget.

**Tests.** `app/test/screens/timer/timer_screen_test.dart`: the `NeumorphicCircleButton` finder
becomes a `SoftCircleButton` finder; new assertions cover the tinted ground, the segmented
progress, and text-scale tolerance. Every existing behavioral assertion (Done/Finish, Do later's
hide rule, Close's abandon confirmation, pause/resume, calibration) keeps passing unmodified in
substance.

**Storage and schema.** None.

**i18n.** None. No new user-facing strings; every existing tooltip and label carries over as-is.

**Rollback.** Reverting `timer_screen.dart` and its test file fully undoes this change — nothing
else in the app references the timer screen's internals.
