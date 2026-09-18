## 1. SoftBackButton

- [x] 1.1 Add `test/widgets/tinted/soft_back_button_test.dart` asserting it renders a
  `SoftCircleButton` with `Icons.chevron_left`, exposes the platform back tooltip, pops by default,
  and runs a custom `onPressed` instead of popping when one is given; verify it fails because the
  widget doesn't exist
- [x] 1.2 Add `lib/widgets/tinted/soft_back_button.dart` with `SoftBackButton`, its
  `asAppBarLeading()` static helper, and `appBarLeadingWidth`; export it from
  `lib/widgets/tinted/tinted.dart`; verify 1.1 passes

## 2. Homologate the four AppBar screens

- [x] 2.1 Add a test to each of `routine_form_screen_test.dart`, `step_form_screen_test.dart`,
  `settings_screen_test.dart`, and `import_screen_test.dart` asserting the app bar's leading is a
  `SoftBackButton` and neither `Icons.arrow_back` nor `Icons.arrow_back_ios` appears; the routine
  form test additionally pins the button 16px from the left edge and vertically centered in the
  bar; verify each fails against the stock `AppBar`
- [x] 2.2 Set `leading: SoftBackButton.asAppBarLeading()` and
  `leadingWidth: SoftBackButton.appBarLeadingWidth` on every `AppBar` in
  `routine_form_screen.dart` and `step_form_screen.dart`, including each screen's loading, error,
  and unavailable-state bars, and on the single `AppBar` in `settings_screen.dart` and
  `import_screen.dart`; verify 2.1 passes and the step form's save/delete actions are unchanged

## 3. Routine detail's delete control

- [x] 3.1 Update `routine_detail_screen_test.dart`'s two menu tests to tap
  `Icons.delete_outline` directly instead of opening `Icons.more_horiz` first, and assert
  `Icons.more_horiz` is absent; extend the tooltip test to also assert `commonDelete`'s tooltip;
  verify they fail against the `PopupMenuButton`
- [x] 3.2 Replace the `PopupMenuButton<_MenuAction>` in `routine_detail_screen.dart` with
  `SoftCircleButton(icon: Icons.delete_outline, tooltip: l10n.commonDelete, onPressed: ...)`
  running the same confirm-then-delete flow, and remove the now-unused `_MenuAction` enum; verify
  3.1 passes and `app_shell_test.dart`'s "no overflow menu" assertion still passes

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
  issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
  above the 593 baseline
