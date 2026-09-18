## Context

See `proposal.md` — Why. `_buildDay` in `routines_list_screen.dart` already builds two lists from the
same gathered `items`: `anytime` (flexible routines) and `today` (scheduled routines due today, via
the static `_dueToday` helper). Only `today` was ever filtered by day. `Timeline` already lays its
cards on a rail — a fixed 56px time column, a 14px gap, an 8px column holding a 1px line and a dot,
another 14px gap, then the card — built inline inside `_TimelineRow`. `AnytimeSection` lays its rows
in a plain `SliverList.separated` of bordered `HomeRoutineRow`s, with no rail at all.

## Goals / Non-Goals

**Goals:**

- Make a flexible routine's days mean the same thing a scheduled routine's days already mean: shown
  on the days it's scheduled for, not shown otherwise.
- Don't let a flexible routine that predates the days field, or one still catching up from a Drive
  sync or a local migration, disappear from Today.
- Make Anytime and the timeline read as one list, without changing what either section's cards look
  like on their own, and without touching the Routines tab.

**Non-Goals:**

- Changing what a flexible routine's card shows, or `HomeRoutineRow`'s own appearance. That widget is
  shared with the Routines tab, which nobody asked to change.
- Changing how days are chosen or stored. A separate change gives the routine form a day picker for
  flexible routines; this one only makes Today honor the result.
- Reworking the timeline's own layout. The rail is extracted, not redesigned.

## Decisions

### The anytime filter adds one clause, not a rewrite

`anytime` keeps its existing `mode == ScheduleMode.flexible` check and adds
`(schedule.days.isEmpty || _dueToday(routine, now))`, reusing the same `_dueToday` the timeline
already relies on rather than writing a second day-matching rule.

*Alternative considered:* treating empty days as "never," matching a scheduled routine with no days
(which, under `_dueToday`, would never show). Rejected: a scheduled routine with no days is a data
error — the form requires at least one day. A flexible routine with no days is either a deliberate
choice made before the form supported days at all, or a routine still waiting on a migration or a
Drive pull from another device that hasn't run yet. Dropping it off Today on the strength of an
absence the user never asked for would trade one silent bug for another.

### The rail is extracted from `_TimelineRow`, not rebuilt from scratch

The new `HomeRail` widget in `timeline.dart` is the same `Row` `_TimelineRow` already built — the
56px time column, the 14px gaps, the 8px line-and-dot column, the padded child — with the time slot
made optional. `_TimelineRow` becomes a thin wrapper that passes its `_StartTime` and `_TimelineCard`
into it. `AnytimeSection` wraps each `HomeRoutineRow` in the same `HomeRail`, passing no time, so that
56px column stays empty instead of collapsing — which is what keeps the dot underneath the timeline's
dot rather than sliding left.

*Alternative considered:* giving `AnytimeSection` its own line-and-dot widget, matched by hand to the
timeline's measurements. Rejected: two copies of the same 56/14/8/14 layout is exactly how the two
sections drifted into looking unrelated in the first place. One widget, shared, is the only way a
future change to the rail's spacing stays a single edit.

### Alignment comes from matching the timeline's outer padding, not the rail itself

The timeline gets its left inset from the `SliverPadding` that wraps it in
`routines_list_screen.dart` (`_gutter - 8`, i.e. 14px), not from anything inside `timeline.dart`.
`AnytimeSection`'s own `SliverPadding` — previously a symmetric 22px, independent of the timeline's
inset — now uses the same 14px on the left so the shared rail lands at the same x in both sections.
The right edge stays at 22px in both, matching the existing card widths.

*Alternative considered:* changing `HomeRail`'s internal widths so it can sit under either padding
and still align. Rejected: the two sections would still be passing different outer padding into an
identical inner layout for no reason, which is a harder invariant to keep than just giving them the
same padding.

## Risks / Trade-offs

**`HomeRoutineRow` still draws its own leading dot, inside the card, in addition to the rail's dot
outside it.** → True, and left as is. The task is explicit that `HomeRoutineRow` isn't to be
restyled — it's the same widget the Routines tab renders — so the rail wraps around it rather than
replacing anything inside it. The two dots sit at different places (one on the spine, one beside the
routine name) and read as different things: a stop marker and a bullet.

**The empty-days fallback means a flexible routine that truly has no schedule shows on every day,
same as before this change.** → Intended. The alternative — hiding it — is the regression the user
is reporting from the other direction. The fallback is a deliberate compatibility shim, not a
long-term behavior; once the days-picker change ships and every flexible routine has been through the
form at least once, empty days should become rare.

## Migration Plan

None. No stored shape changes. Existing flexible routines with no `days` keep showing on Today, same
as they do now; routines that do have `days` start respecting them.
