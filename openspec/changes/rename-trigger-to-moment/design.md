## Context

See `proposal.md` — Why. The control is a dropdown plus an add button on the routine form; its effects are a section heading on the routines list and a prefix in reminder copy.

## Goals / Non-Goals

**Goals:**

- Make the name honest in both locales.
- Make the control's value visible at the point of choice rather than only in its consequences.

**Non-Goals:**

- Renaming identifiers, database columns, providers or localization keys.
- Changing what a moment does. Grouping and reminder copy are unchanged.

## Decisions

### Display text changes; identifiers do not

Only the four `.arb` values and one new string change. `trigger_id`, `TriggerKind`, `triggersProvider` and every localization key stay.

*Rationale:* `trigger_id` is a required property of `schemas/routine.schema.json`, which the project treats as a public agent contract, so it cannot move. With the stored name fixed, keeping the code and the keys aligned to it is more maintainable than having identifiers say "moment" while the persisted contract says "trigger" — a mismatch every future reader would have to re-derive. The `@description` metadata carries the mapping so a translator is not confused by a key that disagrees with its value.

*Alternative considered:* renaming keys and identifiers to match the new term. Rejected as churn that would leave code disagreeing with the schema it serialises to.

### "Moment", not "Group" or "Context"

*Rationale:* the existing code comment already describes it as "the human name for the moment the routine belongs to", and reminder copy places it as a time reference — "After waking up · in 10 minutes". "Group" describes the list-grouping effect but not the notification one; "Moment" covers both, and matches how the values are actually written.

Spanish takes "Momento" for the same reason, and because "Disparador" carries a firing connotation the English never had.

### A helper line, not a tooltip

*Rationale:* the complaint was that the control appears to do nothing. A tooltip hides the answer behind a second interaction, which is the same failure in a smaller form. The line is always visible, states both effects, and stops being needed once the user has seen it once — at which point it is one short line of muted text.

## Risks / Trade-offs

**"Moment" is unusual UI vocabulary.** → Accepted. It is more accurate than "Trigger" and less generic than "Group", and the helper line removes any ambiguity about what it does.

**The key/value mismatch could confuse a future reader.** → Mitigated by `@description` metadata on each renamed string that records the mapping to `trigger_id` explicitly.

## Migration Plan

None. Display text only.
