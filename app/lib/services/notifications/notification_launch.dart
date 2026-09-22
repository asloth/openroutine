/// The route a tapped routine reminder should land on.
///
/// The id arrives as a notification payload, which is outside the app's own
/// UI, so it's escaped before it becomes a path segment — the same rule the
/// widget tap path follows in `widgetLaunchRoute`. Ids are schema-constrained
/// UUIDs today, and this is what keeps that from being the only reason the
/// route is well formed.
String routineNotificationRoute(String routineId) =>
    '/routines/${Uri.encodeComponent(routineId)}';
