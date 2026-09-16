## 1. Navigation

- [x] 1.1 Add nav bar tests for three destinations fitting a 360dp phone at 1.6x and 2.0x, with Spanish and deliberately long labels, and verify they fail
- [x] 1.2 Let the pill cap its width and shrink its destinations, and verify 1.1 passes
- [x] 1.3 Update the shell tests for Today, Routines, and Streaks in order, and add the three-branch shell

## 2. Routines screen

- [x] 2.1 Add widget tests for the order, opening a routine, Add a routine, and the empty state, and verify they fail
- [x] 2.2 Build the screen and verify 2.1 passes
- [x] 2.3 Check Add a routine clears the pill on both Today and Routines

## 3. Home

- [x] 3.1 Replace the Other days test with one asserting routines not due today stay off home, and remove the fold

## 4. Verification

- [x] 4.1 Run `flutter analyze --fatal-infos` and verify no issues
- [x] 4.2 Run `flutter test` and verify the suite passes
