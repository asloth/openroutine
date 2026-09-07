import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion.dart';

/// The one transition every route uses.
///
/// Navigation used to be a stock Material push on all nine routes, which is
/// the largest single reason the app read as assembled rather than designed.
/// One shared definition rather than nine, so navigation feels the same
/// wherever it goes and a route added later inherits it by construction.
///
/// A fade with a small rise, not a slide. A full-width slide is a large
/// directional gesture that asserts hierarchy between screens, which is the
/// wrong register for an app built to lower activation energy. A pure
/// cross-fade is the opposite problem: every screen shares the same warm
/// ground, so a fade alone can look like a repaint rather than a navigation.
/// The rise supplies just enough movement to read as arrival.
///
/// Lives here rather than in `theme/` because [CustomTransitionPage] comes
/// from go_router, and the theme layer has no business knowing about routing.
///
/// The duration is resolved through [AppMotionContext.motion], so all ten
/// routes honour reduced motion from this single call. At zero duration the
/// destination is presented on the first frame, which is what the
/// motion-system spec requires of navigation under reduced motion.
///
/// [key] is required, and route callers must pass `state.pageKey`. Without a
/// distinct key per route, `Navigator.canUpdate` sees two pages of the same
/// runtime type with the same (null) key, treats the destination as an update
/// of the current route rather than a new one, and swaps the child in place —
/// so nothing animates at all. Requiring the key is what stops that returning.
CustomTransitionPage<void> appPage(
  BuildContext context, {
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: context.motion(AppMotion.standard),
    reverseTransitionDuration: context.motion(AppMotion.standard),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final entering = CurvedAnimation(
        parent: animation,
        curve: AppMotion.entrance,
      );
      // The outgoing screen is driven by the secondary animation, and it is
      // leaving, so it takes the exit curve rather than the entrance one.
      final leaving = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotion.exit,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(leaving),
        child: FadeTransition(
          opacity: entering,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(entering),
            child: child,
          ),
        ),
      );
    },
  );
}
