# Design: Android Home Screen Widget

## Technical Approach

Dart is the only reader of the database; the widget is a renderer of a snapshot Dart pushes to it. `HomeWidgetPublisher` denormalizes the routine list into a versioned JSON document, writes it through `home_widget` into the widget's `SharedPreferences`, and asks Android to redraw. `RoutineWidgetProvider` (a `RemoteViews` collection widget) and its `RoutineListService` read that same document and render one row per routine. Row taps travel back as a `openroutine://timer?routineId=…` URI, which the app turns into `router.go('/routines/$id/timer')` — the same "open at route X from outside" shape the notification tap path already uses.

## Architecture Decisions

| Option | Tradeoff | Decision |
|---|---|---|
| Native reads SQLite vs. Dart pushes a snapshot | Native reads need drift's schema v5 encodings (soft deletes, flattened schedule columns, `stepsJson`) reimplemented in Kotlin, and open a second connection to a live database. A pushed snapshot costs one write per routine-list change. | Push a snapshot. The storage contract stays in one language, and the widget cannot corrupt or lock anything. |
| `home_widget` plugin vs. hand-rolled MethodChannel + `FlutterSharedPreferences` | The prefs bridge and an update broadcast are ~60 lines to hand-roll; delivering the launch URI on cold start, on warm start, and through `singleTop`'s `onNewIntent` is the part that is easy to get subtly wrong. The plugin's only transitive dependency is `path_provider`. | Take the plugin. It buys the fiddly half and does not disturb the `meta`/`analyzer` pin. |
| Glance/Compose vs. classic `RemoteViews` | Glance would mean enabling `buildFeatures { compose = true }`, adding the compose compiler plugin, and aligning versions for a single widget in a project with no other Compose. | Classic `RemoteViews`. Plain XML and Kotlin, and `minSdk = 26` needs no compatibility shims. |
| Fixed row slots vs. a collection `ListView` | Fixed slots are simpler but cap the routine count and waste space when resized. The routine count is entirely user-driven. | `RemoteViewsService` + `ListView`: scrolls, adapts to any widget size, and each row gets its own fill-in intent. |
| Native `values-es/strings.xml` vs. strings pushed from Dart | A native strings file forks user-facing copy away from the ARB files, which the project rule says must be edited together. | Push localized copy in the payload; keep only English fallbacks natively for the pre-first-launch case. |
| Format the start time in Dart vs. in Kotlin | A Dart-formatted string freezes the 12/24-hour choice at publish time and would go stale when the system setting changes. | Push the raw `"HH:MM"` and format natively with `DateFormat.is24HourFormat(context)`, mirroring how `_StartTime` follows `MediaQuery.alwaysUse24HourFormatOf`. |

## Data Flow

```text
routinesProvider ──> homeWidgetPublisherProvider ──> HomeWidgetPublisher.publish
                                                             │
                                        HomeWidget.saveWidgetData('routines_v1', json)
                                        HomeWidget.updateWidget(RoutineWidgetProvider)
                                                             │
                                     RoutineWidgetProvider.onUpdate ──> notifyAppWidgetViewDataChanged
                                                             │
                                        RoutineListService / RoutineListFactory
                                          reads HomeWidgetPlugin.getData(context)
                                                             │
                                        row fill-in intent: openroutine://timer?routineId=<id>
                                                             │
                        MainActivity (singleTop) ──> home_widget ──> initiallyLaunchedFromHomeWidget
                                                                  └─> widgetClicked stream
                                                             │
                                                  router.go('/routines/<id>/timer')
```

`HomeWidgetPublisher` owns encoding and swallows platform failures the way `NotificationService` does — a widget that cannot be reached must never break the app. The provider owns *when* to publish. `main.dart` owns the routing, so the widget knows nothing about routes beyond the URI shape.

## Interfaces / Contracts

Payload, stored under the single key `routines_v1`. Internal and versioned; explicitly **not** part of `schemas/`, which is the public agent contract.

```json
{
  "v": 1,
  "routines": [
    {"id": "0192…", "name": "Morning", "startTime": "07:30", "stepCount": 7}
  ],
  "strings": {"title": "OpenRoutine", "empty": "No routines yet", "openApp": "Open OpenRoutine"}
}
```

- `startTime` is the schema's local `"HH:MM"` string, or absent for flexible routines.
- `routines` carries only active (non-deleted) routines, ordered scheduled-by-start-time then flexible-by-name.
- A missing or unparseable document renders the empty state rather than throwing; the factory treats any parse failure as "no routines".
- Tap URI: `openroutine://timer?routineId=<id>`. The empty state uses `openroutine://open`.

No public, persisted, or generated interface changes. `Routine`, `RoutineStep`, the storage adapters, and every schema in `schemas/` are untouched.

## Testing Strategy

Strict TDD: failing test, minimum implementation, refactor while green.

| Layer | What to Test | Approach |
|---|---|---|
| Unit | Payload shape and version; scheduled-then-flexible ordering; start time passed through verbatim and omitted for flexible; step counts; empty list; localized strings included; platform failures swallowed | `home_widget_publisher_test.dart` against a fake sink capturing `(key, json)` and update calls |
| Unit | Republish on every routine-list emission, and not on unrelated rebuilds | `home_widget_provider_test.dart` with an overridden storage adapter driving `routinesProvider` |
| Widget | N/A — the rendered surface is Android `RemoteViews`, outside Flutter's widget tree | Covered by the on-device checklist |
| Integration/E2E | Not available in this repository | Manual on-device verification on the Pixel 9a, plus the debug APK build in CI to catch native compile and manifest errors |

## Threat Matrix

The widget introduces one new externally reachable entry point: an exported `AppWidgetProvider` receiver and the URI it hands the app.

| Boundary | Concern | Control |
|---|---|---|
| Exported receiver | Any app can broadcast `APPWIDGET_UPDATE` to it | The provider only re-renders from local prefs; it takes no data from the intent and performs no writes |
| Launch URI | A crafted `routineId` could route somewhere unintended | The URI is only ever turned into `/routines/<id>/timer`; the id is path-encoded, and an unknown id resolves to the existing not-found handling. The router's onboarding redirect still applies |
| `RemoteViewsService` | Must not be startable by other apps | Declared `android:exported="false"` with `android:permission="android.permission.BIND_REMOTEVIEWS"` |
| Snapshot contents | Routine names sit in app-private `SharedPreferences` and on the home screen | No new storage location beyond the app sandbox; nothing leaves the device. Routine names are already visible on notifications |

## Migration / Rollout

No migration, no feature flag, no persisted state. Delivered as five reviewable slices (see `tasks.md`), each independently revertable; the Dart half is inert until the manifest entries exist, so an incomplete rollout is invisible rather than broken.

## Open Questions

None blocking. Two follow-ups are recorded in the proposal rather than resolved here: palette-aware widget colors, and starting Low Mode from the widget.
