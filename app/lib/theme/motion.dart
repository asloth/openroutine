/// Motion tokens for OpenRoutine.
///
/// Before this file, motion was decided per widget: one easing curve in the
/// whole app, three durations, and no screen transitions at all. That is what
/// makes an interface read as assembled rather than designed — not the absence
/// of animation, but the absence of agreement about it.
///
/// The bounds below come from Disney's twelve principles as they apply to
/// interfaces: motion that answers a tap resolves inside the window where the
/// user is still waiting for it, easing says whether a thing is arriving or
/// leaving, and deformation stays subtle enough to read as a press rather than
/// a glitch.
///
/// Reach for a token rather than an inline `Duration` or a bare `Curves.*`.
/// A magic number at a call site is a motion decision made once, in private,
/// that nobody can reconcile with the next one.
///
/// Nothing here varies with the palette, which is why these are plain
/// constants rather than a `ThemeExtension` like `NeumorphicTheme`: 250ms is
/// 250ms in every palette, and pretending otherwise would put a `context` in
/// the way of every animation for no gain.
library;

import 'package:flutter/material.dart';

abstract final class AppMotion {
  // ---------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------

  /// Press and release feedback. Short enough that the control feels
  /// connected to the finger rather than reporting back after the fact.
  static const feedback = Duration(milliseconds: 120);

  /// Small local changes: a chip toggling, an icon swapping, a value
  /// stepping. Fast enough not to be waited on.
  static const quick = Duration(milliseconds: 180);

  /// The default for a state change the user asked for and is watching.
  static const standard = Duration(milliseconds: 250);

  /// The ceiling, for motion that has to carry a larger distance or a change
  /// of context. Past this the user has finished the thought that the
  /// animation is still illustrating.
  static const emphasized = Duration(milliseconds: 300);

  /// Delay between consecutive items entering as a group. Beyond ~50ms a
  /// list stops reading as one group arriving and starts reading as items
  /// loading one at a time.
  static const stagger = Duration(milliseconds: 40);

  /// Every duration that answers a direct user action, and therefore every
  /// duration bound by the 300ms rule. [stagger] is excluded because it is a
  /// delay between elements rather than the length of any single animation.
  static const userInitiated = <Duration>[
    feedback,
    quick,
    standard,
    emphasized,
  ];

  // ---------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------

  /// Anything arriving: decelerates into place, fast on arrival and settling
  /// gently. An entrance that accelerates reads as the element being pulled
  /// away rather than delivered.
  static const entrance = Curves.easeOutCubic;

  /// Anything leaving: accelerates away, building momentum before it goes.
  /// The mirror of [entrance], and using the wrong one of the pair is the
  /// single most common way motion ends up feeling backwards.
  static const exit = Curves.easeInCubic;

  /// An element that is on screen before and after — repositioning, resizing,
  /// recolouring. It accelerates away from where it was and decelerates into
  /// where it is going, because it is doing both things in one move.
  static const transition = Curves.easeInOutCubic;

  /// Reserved for indicators that map onto elapsed time or completion: a
  /// progress ring, a bar filling. This is the only linear token, and it is
  /// linear precisely because it is not depicting an object moving — nothing
  /// physical starts and stops at a constant speed, but elapsed time does.
  static const progress = Curves.linear;

  /// Every curve that depicts an object moving, and therefore every curve the
  /// ban on linear easing applies to. [progress] is deliberately absent.
  static const objectCurves = <Curve>[entrance, exit, transition];

  // ---------------------------------------------------------------------
  // Physics
  // ---------------------------------------------------------------------

  /// How far an interactive control shrinks while held. Three percent is
  /// enough to see and not enough to notice: past about five the control
  /// reads as glitching, and at exactly 1.0 it reads as dead, which is the
  /// more common failure of the two.
  static const pressScale = 0.97;

  /// For motion that should overshoot and settle rather than ease to a stop.
  ///
  /// A spring rather than `Curves.elasticOut` because a curve has a fixed
  /// shape over a fixed duration: interrupt it mid-flight and it can only
  /// snap or restart. A spring carries velocity across the interruption,
  /// which is the whole reason a re-targeted gesture feels continuous.
  ///
  /// Damping ratio is roughly 0.67 — under 1, so it overshoots, but high
  /// enough that it settles on the first return instead of visibly ringing.
  static const overshoot = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 30,
  );
}

/// Resolves a motion token against the platform's accessibility settings.
///
/// This is the single place motion is allowed to be suppressed. Route every
/// animated duration through it — `duration: context.motion(AppMotion.standard)`
/// — rather than passing a token straight to a widget.
///
/// Flutter does not do this for you. `MediaQueryData.disableAnimations` is
/// honoured by parts of the framework, but it is not applied to a duration you
/// hand to `AnimatedContainer`, nor to an `AnimationController` you drive
/// yourself. A widget that ignores it keeps animating for someone who asked
/// the operating system not to.
extension AppMotionContext on BuildContext {
  /// [duration], or [Duration.zero] when the user has asked for reduced
  /// motion.
  ///
  /// Zero rather than skipping the animation: a zero-duration animation in
  /// Flutter still runs and still completes, so the widget lands on its end
  /// state on the next frame. Suppressing the animation by not starting it
  /// would leave the interface holding its *old* state, which is the failure
  /// the requirement is written against.
  Duration motion(Duration duration) =>
      (MediaQuery.maybeDisableAnimationsOf(this) ?? false)
      ? Duration.zero
      : duration;
}
