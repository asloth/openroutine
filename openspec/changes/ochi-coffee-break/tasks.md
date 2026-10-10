## 1. Draw the coffee break

- [x] 1.1 Back up `rive/mascot/scene.rml` to `build/scene.pre-coffee.rml.bak`
- [x] 1.2 Write `rive/mascot/build/gen_coffee.py`: the mug, paw, and steam, the `hasCoffee` and
      `sip` view model properties, `coffee_in`, `coffee_hold`, and `coffee_sip`, and the mug pinned
      hidden in every existing animation
- [x] 1.3 Render a preview headless and check the hold, the sip, a reaction from the hold, sleeping,
      and a second palette
- [x] 1.4 Build the `.riv` and copy it to `app/assets/mascot.riv`

## 2. Wire it into the timer

- [x] 2.1 Add tests: `MascotReaction.sip` fires `sip`, and `MascotSlot.hasCoffee` defaults to false;
      verify they fail
- [x] 2.2 Add timer tests: a 6-minute step holds coffee, a 5-minute step doesn't, sips arrive every
      45 seconds, a short step never sips, pausing puts the cup down and stops sips, and moving on
      to a short step stops sips; verify they fail
- [x] 2.3 Add `MascotSlot.hasCoffee` and `MascotReaction.sip`, and verify 2.1 passes
- [x] 2.4 Add `_syncSips` and pass `hasCoffee` to the running mascot, and verify 2.2 passes

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [ ] 3.3 Run a routine with a step over 5 minutes on the Pixel 9a and watch for a sip
