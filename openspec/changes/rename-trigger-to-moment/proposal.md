## Why

The routine form's "Trigger" control reads as automation and delivers none. `TriggerKind` has exactly one value, `manual`, so nothing is ever triggered. The user's verdict was that it "has no usability, it doesn't change anything".

It does do two things, but neither is visible at the moment you use the control: it groups routines into sections on the routines list, and it supplies the leading phrase in reminder notifications, so a reminder reads "After waking up · in 10 minutes" instead of just "in 10 minutes". Both effects appear somewhere other than the screen where the choice is made, which is why the control feels inert.

The Spanish label is worse than the English one: "Disparador" names a firing mechanism, with no sense of a moment in a day.

So the problem is the name and the silence, not the feature. This renames it to what it is and tells the user what it does.

## What Changes

- Rename the user-facing term from "Trigger" to "Moment" in English, and from "Disparador" to "Momento" in Spanish, across the form label, the new-item dialog, the name field, and the routines-list section header for routines without one.
- Add a helper line under the control naming both of its effects, so its value is visible where the choice is made rather than only later.
- **Keep every identifier as-is**: `trigger_id`, `TriggerKind`, `triggersProvider` and the localization keys stay. The stored field is a required property of `schemas/routine.schema.json`, a public agent contract, and the keys stay aligned with it.

## Capabilities

### New Capabilities

- `routine-moment` — the control that assigns a routine to a named moment of the day, what it is called, and the requirement that its effects are stated where it is chosen.

## Impact

**Code.** `app/lib/l10n/app_en.arb` and `app_es.arb` (four renamed values, one new string with metadata), and `app/lib/screens/routine_form/routine_form_screen.dart` (helper line). No logic changes.

**Storage and schema.** None. No identifier, field or schema changes — only display text.

**i18n.** Four values change meaning in both locales; one string is added to both. No keys are renamed, so no call site changes.

**Rollback.** Reverting restores the previous wording. Nothing persisted is touched.
