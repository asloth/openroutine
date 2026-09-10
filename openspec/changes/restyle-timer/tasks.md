## 1. Ground and progress

- [x] 1.1 Update `timer_screen_test.dart`: the running screen's `Scaffold` reads
      `context.routineCardColors.timerGround`; a `SegmentedProgress` with the right `count`/
      `filled`/semantics label is present and no `LinearProgressIndicator` is present; watch these
      fail
- [x] 1.2 Set the `Scaffold`'s `backgroundColor` to `context.routineCardColors.timerGround` in
      `timer_screen.dart`; replace the `LinearProgressIndicator` with `SegmentedProgress`; verify
      1.1 passes

## 2. Circular controls

- [x] 2.1 Update `timer_screen_test.dart`: the close, pause/resume, and restart controls are
      `SoftCircleButton`s (48px neutral for close, 64px accent for the other two), keeping their
      existing tooltips/icons/actions; watch it fail
- [x] 2.2 Replace the close `IconButton` and `_CircleAction`'s `NeumorphicCircleButton` with
      `SoftCircleButton`; verify 2.1 passes

## 3. Do later

- [x] 3.1 Update `timer_screen_test.dart` to assert "Do later"'s label color is `onSurface`; watch
      it fail
- [x] 3.2 Set `TextButton.styleFrom(foregroundColor: colorScheme.onSurface)` on the "Do later"
      button; verify 3.1 passes

## 4. Text scale

- [x] 4.1 Add widget tests at 1.5x and 2.0x text scale (`tester.platformDispatcher
      .textScaleFactorTestValue`, cleared after each test) covering the running screen with no
      overflow errors

## 5. Verification

- [x] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes
      (490 pass)
- [x] 5.3 Format only the touched files with
      `/home/sabera/fvm/bin/fvm dart format $(git diff --name-only --diff-filter=ACM | grep '\.dart$')`
- [x] 5.4 Run `openspec validate restyle-timer --type change --strict` and verify it passes
