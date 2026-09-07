/// The scheme the Android widget's rows launch the app with. Must match
/// `RoutineListFactory.TIMER_URI_PREFIX` and `RoutineWidgetProvider.OPEN_URI`.
const widgetUriScheme = 'openroutine';

/// The route a widget tap should land on, or null if it should only open the
/// app where it left off.
///
/// A tap arrives as an opaque URI from outside the app, so nothing here trusts
/// it: an unexpected scheme, host or missing id opens nothing rather than
/// routing somewhere unintended. An id that no longer exists is left to the
/// router's existing not-found handling, and the onboarding redirect still
/// wins over any of this.
String? widgetLaunchRoute(Uri uri) {
  if (uri.scheme != widgetUriScheme || uri.host != 'timer') return null;

  final routineId = uri.queryParameters['routineId'];
  if (routineId == null || routineId.isEmpty) return null;

  return '/routines/${Uri.encodeComponent(routineId)}/timer';
}
