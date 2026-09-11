## Context

See `proposal.md` — Why. All four defects live in one file,
`app/lib/screens/step_form/step_form_screen.dart`, and none of them touch storage: the step model,
the Drift schema, and `assets/step_templates.json` are all unchanged. This is a presentation-only
fix, delivered as one spec with three implementation slices (templates, then guidance/counter/
duration) to keep each review under the 400-line budget.

## Goals / Non-Goals

**Goals:**

- Make every template name readable in full, at any text scale, without shrinking or reorganizing
  the rest of the form.
- Keep the templates a fast path, not a chore: one tap to open, one tap to apply.
- Cut the guidance text's ceremony without cutting its meaning — a subtitle already reaches screen
  readers through its tile, so the extra `Semantics` wrapper was doing nothing a sighted user
  couldn't already see and a screen reader user didn't already hear twice.
- Make common durations reachable in one tap instead of a walk of taps from wherever the step
  starts.

**Non-Goals:**

- Changing what a template contains, how many templates exist, or `assets/step_templates.json`'s
  shape.
- Changing the toggle order, the emoji picker, or the save/delete actions.
- A general text-scale audit of the rest of the screen.

## Decisions

### Templates move to a bottom sheet, not a taller inline section

A `showModalBottomSheet` with `showDragHandle: true` and `isScrollControlled: true`, wrapping a
`DraggableScrollableSheet` — the same shape the emoji picker on this screen already uses.

*Alternative considered:* keep templates inline but stack categories vertically instead of scrolling
horizontally. Rejected: `_TemplateCarousel`'s own doc comment records why it went horizontal in the
first place — a full vertical wrap of every category pushed the name field below the fold on a
phone screen. A sheet gets the same vertical room the carousel was avoiding, without spending it
against the form that's visible by default. The trigger button costs one row; the sheet costs
nothing until someone opens it.

### Chips read as one line of text, not a card

Each chip's label is a single ARB string —
`"{emoji} {name} · {duration}"` — matching `reminderBodyWithTrigger`'s existing pattern of
composing two localized fragments with a fixed separator. A template with no duration uses a
second key with no duration placeholder, rather than making `duration` an optional segment inside
one message: an empty placeholder still leaves the separator dangling, and past-tense conditionals
inside ICU messages read worse than two keys.

*Alternative considered:* keep the emoji as its own `Text` beside the label, mirroring the old
card's layout. Rejected: a `Wrap` of chips lays out left-to-right by chip, not by internal widget,
so splitting the emoji out gains no readability and costs an extra widget per chip for no benefit.

### The guidance strings move into `subtitle`, not into a shared helper

`CheckboxListTile.subtitle` and `SwitchListTile.subtitle` take the guidance text directly. No new
widget wraps them.

*Rationale:* the `Semantics(label:)` + `Column` pairing existed because a bare `Text` sibling
doesn't get read as part of the checkbox or switch's accessible description. A tile's `subtitle`
solves the same problem natively — `CheckboxListTile` and `SwitchListTile` already merge title and
subtitle into one semantic node — so the wrapper was working around a gap these tiles don't have.

### Duration keeps `ChoiceChip`, trading relative presets for fixed ones

The ten fixed values (1, 2, 3, 5, 10, 15, 20, 30, 45, 60 minutes) replace `{n-1, n, n+1}`. When the
current `_minutes` isn't one of the ten, it's added as an eleventh chip in sorted position, so a
7-minute step someone is editing, or a template that seeded a 7-minute value, keeps 7 selected
rather than snapping to the nearest preset.

*Alternative considered:* a slider. Rejected: a slider trades precise, glanceable values for a
continuous range that's harder to hit exactly and harder to make accessible, for a form where the
whole point is picking a specific number of minutes.

## Risks / Trade-offs

**A sheet is one more tap than an already-visible carousel.** → True, and worth stating: the
carousel was zero taps to see, one tap to apply. The sheet is one tap to see, one tap to apply.
The trade is legibility for that first tap, which is the entire complaint this change responds to.

**Ten preset chips plus a possible eleventh is more chips than three.** → Intended. `Wrap` lets
them flow across as many lines as they need, and picking a value in one tap beats stepping to it
one minute at a time.

## Migration Plan

None. Presentation only, nothing persisted changes shape, and no existing step's stored duration or
template origin changes meaning.
