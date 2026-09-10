## Context

See `proposal.md` — Why. The router in `app/lib/main.dart` is a flat list of eleven `GoRoute`s with `/routines` as the initial location; every other screen is pushed onto it. `RoutinesListScreen` owns the only `AppBar` with actions, and its `PopupMenuButton` is the sole entry point to `/import` and `/stats`, and one of the entry points to `/settings`.

`StatsScreen` and `ImportScreen` each build their own `AppBar` with an automatic back button, which is correct for a pushed page and wrong for a destination root.

## Goals / Non-Goals

**Goals:**

- Make Stats visible without opening anything.
- Separate destinations from actions, and place each accordingly.
- Preserve each destination's state across switches, including the routine list's scroll offset and its selected Scheduled/Flexible tab.
- Keep every existing deep link working — notification taps and the home screen widget both route into `/routines/<id>` paths.

**Non-Goals:**

- Restyling the routine list, the stats screen, or settings. The bar is new; nothing inside the screens moves. Per `CLAUDE.md`, controls that weren't part of this request stay where they are.
- Promoting Import to a destination. It is an action, and the point of this change is to stop treating it as a place.
- Shedding the Material 3 look. That's the Stitch redesign, and doing it here would bury a navigation change inside a visual one.

## Decisions

### Two destinations, not three

The bottom bar carries Routines and Stats. Settings goes to a gear icon in the app bar.

*Rationale:* a bottom bar earns its space by making frequent destinations reachable. Routines is the app; Stats is what this change is for. Settings is visited rarely and would spend a permanent third of the bar on something touched once a month.

*Alternative considered:* three destinations including Settings. Rejected on two grounds. The gear is a stronger convention for settings than a labelled tab, and — concretely — three labels have to fit at large text scales. The step template cards were sliced through the middle of their letters for exactly this reason, on a device whose text scale is well above default. Two labels have room to grow; three are already tight.

*Cost, stated plainly:* navigation now lives at two edges of the screen. Destinations are at the bottom, settings at the top. That is a real inconsistency, accepted because the gear is where users already look for settings and because it protects the bar from crowding.

### `StatefulShellRoute.indexedStack`, not a `TabBar` or manual index

*Rationale:* it is go_router's own mechanism for exactly this, and it gives each branch an independent `Navigator`. Keeping the state means keeping the whole subtree alive, which `indexedStack` does by construction — no `AutomaticKeepAlive`, no manual scroll controllers, no remembering to restore the tab index.

*Alternative considered:* a single `Scaffold` with an index and a `body` switch. Rejected: it discards each screen's navigation stack on every switch, so pushing into a routine, switching to Stats and switching back would land on the list rather than the routine. The `indexedStack` variant keeps the branch's whole stack.

### `/settings` and `/import` stay outside the shell

Both are pushed over the bar rather than being branches of it.

*Rationale:* a pushed route covers the bottom bar, which is the correct signal for a screen you finish and leave. It also means neither route changes shape, so nothing that links to them needs to know the shell exists.

### Import moves next to Export, not into a menu of its own

The Data section in Settings already holds `Export all`. Import goes directly above it.

*Rationale:* they are one idea in two directions, and a user looking for one will look where the other is. This is the only control this change relocates, and it moves toward its pair rather than away from it.

### Stats and Import lose their back buttons only where it's wrong to have one

`StatsScreen` becomes a destination root, so its `AppBar` must not draw an automatic back button — there is nothing to go back to. `ImportScreen` stays pushed and keeps its back button.

## Risks / Trade-offs

**Navigation splits across two screen edges.** → Stated above as an accepted cost of the chosen shape. The gear sits in the exact corner the overflow menu occupied, so the muscle memory that mattered is preserved even as the icon changes.

**Import becomes harder to find before it becomes easier.** → It moves from a menu nobody browses into a section named Data next to its own opposite. Someone who knew the old location has one place to re-learn; someone who didn't is more likely to stumble on it now. The label itself doesn't change, so search-by-eye still works.

**A shell route is a structural change to the router, and the router is what the widget tap and notification tap both depend on.** → Both route to `/routines/<id>` and `/routines/<id>/timer`, which stay ordinary pushed routes. The recently fixed `overridePlatformDefaultLocation` behaviour is a property of the `GoRouter` itself and is unaffected by branch structure. Tasks cover both paths explicitly rather than assuming.

**`indexedStack` builds both branches up front**, so the stats queries run on first launch rather than on first visit. → Accepted. The queries are local drift reads over completion logs, already fast enough to render synchronously on the device, and the alternative costs the state preservation this change is for.

## Migration Plan

None. Presentation and routing only; nothing persisted changes shape. A user's first launch after the update shows the bar without any prompt or migration step.
