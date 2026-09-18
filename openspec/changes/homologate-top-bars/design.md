## Context

See `proposal.md` — Why. Routine detail, timer, and home each hand-roll their own back row with
`SoftCircleButton`; they don't use `AppBar` at all. The four screens this change touches still do,
because moving them off `AppBar` entirely — matching routine detail's approach — is a bigger,
separate piece of work than homologating the one control that's visibly wrong. This change fixes
the back arrow and the delete menu without touching anything else about how these screens use
`AppBar`.

## Goals / Non-Goals

**Goals:**

- Make every back control on every screen the same widget.
- Make routine detail's delete control cost one tap, not two, since it's the only thing that ever
  shows up in the menu it used to live behind.

**Non-Goals:**

- Moving routine form, step form, settings, or import off `AppBar` onto a hand-rolled header row.
  That's routine detail's pattern, not yet a rule for every screen.
- Touching the step form's own save/delete actions, or any screen's title, body, or layout beyond
  the leading slot.
- Timer, home, or anything already on `SoftCircleButton`.

## Decisions

### `SoftBackButton` is a thin wrapper, not a new visual idiom

It renders exactly what routine detail already draws by hand: `SoftCircleButton(icon:
Icons.chevron_left, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: ...)`.
Default `onPressed` is `Navigator.maybePop`, the same call the stock back button makes and the one
go_router already knows how to honor.

*Alternative considered:* a generic "AppBar leading" widget that also handles close (`X`) buttons
or other leading icons. Rejected — every screen in this change wants a back arrow, and a name that
says so is clearer than a name that says "whatever the leading slot needs."

### The 16px inset lives in a static helper, not copied into four screens

`SoftBackButton.asAppBarLeading()` returns the button wrapped in `Align(centerLeft)` and
`Padding(left: 16)`; `SoftBackButton.appBarLeadingWidth` (64 = 48 + 16) pairs with it as the
`AppBar`'s `leadingWidth`.

*Rationale:* ten `AppBar`s across four files need the identical placement. Writing the
`Align`/`Padding` pair by hand at each site risks one of them drifting by a pixel; a named pair of
constants can't.

*Alternative considered:* wrapping the padding into `SoftBackButton` itself, so plain
`SoftBackButton()` is already inset. Rejected — the button is a general-purpose circular control,
and baking in an `AppBar`-specific inset would make it wrong the one time it's used somewhere else.

### Routine detail's delete keeps its own confirm flow verbatim

`_confirmDelete` → `deleteRoutine` → `ref.invalidate(routinesProvider)` → `context.pop()` moves
from the `PopupMenuButton`'s `onSelected` to the `SoftCircleButton`'s `onPressed` unchanged. Share
and edit don't move.

*Alternative considered:* asking whether a lone delete control needs its own confirm dialog at all,
now that there's no menu step in front of it. Out of scope — the confirm dialog's job is guarding
against an accidental tap on an irreversible action, which is exactly as true with one tap as with
two.

## Risks / Trade-offs

**A `SoftCircleButton` reads as more prominent than a menu ever did.** → Intended. Delete was the
only thing behind that menu, so hiding it behind an extra tap was never protecting against
anything except finding it. The confirm dialog is still the real guard.

**Four screens keep `AppBar` while three don't.** → Accepted for this change; see Non-Goals. It's
an inconsistency this change doesn't fully close, but closing it means redesigning four screens'
headers, not fixing a mismatched icon.

## Migration Plan

None. Presentation only, nothing persisted changes shape.
