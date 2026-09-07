# Proposal: Android Home Screen Widget

## Why

Starting a routine today costs unlock → find the app → open it → pick the routine → tap into Timer Mode. The app exists to remove friction from starting, so the launch path itself is the highest-leverage thing left to shorten. A home screen widget that lists the routines and starts one in a single tap collapses that path to one gesture.

## What Changes

### In Scope
- An Android app widget listing the user's active routines as `start time · name · step count`, ordered the way the in-app list orders them (scheduled by start time, then flexible by name).
- Tapping a row opens the app directly at `/routines/:routineId/timer`, which starts the run.
- The widget list stays current: every change to the routine list — create, rename, delete, reorder, a Drive sync pulling another device's change — republishes the snapshot and redraws the widget.
- Localized (en/es) header and empty-state copy, pushed pre-rendered from Dart so the ARB files stay the single source of user-facing strings.
- Light and dark widget colors drawn from the warm-paper palette.

### Out of Scope
- iOS. The iOS project has no App Group and no WidgetKit extension, and neither can be compiled or exercised from the Linux development machine; shipping unverifiable Swift is worse than shipping nothing.
- Starting Low Mode from the widget, showing today's progress, and mirroring a run in progress.
- Following the user's palette selection (the widget ships with the default palette; see Risks).
- Schema changes. The widget payload is a private app↔widget detail and MUST NOT enter `schemas/`.

## Capabilities

### New Capabilities
- `home-screen-widget`: an Android launcher surface that lists routines and starts one in Timer Mode.

### Modified Capabilities
- None.

## Approach

Dart owns the data and native only renders it. A keep-alive provider watches `routinesProvider`, denormalizes each routine into a small versioned JSON snapshot, and hands it to the `home_widget` plugin, which stores it in the widget's `SharedPreferences` and asks Android to redraw. A classic `RemoteViews` collection widget (`AppWidgetProvider` + `RemoteViewsService`) parses that snapshot and renders one scrollable row per routine. Row taps carry a `openroutine://timer?routineId=…` URI back through `home_widget`, and the app routes it with `router.go` exactly as the existing notification tap path does.

The widget deliberately never opens the drift database: reimplementing schema v5 — soft deletes, flattened schedule columns, JSON-encoded step lists — in Kotlin would duplicate the storage contract in a second language and risk a second SQLite connection against a live one.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `app/lib/services/home_widget/home_widget_publisher.dart` | Added | Snapshot encoding and the plugin calls, behind an injectable seam |
| `app/lib/state/home_widget_provider.dart` | Added | Keep-alive provider republishing on every routine-list change |
| `app/lib/main.dart` | Modified | Widget-launch routing beside the existing notification routing; keeps the publisher alive |
| `app/lib/l10n/app_en.arb`, `app_es.arb` | Modified | Widget header and empty-state copy |
| `app/android/app/src/main/kotlin/app/openroutine/mobile/` | Added | `RoutineWidgetProvider`, `RoutineListService` |
| `app/android/app/src/main/res/` | Added | Widget and row layouts, provider info XML, colors, fallback strings |
| `app/android/app/src/main/AndroidManifest.xml` | Modified | Widget receiver and the `BIND_REMOTEVIEWS` service |
| `app/pubspec.yaml` | Modified | `home_widget: ^0.9.4` |
| `.github/workflows/flutter-ci.yml` | Modified | Compile the Android app so native breakage cannot pass CI |
| `docs/SPEC.md` | Modified | Record the widget, its payload contract, and the Android-only decision |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Collection widgets need a mutable `PendingIntent` template plus fill-in intents, which the plugin's own launch helper does not build | Med | Build the template by hand carrying the plugin's launch action and let the fill-in supply the URI; verify on device before building on top of it, and fall back to an `openroutine://` `VIEW` intent-filter read in `MainActivity` |
| A cold-start tap arrives twice (launch query and click stream) and double-navigates | Med | Ignore a first stream event identical to the initial launch URI |
| The widget is placed before the app has ever run, so the snapshot is empty | High | Native fallback strings and an empty view whose tap opens the app |
| Kotlin sources compile against an unpinned JDK (machine default is 26, which Kotlin 2.2.20 cannot parse) | Med | Keep the existing `flutter config --jdk-dir` fix; add the debug APK build to CI so the native side is compiled on every PR |
| Widget colors drift from the user's chosen palette | Low | Ship the default warm-paper palette now; pushing palette colors in the payload is a follow-up, recorded here rather than forgotten |

## Rollback Plan

Revert the change as a whole: the Dart additions are inert without the manifest entries, and the manifest entries are inert without the Dart publisher. No storage, schema, or migration is involved, so no data is at risk and no user-visible in-app behavior changes. A user who has placed the widget sees it stop updating and go empty after an uninstall of the receiver; nothing else regresses.

## Dependencies

- `home_widget` ^0.9.4 (Dart ≥3.10, Flutter ≥3.38.1 — satisfied by 3.11.1 / 3.41.4; its only transitive dependency is `path_provider`, so it does not disturb the `meta` / `analyzer` pin documented in `app/pubspec.yaml`).
- The existing `/routines/:routineId/timer` route and `TimerScreen`'s auto-start behavior.

## Success Criteria

- [ ] The widget can be placed from the launcher's widget picker and lists the real routines.
- [ ] Start times render according to the phone's 12/24-hour setting.
- [ ] Creating, renaming or deleting a routine updates the widget without any manual refresh.
- [ ] Tapping a row with the app closed lands in Timer Mode with the run already started.
- [ ] Tapping a row with the app already open on another screen does the same.
- [ ] The list scrolls when the widget is resized shorter than the routine count.
- [ ] Dark mode applies the night colors.
- [ ] `flutter analyze --fatal-infos`, `flutter test`, and a debug APK build all pass.
