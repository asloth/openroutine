## Context

See `proposal.md` — Why, and `openspec/specs/motion-system/spec.md` for the contract this change makes the app conform to.

The relevant existing shape: the router is a single `GoRouter` in `main.dart` with ten `GoRoute`s, all using `builder:`. The two interactive neumorphic controls own their own pressed state via `GestureDetector` + `AnimatedContainer`, and `NeumorphicTheme.raised`/`pressed` already return the decoration for each state — so the pressed *appearance* exists and only its timing and deformation are wrong.

## Goals / Non-Goals

**Goals:**

- Make navigation animate consistently, from one definition rather than ten.
- Make the two defects in the button controls impossible to reintroduce, by asserting them in tests rather than relying on review.
- Keep reduced-motion handling on the default path, so a future animated widget honours it without its author remembering to.

**Non-Goals:**

- Per-route bespoke transitions. One shared transition, applied everywhere.
- Staggered or sequenced entrances. Excluded by product decision, not deferred for effort.
- Touching `mascot_slot.dart`, which already conforms.

## Decisions

### A fade-through with a small rise, not a slide

The shared transition cross-fades and lifts the arriving screen by a short distance, reversing on the way out.

*Alternative considered:* the platform-default horizontal slide. Rejected because a full-width slide is a large, directional gesture that asserts hierarchy between screens, and this app's registers are calm and low-arousal. A fade with a small rise reads as the next screen surfacing rather than being pushed in, and it stays legible when the two screens share a background colour, which they always do here.

*Alternative considered:* a pure cross-fade with no movement. Rejected as too weak to communicate that navigation happened at all — a fade between two screens with the same warm ground can look like a repaint.

### The transition lives outside `theme/`

The shared page builder goes in `app/lib/routing/app_page.dart`, not in `theme/motion.dart`.

*Rationale:* `CustomTransitionPage` comes from go_router. `motion.dart` currently imports only `material.dart`, and pulling a routing package into the theme layer inverts the dependency — the theme would then know about navigation. Keeping the page builder in a routing file lets it consume motion tokens without motion knowing about routes.

### Reduced motion is resolved inside the shared page builder

`transitionDuration` is `context.motion(AppMotion.standard)`, resolved once in the shared builder.

*Rationale:* this is the payoff of the resolver being the single entry point. Ten routes get correct reduced-motion behaviour from one call, and an eleventh route added later gets it by construction. A zero duration makes `CustomTransitionPage` present the destination on the first frame, which is what the spec's navigation-under-reduced-motion scenario requires.

### Press deformation wraps rather than replaces the existing animation

The buttons keep their `AnimatedContainer` for the decoration change and gain an `AnimatedScale` around it for the deformation, both on the same token duration and curve.

*Alternative considered:* animating a `Transform.scale` inside the existing `AnimatedContainer`. Rejected because the container's `decoration` and the scale are different properties with different widgets driving them; nesting `AnimatedScale` keeps each animation owned by the widget designed for it, and both read the same tokens so they stay in step.

Note that the circle button already uses a `scale` argument on `neumorphic.raised` — that is a *shadow* scale for large buttons, unrelated to press deformation. The two must not be conflated.

### Tests assert the defects directly

Rather than only testing that motion looks right, tests assert the two specific defects cannot return: that the press animation's curve is not linear, and that the transition duration collapses to zero under `disableAnimations`.

*Rationale:* both defects are invisible in a screenshot and survived a full design pass unnoticed. A test that names them is the only thing that keeps them fixed.

## Risks / Trade-offs

**Every navigating widget test now has an animation to settle.** → The largest practical risk, and the reason the task list front-loads a full-suite run immediately after the router change rather than at the end. Tests that call `pump()` after a navigation may need `pumpAndSettle()`. This is a test-visibility change, not a regression, but it can look like many simultaneous failures.

**A fade-through can feel sluggish if the duration is too long.** → It uses `AppMotion.standard`, which is bounded by the spec at well under the 300ms ceiling. If it reads as slow on device, the fix is the token, and it moves everywhere at once.

**`CustomTransitionPage` changes what `GoRoute` returns.** → Any code depending on the route's `Page` type, or on `MaterialPage` semantics such as the platform back-swipe on iOS, could behave differently. The app currently ships Android and Linux, so iOS back-swipe is not exercised today, but it is worth stating rather than discovering later.

## Migration Plan

Presentation only, no persisted state, no schema. Rollback is reverting the routes to `builder:` and restoring the inline durations.

## Open Questions

None. The one genuinely open question — how far the motion should go — was settled before this change was written: correctness plus navigation transitions, no stagger.
