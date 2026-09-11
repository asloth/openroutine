## 1. Spec

- [x] 1.1 Write `proposal.md`, `design.md`, and `specs/step-form/spec.md`
- [x] 1.2 Validate with `openspec validate fix-step-form-templates --type change --strict`

## 2. Templates in a sheet

- [x] 2.1 Add `stepFormChooseTemplate`, `stepFormTemplateChipLabel`, and
      `stepFormTemplateChipLabelNoDuration` to both ARB files and run `flutter gen-l10n`
- [x] 2.2 Write `step_template_sheet_test.dart` covering: every template name shows in full with no
      ellipsis at the default text scale and at 1.5x; picking a template fills the name and emoji
      and closes the sheet; the entry point doesn't exist when editing — and watch it fail
- [x] 2.3 Replace `_TemplateCarousel`/`_TemplateCard` with the "Start from a template" button and
      the bottom sheet, and verify 2.2 passes
- [x] 2.4 Update `app_shell.dart`'s doc comment to point at `step_template_sheet_test.dart`

## 3. Guidance, counter, and duration

- [x] 3.1 Shorten `stepFormRemindDuringGuidance` in both ARB files and run `flutter gen-l10n`,
      keeping `remind_during_strings_test.dart` green
- [x] 3.2 Add failing assertions to `step_form_screen_test.dart` for a 7-minute step showing a
      selected 7-minute chip, the ten presets rendering, and the counter being hidden
- [x] 3.3 Move both guidance strings into their tile's `subtitle`, hide the name counter with
      `counterText: ''`, and replace the duration chips with the ten fixed presets plus the
      current value when it isn't one of them; verify 3.2 passes and every existing test in the
      file stays green

## 4. Verification

- [x] 4.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 4.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes
- [x] 4.3 Run `openspec validate fix-step-form-templates --type change --strict` and verify it
      passes
