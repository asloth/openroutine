## Why

The step form is the last form still drawn with stock Material parts: a labelled text field, a row of `ChoiceChip`s, a checkbox, and a checkmark hiding in the app bar. The routine form next to it already moved to the redesign's look — a display-size name with only a rule under it, tinted controls, and one full-width button at the bottom. Opening a step from that form drops you into a screen that looks like another app.

## What Changes

- The name becomes a display-size field with the hint "What's the step?", next to the existing emoji circle.
- Duration moves into a **How long** section: a five-column grid of minute tiles, a "No set time" toggle on the right of the heading, and a "minutes" caption under the grid.
- "Remind me during this step" and "Essential for Low Mode" share one card, and both are switches. Essential was a checkbox.
- Save moves from the app bar to a full-width button at the bottom. It reads "Name it first" and stays disabled until the step has a name. Delete stays in the app bar when editing.
- The "Start from a template" button and its sheet don't change.

## Capabilities

### Modified Capabilities

- `step-form` — layout and controls only. What the form stores is unchanged.

## Impact

**Code.** `app/lib/screens/step_form/step_form_screen.dart` and its tests.

**Storage and schema.** None. No file under `schemas/` changes.

**i18n.** New keys `stepFormNameHint`, `stepFormHowLong`, `stepFormMinutesCaption`, and `stepFormNameFirst` in both ARB files. `stepFormNoExplicitTime` now reads "No set time".

**Rollback.** Revert the commit. Nothing is persisted differently.
