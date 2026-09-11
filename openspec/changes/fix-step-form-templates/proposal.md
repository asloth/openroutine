## Why

The user's own words: the "Add step" templates "can't be read well", the screen has "too much
text", and the template cards "aren't organized well". Three separate defects on
`step_form_screen.dart`, plus a fourth text problem noticed along the way:

- **Templates.** `_TemplateCarousel` packs an emoji, a two-line name, and a duration into a
  116×104 card, so most names truncate. Category names sit as small grey text between cards
  instead of grouping them, so "organized" reads as "cramped".
- **Guidance text.** `stepFormCoreGuidance` and `stepFormRemindDuringGuidance` sit as loose
  paragraphs under their toggles, each wrapped in its own `Semantics` and `Column`. The remind
  guidance alone is two long sentences.
- **The name counter.** A "0/50" counter sits under the name field for a limit nobody is close to
  hitting.
- **The duration picker.** Three chips — n-1, n, and n+1 minutes — mean getting from 5 to 25
  minutes takes 20 taps.

## What Changes

- Replace the inline template carousel with a full-width "Start from a template" button, shown
  only when creating a step. It opens a bottom sheet with each category as a heading and its
  templates as a wrap of chips, at `bodyMedium` with no line limit, so every name reads in full.
- Move both guidance strings into their tile's `subtitle`, dropping the wrapping `Semantics` and
  `Column` a subtitle doesn't need. Shorten the remind-during guidance to one sentence per idea in
  both locales.
- Hide the name field's character counter with `counterText: ''`, keeping the 50-character limit.
- Replace the three-chip duration picker with ten fixed presets (1, 2, 3, 5, 10, 15, 20, 30, 45,
  60 minutes), adding the current value as an extra chip when it isn't one of the ten so an edited
  or templated duration is never silently changed.

## Capabilities

### New Capabilities

- `step-form` — how the "Add step" and "Edit step" screen presents step templates, toggle
  guidance, the name field, and the duration picker.

## Impact

**Code.** `app/lib/screens/step_form/step_form_screen.dart` (templates, guidance, counter,
duration), `app/lib/screens/shell/app_shell.dart` (doc comment referencing the old template test
file), `app/lib/l10n/app_en.arb` and `app_es.arb` (new and shortened strings). Widget tests for
the new sheet and the screen's changed behavior.

**Storage and schema.** None. No model, provider, or Drift table changes; nothing under `schemas/`
changes.

**Existing users.** None of this is stored. Editing an existing step keeps working exactly as
before — the template button is create-only, same as today.

**i18n.** Both `app_en.arb` and `app_es.arb` gain `stepFormChooseTemplate` and two template chip
label keys, and both shorten `stepFormRemindDuringGuidance`.

**Rollback.** Presentation only. Reverting restores the carousel, the loose guidance paragraphs,
the visible counter, and the three-chip duration picker, with nothing to unwind in storage.
