## 1. Mascot moves

- [x] 1.1 Generate `run`, `jump`, and `bounce` into `scene.rml` with `gen_story.py`, verify the project, and preview the frames
- [x] 1.2 Copy the built `mascot.riv` into `app/assets/`
- [x] 1.3 Add `run`, `jump`, `bounce`, and `celebrate` to `MascotReaction`

## 2. Builder starting mode

- [x] 2.1 Add a widget test that the builder opens on Scheduled when asked, and verify it fails
- [x] 2.2 Add `initialMode` and read `mode` on `/routines/new`, and verify 2.1 passes

## 3. Onboarding story

- [x] 3.1 Write widget tests for the beats, Skip, the mascot cues, and the hand-off to the builder, and verify they fail
- [x] 3.2 Add the strings to both ARB files and remove the old slide strings
- [x] 3.3 Build the story screen and verify 3.1 passes

## 4. Verification

- [x] 4.1 Run `flutter analyze --fatal-infos` and verify no issues
- [x] 4.2 Run `flutter test` and verify the suite passes
- [x] 4.3 Install on the Pixel with `adb install -r` and check each beat
