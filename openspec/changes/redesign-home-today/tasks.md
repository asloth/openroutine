## 1. Typefaces

- [x] 1.1 Add a test asserting the display family is Bricolage Grotesque and the body family is Plus Jakarta Sans, and verify it fails
- [x] 1.2 Bundle static instances of both families with their OFL licences, swap `AppTypography` and the one hardcoded family, remove Lexend and Inter, and verify 1.1 passes
- [x] 1.3 Update `DESIGN.md` and `docs/SPEC.md`, and verify the `DESIGN.md` lint reports 0 errors and 0 warnings

## 2. Header and nudge card

- [x] 2.1 Add widget tests for the date, the greeting, the streak pill, and the Settings gear, and verify they fail
- [x] 2.2 Build the header and verify 2.1 passes
- [x] 2.3 Add widget tests for the nudge card: shown with the time until the next routine, Start opens the timer, hidden when nothing is upcoming; verify they fail
- [x] 2.4 Build the nudge card with the Rive mascot and verify 2.3 passes

## 3. Anytime today, timeline, and Other days

- [x] 3.1 Add unit tests for today's progress from completion logs, and verify they fail
- [x] 3.2 Implement the progress rule and verify 3.1 passes
- [x] 3.3 Add widget tests for Anytime today (collapse, Start), the timeline (today only, sorted, badge, Low mode), and Other days; verify they fail
- [x] 3.4 Build the three sections and the Add a routine pill, remove the tabs and moment headings, and verify 3.3 passes

## 4. Verification

- [x] 4.1 Run `flutter analyze --fatal-infos` and verify no issues
- [x] 4.2 Run `flutter test` and verify the suite passes
- [ ] 4.3 Build a debug APK with `--dart-define-from-file=dart_define.json`, install it with `adb install -r`, and compare a screenshot with the design
