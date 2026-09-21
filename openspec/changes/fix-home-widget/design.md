## Context

See `proposal.md`. `HomeWidgetPublisher` writes one JSON document, and `RoutineWidgetProvider` and `RoutineListService` render it with `RemoteViews`. The app builds its theme from `Palette.scheme(brightness)`.

## Decisions

### The tap pushes over the list

`openWidgetRoute` runs `go('/routines')` and then `push(route)`. Resetting first also drops whatever screen the app was left on, so a warm tap lands the same way a cold one does.

### Send both schemes, not the one showing now

The widget can outlive the app's process, and the system can switch to dark mode while the app is closed. So the app sends both schemes plus the mode. On Android 12 and later, `RemoteViews.setColorInt(id, method, day, night)` lets the launcher switch between them itself. Before 12, the widget uses whichever one matches the current configuration at update time.

### Tint an image, not the frame

`RemoteViews` can't recolor a shape drawable's fill. The background becomes an `ImageView` of the rounded shape, tinted with `setColorFilter`, which keeps the corners. For the same reason, the `ListView`'s divider moves into each row as a `View` that `setBackgroundColor` can reach.

### Five roles

`surface`, `onSurface`, `onSurfaceVariant`, `primary`, and `outlineVariant`: the same roles the resource colors already stood in for.

## Risks / Trade-offs

**No automated test covers the Kotlin.** The Dart payload and the tap routing are unit-tested, but the rendering needs a check on the phone in light, dark, and a non-default palette.
