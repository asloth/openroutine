## Context

See `proposal.md` — Why. `add-tinted-surfaces` landed the widget set this change
consumes (`TintedCard`, `PageHeader`, `SectionLabel`, `SegmentedProgress`) and the two
tokens it needs (`AppTypography.pageTitle`/`sectionLabel`, `AppRadius.hero`). This
screen's own data model, `RoutineStatistics` and its aggregation service, isn't touched:
every figure the screen shows today still comes from the same four fields.

This screen is a bottom-nav destination root. A separate, parallel change is replacing
`AppShell`'s `NavigationBar` with a floating pill on `Scaffold.extendBody`, which puts
the pill's height into the body's `MediaQuery.padding.bottom`. This change reserves that
space at the bottom of the list without depending on the pill change landing first —
`MediaQuery.paddingOf(context).bottom` is 0 today and becomes the pill's height once that
change lands, either way the list clears whatever sits below it.

## Goals / Non-Goals

**Goals:**

- Match the approved "tinted paper" mockup: a hero finishing card, and the other three
  sections laid flat with dividers instead of boxed in neumorphic cards.
- Keep the section order and every figure identical to today — this is a restyle, not a
  rework of what's reported.
- Keep the hero screen-reader-friendly as one sentence, not a sequence of fragments a
  screen reader would otherwise read as "sixty-four... of twelve runs finished... four
  days in a row" with no connecting grammar.

**Non-Goals:**

- Changing `RoutineStatistics`, the aggregation service, or the provider. This is a
  presentation-layer change over the same data.
- The floating nav pill itself. That's a separate, parallel change; this one only
  reserves the bottom padding it will need.
- Per-routine filtering, charts, or any new statistic. Out of scope here as it was in
  `add-statistics-screen`.

## Decisions

### The completion-rate section becomes the hero, not an equal fourth card

*Rationale:* the approved mockup makes finishing the visually dominant figure, and it's
the number the rest of the screen exists to contextualize — the estimate, skip, and
timing sections are ways of explaining *why* the finishing rate looks the way it does.
Rendering all four as equal-weight cards buried that relationship; a hero card states it.

### The hero carries one semantics label, not one per line

*Rationale:* `TintedCard`'s content is a title, a number, a phrase, and a progress bar —
read individually by a screen reader, that's four disconnected announcements with no
grammar tying them together ("64", "of 80 runs finished", "4 days in a row",
"progress bar"). Wrapping the whole card in one `Semantics(label: ...)` node, built from
the existing `statsCompletionRate` sentence plus the streak sentence, gives one complete
thought instead. The visible text underneath still needs `ExcludeSemantics` so it isn't
announced a second time as fragments.

### `statsCompletionRate` stays; two new strings split its visible rendering

*Rationale:* the mockup shows the finished count as its own large figure and "of N runs
finished" as a smaller trailing phrase — two visual weights sharing one grammatical
sentence. Splitting `statsCompletionRate` itself would break every existing consumer of
that string (there are none outside this screen today, but the string is also the
building block for the hero's semantics label, where the full sentence is exactly what's
wanted). Keeping it and adding two purpose-built strings for the split visible rendering
avoids stitching a sentence back together from two independently-pluralized fragments.

### The three flat sections read the divider from `outlineVariant`, not a card boundary

*Rationale:* `TintedCard` requires a fill and reads as a bounded surface; laying rows
directly on the page with `outlineVariant` dividers between them (never after the last
row) is what "flat on the page" means in the mockup, and matches how `SectionLabel` is
documented — a caption over a group, not over a card.

## Risks / Trade-offs

**Two visual weights for the same statistic (hero number vs. flat rows) is more layout
than one card style.** Accepted: it's what the approved mockup asks for, and it's also
the reason finishing gets legible priority over the other three sections instead of
looking incidental.

**`MediaQuery.paddingOf(context).bottom` is 0 until the nav-pill change lands, so the
extra list padding is inert for now.** Acceptable and deliberate — the two changes are
independent and unordered relative to each other; this one shouldn't block on, or assume
anything about, the other's landing order.

## Migration Plan

None. No persisted data or schema involved; this is a visual change to one screen.
