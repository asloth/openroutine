## Why

OpenRoutine has no motion design. The app ships one easing curve (`Curves.easeOut`), three animation durations, a single `AnimationController`, and zero custom screen transitions — every navigation is a stock Material push. Motion is currently decided per-widget by whoever wrote it, which is why the interface reads as assembled rather than designed.

This matters more here than in a typical app. OpenRoutine's job is to lower the activation energy of starting a routine, and abrupt state changes cost attention: a step that swaps instantly gives the user no continuity between "what I was doing" and "what I am doing now". Motion is the cheapest way to make that continuity legible.

## What Changes

- Add `app/lib/theme/motion.dart` defining `AppMotion` — the named duration, curve, and spring tokens every animation must reach for, replacing inline `Duration(milliseconds: …)` and bare `Curves.*` at call sites.
- Adopt the timing/easing/physics constraints from Disney's 12 principles as normative rules: user-initiated motion completes within 300ms; entrances ease out and exits ease in; linear is reserved for progress indicators; press feedback deforms only within 0.95–1.05; list stagger stays at or below 50ms per item.
- Add a reduced-motion contract: when the platform reports `disableAnimations`, token-driven durations collapse to zero so animation-dependent UI still reaches its end state rather than freezing mid-transition.
- Add a `## Motion` section to `DESIGN.md` recording the rationale, with the exact token values in its frontmatter.

Not in this change: applying the tokens to existing screens. That is deliberately deferred — see Impact.

## Capabilities

### New Capabilities

- `motion-system` — the app-wide motion contract: which tokens exist, the bounds a conforming animation must satisfy, and how motion degrades when the platform asks for less of it.

### Modified Capabilities

None. `openspec/specs/` is currently empty, so this change introduces the first capability and does not alter existing requirements.

## Impact

**Code.** One new file (`app/lib/theme/motion.dart`) plus its tests, and a documentation section in `DESIGN.md`. No existing Dart file is modified.

**Storage and schema.** None. Motion tokens are compile-time constants; nothing is persisted, nothing crosses the Drive sync or import/export boundary, and no file under `schemas/` or `app/assets/schemas/` changes. This change cannot affect the public agent contract.

**i18n.** None. No user-facing strings are added.

**Dependencies.** None. Durations, curves, and spring simulations are all in the Flutter SDK.

**Deliberately deferred — screen adoption.** Applying these tokens touches every screen widget, and a concurrent branch is currently rewriting the theme, palette, and all five screens. Landing tokens and screen adoption together would guarantee conflicts in files being rewritten. Delivering the tokens alone keeps this change additive and lets adoption land as a follow-up change against the merged theme. This also keeps the slice inside the 400-line review budget.

**Rollback.** Deleting `app/lib/theme/motion.dart`, its test, and the `DESIGN.md` section fully reverts the change. Because no existing file is modified and nothing is persisted, there is no migration to unwind and no state that can outlive the revert.
