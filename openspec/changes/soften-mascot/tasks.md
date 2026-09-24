## 1. Rive source

- [x] 1.1 Back up `scene.rml` as `build/scene.pre-soft.rml.bak`, and save the reference as `build/softer-reference.png`
- [x] 1.2 Run `build/gen_soft.py build/scene.pre-soft.rml.bak build/softer-reference.png scene.rml --shading`, then `rive . --verify` and `rive inspect . --summary`, and verify no problems
- [x] 1.3 Render every move at its start, middle, and end, and verify the feet show no seam and the smile shows in celebrate, step done, jump, and bounce
- [x] 1.4 Click the body, a side tuft, the curl, the lower edge, and an empty corner with `--pointer`, and verify `tap` fires on the pet only
- [x] 1.5 Render with a dark-theme body and accent, and verify the shading and shadow still read
- [x] 1.6 Run `build/fix_leg_ledge.py` to drop the inward shelf at the top of each foot, which the higher fur edge left showing as a bar between the legs on a jump's landing, and render every leg move to verify it's gone

## 2. App

- [x] 2.1 Build with `rive . --once` and copy `build/mascot.riv` to `app/assets/mascot.riv`
- [x] 2.2 Run `flutter analyze --fatal-infos` and `flutter test` from `app/`, and verify both pass. No Dart behaviour changes: the view model is the same, so there's no new test to write first
- [ ] 2.3 Install on the Pixel with `adb install -r`, and check the pet on Today and in a finished run
