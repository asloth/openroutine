## 0. Preconditions

- [x] 0.1 Confirm this change stays independent of the concurrent theme work by verifying `app/lib/theme/motion.dart` does not already exist and that nothing it will import comes from `theme/` — the merged theme is a precondition of the *adoption* follow-up, not of these tokens
- [x] 0.2 Confirm the Flutter pin resolves, by verifying `app/.fvmrc` exists and `/home/sabera/fvm/bin/fvm flutter --version` reports 3.41.4 — the global `~/flutter` is 3.24.5 and cannot resolve this project

## 1. Duration and curve tokens

Strict TDD: each pair below writes the failing test first, then the smallest implementation that passes it.

- [x] 1.1 Add `app/test/theme/motion_test.dart` asserting every user-initiated duration token is at most 300ms, and verify it fails because `app/lib/theme/motion.dart` does not yet exist
- [x] 1.2 Create `app/lib/theme/motion.dart` with `AppMotion` duration tokens, absorbing the two durations already in use (120ms press feedback, 250ms standard), and verify 1.1 now passes
- [x] 1.3 Extend the test to assert the entrance curve decelerates and the exit curve accelerates — sample each curve's `transform()` at t=0.25 and t=0.75 and compare progress against linear — and verify it fails
- [x] 1.4 Add the entrance, exit, standard, and progress curve tokens, and verify 1.3 passes
- [x] 1.5 Extend the test to assert the progress curve is the only linear token, per the spec's reservation of linear easing, and verify it passes against 1.4's tokens

## 2. Physics tokens

- [x] 2.1 Extend the test to assert the press-feedback scale sits within 0.95–1.05 inclusive, and verify it fails
- [x] 2.2 Add the press-feedback scale token, and verify 2.1 passes
- [x] 2.3 Extend the test to assert the stagger token is at most 50ms, and verify it fails, then add the stagger token and verify it passes
- [x] 2.4 Add the `SpringDescription` overshoot token with a test asserting it is underdamped, so it actually overshoots rather than merely easing, and verify the test passes

## 3. Reduced-motion resolver

- [x] 3.1 Add a widget test pumping a subtree with `MediaQueryData(disableAnimations: true)` asserting the resolver returns `Duration.zero` for every duration token, and verify it fails
- [x] 3.2 Implement the resolver as the single entry point described in design.md — Decisions, and verify 3.1 passes
- [x] 3.3 Add a widget test asserting that with `disableAnimations: true` an animated state change renders its end state on the first frame after the change, satisfying the spec's "no partial or frozen intermediate state" clause, and verify it passes
- [x] 3.4 Add a widget test asserting the resolver returns the unmodified token duration when `disableAnimations` is false, and verify it passes

## 4. Documentation

- [x] 4.1 Add a `## Motion` section to `DESIGN.md` recording the bounds and their rationale with no value inventory, per design.md — Decisions, placing it after `## Elevation & Depth`
- [x] 4.2 Verify `npx @google/design.md lint DESIGN.md` still reports 0 errors and 0 warnings — in particular no `token-like-ignored` finding, which would mean motion values were placed in frontmatter
- [x] 4.3 Verify `npx @google/design.md export --format dtcg DESIGN.md` still emits all four populated categories, confirming the new section did not disturb the frontmatter

## 5. Verification

- [x] 5.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify it reports no issues
- [x] 5.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes, including the pre-existing tests, confirming this additive change broke nothing
- [x] 5.3 Run `openspec validate establish-motion-system --type change --strict` and verify it passes
- [x] 5.4 Verify the diff touches only `app/lib/theme/motion.dart`, `app/test/theme/motion_test.dart`, and `DESIGN.md` — any other modified file means the change stopped being additive and will conflict with the concurrent theme work
