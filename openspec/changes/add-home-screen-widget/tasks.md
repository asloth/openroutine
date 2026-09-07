# Tasks: Android Home Screen Widget

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 700–850 |
| 400-line budget risk | High |
| 400-line budget at risk | Yes |
| Chained PRs recommended | Yes |
| Suggested split | Dart publisher · native widget · tap routing · CI and docs |
| Delivery strategy | auto-chain |
| Chain strategy | sequential, each phase green before the next |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: sequential
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Dart publisher and provider | PR 1 | `cd app && flutter test test/services/home_widget test/state/home_widget_provider_test.dart` | flutter_test with a fake widget sink | Revert `lib/services/home_widget/`, `lib/state/home_widget_provider.dart`, the ARB keys and the pubspec entry |
| 2 | Native widget surface | PR 2 | `cd app && flutter build apk --debug` | Debug APK build; visual check on device | Revert `android/app/src/main/{kotlin,res}` additions and the manifest hunk |
| 3 | Tap routes into Timer Mode | PR 3 | `cd app && flutter test && flutter build apk --debug` | On-device cold/warm start | Revert the `main.dart` launch handling and the fill-in intent wiring |
| 4 | CI compiles Android; SPEC records the contract | PR 4 | CI run | GitHub Actions | Revert the workflow and docs hunks |

## Phase 1: Dart Publisher TDD

- [x] 1.1 Add `home_widget: ^0.9.4` to `app/pubspec.yaml` with a note on why the dependency is safe against the `meta`/`analyzer` pin, and run `flutter pub get`.
- [x] 1.2 RED — In `app/test/services/home_widget/home_widget_publisher_test.dart`, assert the payload's version, that scheduled routines come first ordered by start time and flexible ones follow by name, that `startTime` is passed through verbatim and omitted when absent, and that step counts and localized strings are present.
- [x] 1.3 GREEN — Add `app/lib/services/home_widget/home_widget_publisher.dart`: encode the snapshot and write it through an injectable sink so tests never touch the plugin.
- [x] 1.4 RED — Assert an empty routine list still publishes a well-formed document, and that a throwing sink is swallowed rather than propagated.
- [x] 1.5 GREEN — Make the publisher failure-tolerant and a no-op off Android, mirroring `NotificationService.init`.
- [x] 1.6 RED — In `app/test/state/home_widget_provider_test.dart`, assert a republish on every `routinesProvider` emission.
- [x] 1.7 GREEN — Add `app/lib/state/home_widget_provider.dart` (keep-alive) and keep it alive from `OpenRoutineApp.build`.
- [x] 1.8 Add the widget header, empty-state and open-app strings to `app/lib/l10n/app_en.arb` and `app_es.arb` together; run `flutter gen-l10n`.
- [x] 1.9 REFACTOR — Tidy the publisher and provider while green; run `flutter analyze --fatal-infos` and `flutter test`.

## Phase 2: Native Widget Surface

- [x] 2.1 Add `res/layout/routine_widget.xml` (header, `ListView`, empty view) and `res/layout/routine_widget_row.xml` (time · name · step count).
- [x] 2.2 Add `res/values/colors.xml` and `res/values-night/colors.xml` from the warm-paper palette in `app/lib/theme/colors.dart`, plus `res/values/strings.xml` with English fallbacks only.
- [x] 2.3 Add `res/xml/routine_widget_info.xml`: `updatePeriodMillis="0"`, resizable in both axes, 2×2 minimum with `targetCellWidth`/`targetCellHeight` for API 31+, `previewLayout`, `widgetCategory="home_screen"`.
- [x] 2.4 Add `RoutineWidgetProvider.kt` and `RoutineListService.kt`; parse the snapshot defensively so any malformed document renders the empty state.
- [x] 2.5 Register the receiver and the `BIND_REMOTEVIEWS` service in `AndroidManifest.xml`.
- [ ] 2.6 Build the debug APK, install on the Pixel 9a, place the widget, and confirm it lists the real routines with correctly formatted times in light and dark. **Blocked: no device connected — the debug APK builds, but nothing has rendered it yet.**

## Phase 3: Tap Into Timer Mode

- [x] 3.1 Set the mutable `PendingIntent` template on the collection and per-row fill-in intents carrying `openroutine://timer?routineId=<id>`; give the empty view `openroutine://open`.
- [x] 3.2 In `app/lib/main.dart`, handle the initial launch URI once and subscribe to the click stream, both routing to `/routines/<id>/timer`, de-duplicating an initial event that arrives on both paths.
- [ ] 3.3 **Blocked on the phone.** Verify on device: tap with the app closed, tap with the app open on another screen, tap before onboarding is complete (the redirect must still win), and tap a row for a routine deleted since the last publish.
- [ ] 3.4 Contingent on 3.3. If the plugin does not receive the merged intent, fall back to an `openroutine://` `VIEW` intent-filter on `MainActivity` reading `intent.data`; record which path was taken.

## Phase 4: CI and Documentation

- [x] 4.1 Add `flutter build apk --debug` to `.github/workflows/flutter-ci.yml` so Kotlin and manifest errors cannot pass CI.
- [x] 4.2 Document the widget, its payload contract and the Android-only decision in `docs/SPEC.md`.

## Phase 5: Verification

- [x] 5.1 From `app/`: `flutter pub get`, `flutter gen-l10n`, `dart run build_runner build`, `flutter analyze --fatal-infos`, `flutter test`.
- [ ] 5.2 Run the on-device checklist in the proposal's success criteria and capture screenshots.
- [ ] 5.3 Confirm CI is green on the pushed branch.
