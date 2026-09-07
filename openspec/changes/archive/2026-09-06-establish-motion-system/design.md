## Context

See `proposal.md` — Why for motivation, and `specs/motion-system/spec.md` for the behavioral contract.

Two facts about the existing codebase shape this design. First, the theme layer already has a settled convention: `AppSpacing`, `AppRadius`, and `AppTypography` are plain `abstract final class` holders of compile-time constants, while `NeumorphicTheme` is a `ThemeExtension` specifically because its shadow colours vary with the selected palette. Second, the app currently uses exactly two deliberate animation durations, 120ms and 250ms, and one curve.

This change does not touch sync, import/export, migration, or timer behaviour, so the project rule requiring data-flow notes for those areas does not apply — no data flows are added or altered.

## Goals / Non-Goals

**Goals:**

- Give every animation a named token to reach for, so a duration or curve is chosen once and reused rather than re-decided per widget.
- Make the spec's bounds machine-checkable, so conformance is a test failure rather than a review opinion.
- Keep the reduced-motion contract in one place, so honouring it is the default path and not something each widget remembers.

**Non-Goals:**

- Enforcing that call sites actually use the tokens. Nothing here prevents someone writing `Duration(milliseconds: 400)` inline; that is a review and lint concern addressed by the adoption change.
- Screen transitions, shared-element transitions, and per-widget motion. Those are the adoption change.
- Retiming the two durations already in use. They are absorbed as tokens so adoption is a rename, not a behavioural change.

## Decisions

### Plain constants, not a ThemeExtension

Motion tokens are compile-time constants in `app/lib/theme/motion.dart`, matching `AppSpacing` and `AppTypography`.

*Alternative considered:* a `ThemeExtension`, mirroring `NeumorphicTheme`. Rejected because `NeumorphicTheme` earns that cost by varying with the palette — its shadow colours differ per theme. Motion does not vary by palette or brightness: a 250ms ease-out is 250ms in every palette. Making it a theme extension would add `context` plumbing to every call site and imply a variability that does not exist.

### An explicit reduced-motion resolver

A single helper resolves a token duration against the platform's accessibility state, returning `Duration.zero` when animations are disabled.

*Alternative considered:* relying on Flutter to handle it. Rejected because `MediaQueryData.disableAnimations` is honoured by some framework widgets but is not applied to a hand-driven `AnimationController` or an `AnimatedContainer` duration. Since the spec requires the interface to land on its *end state* rather than freeze mid-transition, and since zero-duration animations in Flutter complete immediately rather than not running, resolving the duration to zero satisfies the requirement without branching the widget tree.

Routing every token through one resolver also means the spec's "no control becomes unreachable" clause has a single place it can be violated, and therefore a single place to test it.

### Springs only where overshoot is wanted

Curve tokens cover ordinary motion; one `SpringDescription` token covers overshoot-and-settle.

*Alternative considered:* `Curves.elasticOut` for bounce. Rejected because an elastic curve has a fixed shape over a fixed duration, so it cannot be interrupted mid-flight and re-targeted — it restarts or snaps. A spring simulation carries velocity, which is what makes an interrupted gesture feel continuous. The spec's press-feedback and overshoot requirements are the only places this matters today, so exactly one spring is defined rather than a family.

### `DESIGN.md` records motion rules, not motion values

`app/lib/theme/motion.dart` is the normative source for every motion value. `DESIGN.md` gains a `## Motion` section carrying the rules and their rationale — the 300ms bound, the entrance/exit easing semantics, the stagger ceiling — but no value inventory.

*Alternative considered:* a `motion:` token category in the `DESIGN.md` frontmatter, alongside `colors` and `spacing`. Rejected on evidence: the installed specification recognises only `colors`, `typography`, `spacing`, `rounded`, and `components`. Linting a document with a `motion:` block returns `token-like-ignored` — *"looks like a design-token map but is not a recognized schema key … It will be silently ignored by export commands."* Motion values placed there would lint as a warning and vanish from every export, which is worse than not putting them there at all, because the document would appear to carry them.

This lands where the format wants it anyway: its own guidance puts normative values in frontmatter and reserves Markdown for intent and application guidance. With no frontmatter category available, motion values live in Dart and `DESIGN.md` explains how to apply them.

### Bounds are asserted against the tokens themselves

Tests assert properties over the exported token set — every user-initiated duration is at most 300ms, the stagger token is at most 50ms, the press-feedback scale sits within 0.95–1.05, the progress curve is the only linear one.

*Alternative considered:* a custom analyzer lint enforcing the bounds at every call site. Rejected for this change as disproportionate: it is a separate tooling effort, and with no adoption yet there are no call sites to lint. Property tests over the token set catch the case that actually matters now — a token being added or edited out of bounds.

## Risks / Trade-offs

**Tokens ship unused until the adoption change lands.** → Accepted deliberately. The alternative is conflicting with a concurrent rewrite of every screen. The tokens are additive and inert, so there is no cost to them sitting unused, and `DESIGN.md` documents them so the other branch can adopt them directly rather than inventing parallel values.

**Nothing forces a call site to use a token.** → Property tests protect the token set, not its usage. The adoption change carries the per-widget tests, and review is the interim control. Documenting the bounds in `DESIGN.md` makes a non-conforming value visible to a reviewer.

**The spec's "comparable elements animate identically" requirement is not fully testable from tokens alone.** → Tokens make identical timing the path of least resistance, but proving two controls actually match requires the widgets to exist. Deferred to adoption, where the assertion has something to bind to.

**A future in-app reduced-motion setting could bypass the platform check.** → The resolver is the single entry point, so adding a second input to it later is a one-file change rather than an audit of every widget.

## Migration Plan

Additive. One new file plus its test and a documentation section; no existing Dart file is modified, so there is nothing to migrate and no intermediate state.

Rollback is deleting `app/lib/theme/motion.dart`, its test, and the `DESIGN.md` section. Because nothing is persisted and no existing file changes, rollback cannot leave residue.

## Open Questions

- Whether the app should eventually offer its own reduced-motion toggle in Settings alongside the platform preference. This does not change the specs, the token set, or the task breakdown — it would add one input to the resolver — so it can be answered after adoption, when there is motion to reduce.
