## Why

The owner's report, on her Pixel: "when i start a routine it shows the old mascot for an instant
like half a second and then changes for this new one mascot." Every `MascotSlot` instance owns
`late final Future<File?> _file = _load();`, so every new slot — the one on the timer screen
included — decodes `assets/mascot.riv` from scratch and repeats the delay. While that decode is in
flight, `FutureBuilder` falls back to `_MascotPlaceholder`, the pre-Rive hand-drawn pet, and
`RiveWidgetBuilder`'s own builder does the same for any state short of `RiveLoaded`. So the hand-
drawn pet flashes on screen before the real one takes over, every time a screen with a fresh slot
opens.

## What Changes

- Load the Rive `File` at most once per app run: a static future shared by every `MascotSlot`,
  instead of one per instance. A slot's `dispose` no longer disposes it, since other slots may
  still be using it.
- Stop showing the hand-drawn placeholder while that shared file, or the state machine inside it,
  is still loading. The slot renders an empty box at its own size instead, so layout doesn't jump.
  The placeholder is now only for when there's truly no pet to show: no renderer (`flutter test`),
  or the file failed to decode.
- Factor the "what to show" decision into two small, `@visibleForTesting` pure functions
  (`mascotLoadVisual`, `mascotRiveVisual`) returning a `MascotSlotVisual` enum, so the loading logic
  is unit-testable without a real `.riv` file.

## Capabilities

### Modified Capabilities

- `mascot` — changes the "slot always draws something" guarantee: the stand-in is for when Rive is
  unavailable or failed to load, not for the ordinary loading window, which now stays empty.

## Impact

**Code.** `app/lib/widgets/mascot_slot.dart` only. `MascotMood`, `MascotReaction`, `MascotCue`, the
constructor API, the warm-up-then-settle timer, `_apply`, the theme colours, cue handling,
hit-testing, the `_wake` listener, and the placeholder painter itself are all unchanged.

**Tests.** `app/test/widgets/mascot_slot_test.dart` gains unit tests for the two pure visual
functions, plus widget tests using a new `@visibleForTesting` `MascotSlot.debugFileLoader` hook:
the slot stays empty while a substituted loader is still pending, falls back to the placeholder
once it resolves with no file, and two slots built together share one load. The existing screen
tests that touch `MascotSlot` (`onboarding_screen_test.dart`, `timer_screen_test.dart`) read the
widget's `mood` and `cue` properties, not its internal visual, so they're unaffected and pass
unchanged.

**Storage and schema.** None.

**i18n.** None. No user-facing strings.

**Rollback.** Reverting restores the per-instance file load and the placeholder-while-loading
behaviour. Nothing persisted changes shape, so there's nothing to unwind.
