## 1. Make the loading decision testable, and prove the bug

- [x] 1.1 Add `test/widgets/mascot_slot_test.dart` unit tests for a pure `mascotLoadVisual`
      function against `AsyncSnapshot` values (still loading → empty, resolved with no data →
      placeholder, resolved with data → rive), and verify they fail to compile against the
      unmodified widget
- [x] 1.2 Add unit tests for a pure `mascotRiveVisual` function against `RiveState` values (loading
      → empty, failed → placeholder)
- [x] 1.3 Add a widget test using a new `@visibleForTesting` `MascotSlot.debugFileLoader` hook,
      set to a `Completer` that never completes, asserting no placeholder paints while it's
      pending, and verify it fails against the current placeholder-while-loading behavior
- [x] 1.4 Add a widget test asserting the placeholder appears once the loader resolves with no file
- [x] 1.5 Add a widget test building two `MascotSlot`s together with a call-counting loader,
      asserting the loader runs once

## 2. Share the file, stop flashing the old pet

- [x] 2.1 Add the `MascotSlotVisual` enum and the `mascotLoadVisual`/`mascotRiveVisual` functions,
      and verify 1.1–1.2 pass
- [x] 2.2 Move `_file` from a per-instance `late final` to a static, lazily created future shared
      by every slot; stop disposing it in `dispose`; add the `debugFileLoader` test hook that
      clears the cache when set, and verify 1.3–1.5 pass
- [x] 2.3 Wire `build()` to use `mascotLoadVisual`/`mascotRiveVisual` instead of the old inline
      `null`/`switch` checks, rendering an empty `SizedBox` of the slot's size for `empty`

## 3. Keep the docs honest

- [x] 3.1 Update the doc comment on `_MascotSlotState`'s file field and on `_MascotPlaceholder`
      that described the placeholder as the stand-in "until the file is ready," so they describe
      the new empty-while-loading behavior instead
- [x] 3.2 Update the inline comment in `build()` that made the same claim

## 4. Verification

- [x] 4.1 Run `app/test/widgets/mascot_slot_test.dart` and verify all tests, old and new, pass
- [x] 4.2 Run `app/test/screens/onboarding/onboarding_screen_test.dart` and
      `app/test/screens/timer/timer_screen_test.dart` and verify they're unaffected
- [x] 4.3 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 4.4 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
