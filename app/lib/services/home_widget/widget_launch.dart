import 'package:go_router/go_router.dart';

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

/// Opens [route] for a widget tap, on top of the routine list.
///
/// A bare `go` would leave the timer as the only page, and its Close button
/// and the back gesture both pop, which throws on an empty stack. Resetting
/// to the list first also drops whatever screen the app was left on, so the
/// tap lands the same way whether the app was cold, warm, or mid-edit.
void openWidgetRoute(GoRouter router, String route) {
  router
    ..go('/routines')
    ..push(route);
}
