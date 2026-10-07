## 1. Center the finished screen

- [x] 1.1 Add a widget test that finishes a run on a phone-sized surface and asserts the content's
      vertical center is within 24px of the screen's, and verify it fails
- [x] 1.2 Replace the summary's `ListView` with a centered `Column` in a `SingleChildScrollView`,
      and verify 1.1 passes

## 2. Throw a small party

- [x] 2.1 Add widget tests: a finished run shows `ConfettiBurst` and still settles, a stopped run
      shows none, and reduced motion shows none; verify the first fails
- [x] 2.2 Add `app/lib/widgets/confetti_burst.dart` and wrap the finished mascot in it, and verify
      2.1 passes

## 3. Verification

- [x] 3.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 3.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
- [ ] 3.3 Finish a routine on the Pixel 9a and check the confetti by eye
