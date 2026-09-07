## Why

The motion contract exists and nothing obeys it. `AppMotion` landed with the tokens, the curves and the reduced-motion resolver, and then every animated surface in the app carried on as before. The result is an app that was redesigned but not re-timed.

Some of the gaps are defects against requirements the `motion-system` spec already states, not merely untidiness. The neumorphic circle and pill buttons animate their pressed state through an `AnimatedContainer` with no `curve:` argument, which in Flutter means **linear** — the one easing the spec reserves for progress indicators. They change their shadow but never deform, while the spec requires an interactive control to give visible feedback on press. Neither they nor the onboarding page slide consult the platform's reduced-motion setting.

The mascot is already correct and is left alone: it checks `disableAnimations` before starting and while building, and its breath runs a fixed number of cycles and settles rather than looping forever. It is the one surface that already does this properly, which is why the ambient-motion requirement below describes its behaviour rather than changing it.

Separately, all ten routes use `builder:`, so every navigation is a stock Material push. Screen transitions are the largest single contributor to an interface reading as designed rather than assembled, and a calm cross-fade reinforces the app's low-arousal register instead of fighting it.

## What Changes

- Replace the inline durations and curves with `AppMotion` tokens: the two 120ms button animations and the onboarding page slide.
- Route those animated durations through `context.motion(...)` so reduced-motion is honoured by default rather than remembered per widget.
- Give the neumorphic circle and pill buttons an explicit non-linear curve and the press-scale deformation the spec already requires.
- Replace the ten `GoRoute` `builder:` entries with `pageBuilder:` and a shared transition, so navigation animates with the entrance and exit easing the spec defines.

Not in this change: staggered list entrances and other sequenced reveals. Repeated eye-drawing motion works against a calm, low-arousal interface, and the app opens the routines list many times a day. The stagger token stays defined and unused.

## Capabilities

### Modified Capabilities

- `motion-system` — adds requirements for navigation transitions and for continuous ambient motion under reduced-motion. The existing requirements on easing, duration bounds and press deformation are unchanged; this change makes the app conform to them.

## Impact

**Code.** `app/lib/main.dart` (route definitions), `app/lib/theme/neumorphic.dart` (two button states), `app/lib/screens/onboarding/onboarding_screen.dart` (page slide), plus a shared page-transition helper. Widget tests for each. `mascot_slot.dart` is deliberately untouched.

**Storage and schema.** None. Motion is presentation only; nothing is persisted, nothing crosses the Drive sync or import/export boundary, and no file under `schemas/` changes.

**i18n.** None.

**Dependencies.** None. `CustomTransitionPage` ships with go_router, already a dependency.

**Risk.** Route transitions are the one visible behavioural change. Every existing widget test that navigates now has an animation to settle, so tests that assumed an instant push may need an explicit settle. That is a test-visibility change, not a behaviour regression, and it is the main thing to watch while implementing.

**Rollback.** Reverting restores `builder:` routes and the inline values. Nothing is persisted, so there is no migration to unwind.
