## Context

The routine form (`routine_form_screen.dart`) already sets the pattern: a display-font name field with an underline, `HomeInk` colours, a hairline card, and `_SaveButton` in `bottomNavigationBar`. The step form copies that pattern so the two screens read as one flow.

## Decisions

**Keep the emoji circle.** The mockup has no emoji control, but every step needs one and `_save` enforces it. The circle stays to the left of the name.

**Save is disabled until there's a name.** The label says why ("Name it first") rather than letting you tap and see a validation error. The emoji check stays a snackbar, since templates and the circle both fill it.

**Selected tiles use the accent.** The mockup paints the selected tile near-black. The app takes every selected state from `HomeInk.accent`, the same as the routine form's day toggles.

**"No set time" hides the grid.** That's today's behaviour: the duration and the reminder disappear together, because a reminder halfway through no estimate isn't a moment.

**An odd stored duration gets its own tile.** A step stored at 7 minutes still shows a selected 7 tile, so opening the form never snaps it to a preset.

## Risks

The bottom button adds a fixed band at the bottom. The form already scrolls, so short phones lose no controls.
