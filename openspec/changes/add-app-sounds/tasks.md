## 1. Tests first

- [x] 1.1 Nudge channel test expects `step_progress_nudge_v2` with `ochi_bip_bip_boo` and retires v1
- [x] 1.2 Timer test: finishing a step pops, finishing the routine celebrates, skip and stop stay quiet
- [x] 1.3 Setting test: on by default, turning it off persists and silences the player
- [x] 1.4 Settings screen test for the Sounds switch

## 2. Implementation

- [x] 2.1 Add `audioplayers`, `assets/sounds/`, and `res/raw/ochi_bip_bip_boo.ogg` (kept in `keep.xml`)
- [x] 2.2 `AppSounds`, `SoundsEnabledSetting`, and `appSoundsProvider`
- [x] 2.3 Play the sounds from `RoutineTimer`
- [x] 2.4 Settings switch and strings in both ARB files

## 3. Verification

- [x] 3.1 `flutter analyze --fatal-infos` and the full suite (one pre-existing failure on `main`, unrelated)
- [ ] 3.2 Hear all three on the Pixel
