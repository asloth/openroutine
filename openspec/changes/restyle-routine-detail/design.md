## Context

See `proposal.md` — Why. `add-tinted-surfaces` (merge `399bc94`) shipped `TintedCard` and
`SoftCircleButton` under `app/lib/widgets/tinted/`; `add-accent-color` shipped
`context.routineCardColors` on `app/lib/theme/theme.dart`. Both are read-only dependencies here —
this change touches neither file, and reports anything either widget is missing rather than editing
it locally.

## Goals / Non-Goals

**Goals:**

- Move the routine detail screen onto the tinted-paper idiom without moving, removing, or regrouping
  a single control. Every tap target a user already knows keeps its place.
- Read every accent-colored surface (the moment chip, the summary card, the history dots) from
  `context.routineCardColors`, so the screen tracks whichever accent the user has picked instead of
  a hard-coded role.
- Keep the reorder, empty-state, and single-step behaviors byte-for-byte what they are today —
  those are already covered by a passing test suite, and a restyle changing any of them would be a
  regression, not an improvement.

**Non-Goals:**

- Touching `app/lib/widgets/tinted/*` or `app/lib/theme/theme.dart`. If either is missing something
  this screen needs, the gap is worked around locally and reported, not patched upstream from this
  change.
- Any new user-facing string. Every label this screen shows already has an `app_en.arb` /
  `app_es.arb` key.
- Reordering, removing, or adding a control. The Back/Share/Edit/More row is the same four actions
  in the same order; Start Timer, Add step, and the step list keep every existing rule.

## Decisions

### The top row is a plain `Row`, not `PageHeader`

`PageHeader` fits the 48px-row, leading/actions-8px-apart shape closely, but its `title` slot
front-loads a title on the same row the actions sit on. This screen's title (the routine name) sits
on its own row 24px below, in a larger size than `PageHeader` renders — the brief calls for
`AppTypography.pageTitle` on the *name* row, not the header row. Reusing `PageHeader` with `title:
null` would work today, but it's spec'd to grow a second line at 2.0x text scale, which this row
never needs to do since it carries no title. A plain `Row` with the same 8px action spacing avoids
inheriting that behavior for a slot this screen doesn't use, while still matching every dimension
the brief specifies.

### The "More" trigger is a local widget, not `SoftCircleButton`

`SoftCircleButton` takes an `onPressed` callback, not a menu. Wiring `PopupMenuButton`'s existing
`Delete` flow to a control that looks identical means giving `PopupMenuButton` a custom `child`: a
48px `Material` circle in `colorScheme.surfaceContainer`, clipped to its own shape, holding a
horizontal "more" icon. This keeps `PopupMenuButton`'s own tooltip, `itemBuilder`, and `onSelected`
— and therefore the delete confirmation dialog — completely unchanged; only the trigger's paint
changes.

### History dots read `onFill`, not a fixed accent role

Today's dots hard-code `colorScheme.primary` for "completed" and "attempted." That was already
correct before `add-accent-color` landed, because `primary` doubled as the accent. Now that
routine-card color has its own name, the dots move to `context.routineCardColors.onFill` — the same
color the card's filled elements already use — so they stay visually attached to the card they sit
inside rather than to whatever `primary` happens to render elsewhere on the screen (button labels,
for instance, which is a legitimately different question).

### One step container replaces one card per step

The brief calls for a single bordered, clipped container around all the step rows, with a divider
between them and none after the last — closer to a stock `ListView.separated` in appearance than to
today's stack of individually shadowed cards. The existing `ReorderableListView`,
`buildDefaultDragHandles: false`, the transparent `proxyDecorator`, and the saving-order lock all
stay; only the per-row surface (a `Container` with a bottom border, cleared on the last index) and
the outer clip (`ClipRRect` at `AppRadius.hero`) change. The single-step and empty-list branches
keep rendering outside any list at all, matching today's behavior of never wiring up a
`ReorderableListView` unless there's something to reorder.

## Risks / Trade-offs

**A local "more" trigger duplicates a few lines of `SoftCircleButton`'s look rather than reusing
it.** Accepted — see Decisions. Extending `SoftCircleButton` itself to accept a menu-building slot
would be a shared-widget change, which this change's brief explicitly keeps out of scope.

**Divider suppression on the last row is easy to get backwards.** Mitigated with a test asserting
the row count of dividers is exactly `steps.length - 1`, not `steps.length`.

## Migration Plan

None. This is a visual and structural change to one screen's `build` method; no persisted state,
route, or public API changes shape.
