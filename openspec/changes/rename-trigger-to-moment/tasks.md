## 1. English wording

- [x] 1.1 Rename the four `app_en.arb` values to the moment wording — form label, new-item dialog title, name field, and the no-moment section header — leaving every key unchanged
- [x] 1.2 Update each renamed string's `@description` to record that the user-facing term is "Moment" while the stored field is `trigger_id`, so the key/value mismatch is explained rather than discovered
- [x] 1.3 Add a `routineFormMomentHelper` string naming both effects, with metadata

## 2. Spanish wording

- [x] 2.1 Rename the same four values in `app_es.arb` from "Disparador" to "Momento" wording, matching gender and article agreement
- [x] 2.2 Add the Spanish `routineFormMomentHelper`, and verify both locales define the same set of keys by running `flutter gen-l10n` and confirming it reports no untranslated messages

## 3. Helper line

- [x] 3.1 Render the helper string beneath the control in `routine_form_screen.dart`, styled as muted supporting text rather than as a field label
- [x] 3.2 Add a widget test asserting the helper text is visible on the routine form, and verify it passes

## 4. Verification

- [x] 4.1 Verify no identifier changed by confirming `trigger_id`, `TriggerKind` and `triggersProvider` are untouched, and that `schemas/routine.schema.json` is unmodified
- [x] 4.2 Add a widget test asserting the form's control is labelled with the moment wording and not the old term, and verify it passes
- [x] 4.3 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 4.4 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or above the 268 baseline
- [x] 4.5 Run `openspec validate rename-trigger-to-moment --type change --strict` and verify it passes
