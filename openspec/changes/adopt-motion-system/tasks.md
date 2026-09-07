## 0. Preconditions

- [x] 0.1 Confirm the tokens are present by verifying `app/lib/theme/motion.dart` exports `AppMotion` and the `context.motion(...)` extension, and that `app/test/theme/motion_test.dart` passes on its own
- [x] 0.2 Record the pre-change baseline by running the full suite and noting the passing count, so the router change's effect on other tests is measurable rather than guessed

## 1. Press feedback on the neumorphic controls

Strict TDD: the failing test first, then the smallest implementation that passes it.

- [x] 1.1 Add `app/test/theme/neumorphic_motion_test.dart` asserting the circle button's press animation uses a non-linear curve — find the `AnimatedContainer` and assert its `curve` is not `Curves.linear` — and verify it fails against the current implicit default
- [x] 1.2 Give `NeumorphicCircleButton` the `AppMotion.feedback` duration and an explicit `AppMotion.transition` curve, and verify 1.1 passes
- [x] 1.3 Extend the test to make the same assertion for `NeumorphicPillButton`, verify it fails, then apply the same tokens and verify it passes
- [x] 1.4 Add a test asserting both controls visibly deform while held — pump a press, assert the rendered scale is `AppMotion.pressScale`, release, assert it returns to 1.0 — and verify it fails because no deformation exists today
- [x] 1.5 Wrap each control's `AnimatedContainer` in an `AnimatedScale` driven by the same tokens, and verify 1.4 passes. Do not disturb the existing `scale:` argument on `neumorphic.raised`, which is a shadow scale for large buttons and unrelated
- [x] 1.6 Add a test asserting both controls' animation durations collapse to zero under `MediaQueryData(disableAnimations: true)`, verify it fails, then route both through `context.motion(...)` and verify it passes

## 2. Shared page transition

- [x] 2.1 Add `app/test/routing/app_page_test.dart` asserting the shared page builder produces a page whose transition duration is `AppMotion.standard`, and verify it fails because `app/lib/routing/app_page.dart` does not exist
- [x] 2.2 Create the shared page builder returning a `CustomTransitionPage` that cross-fades and lifts the arriving screen, per design.md — Decisions, and verify 2.1 passes
- [x] 2.3 Add a test asserting the transition duration is `Duration.zero` under `disableAnimations`, and verify it passes via the resolver rather than a second code path
- [x] 2.4 Add a test asserting the arriving screen's opacity animation uses `AppMotion.entrance` and the departing one uses `AppMotion.exit`, and verify it passes

## 3. Apply the transition to the router

- [x] 3.1 Convert all ten `GoRoute` entries in `app/lib/main.dart` from `builder:` to `pageBuilder:` using the shared builder, and verify no route is left on `builder:` by grepping for it
- [x] 3.2 Run the full suite immediately and verify the result against the 0.2 baseline — this is the step most likely to surface breakage, since every navigating test now has an animation to settle
- [x] 3.3 For any test that broke, add the missing `pumpAndSettle()` rather than shortening the transition, and verify the suite returns to at least the 0.2 baseline count
- [x] 3.4 Add a widget test navigating between two screens and asserting the destination is not fully present on the first frame but is after settling, verifying the transition actually runs

## 4. Onboarding page slide

- [x] 4.1 Replace the inline 250ms and `Curves.easeOut` in `app/lib/screens/onboarding/onboarding_screen.dart` with `AppMotion.standard` and `AppMotion.entrance` routed through `context.motion(...)`, and verify the existing onboarding tests still pass
- [x] 4.2 Verify no inline motion values remain outside `motion.dart` by grepping for `Duration(milliseconds:` and `Curves.` across `app/lib`, and confirm the only remaining hits are `motion.dart` itself and `mascot_slot.dart`, which is deliberately untouched

## 5. Documentation

- [x] 5.1 Update the `## Motion` section of `DESIGN.md` to record that navigation uses one shared transition and what it does, with no value inventory
- [x] 5.2 Verify `npx @google/design.md lint DESIGN.md` still reports 0 errors and 0 warnings

## 6. Verification

- [x] 6.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no issues
- [x] 6.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the full suite passes at or above the 0.2 baseline
- [x] 6.3 Run `openspec validate adopt-motion-system --type change --strict` and verify it passes
- [x] 6.4 Build and install on the Pixel 9a with `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`, then confirm on device that navigating between screens animates and that pressing a control visibly deforms
