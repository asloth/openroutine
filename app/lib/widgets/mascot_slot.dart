import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// What the mascot is reacting to. Screens pass a mood, never a frame or an
/// animation name — so the day the Rive file lands, the swap happens inside
/// this widget and no call site changes.
enum MascotMood {
  /// Nothing in progress. Empty states, a routine sitting idle.
  idle,

  /// A step is running. Ears up, watching the clock with you.
  focused,

  /// Paused, or an evening routine. Eyes closed.
  resting,

  /// A routine just finished.
  cheering,
}

/// The mascot's spot on screen, with a hand-drawn stand-in until the Rive pet
/// is ready.
///
/// This is deliberately a *slot*, not a drawing: the placeholder below is
/// throwaway, the API around it is not. To swap in the real pet, add `rive` to
/// pubspec, load the `.riv` in [_MascotSlotState], and map [MascotMood] onto
/// the artboard's state-machine inputs. Nothing outside this file has to move.
///
/// Decorative by default — every place it appears already has text saying the
/// same thing, so announcing it again would just make a screen reader
/// repetitive. Pass [semanticLabel] if that ever stops being true.
///
/// The pet breathes for a few cycles on arrival and then settles into a still
/// rest pose, rather than looping forever. Perpetual motion in the corner of
/// the eye is exactly the kind of competing stimulus this app exists to
/// remove, and a pet that never stops moving is a pet you end up ignoring.
/// It also means the widget reaches a steady state, so `pumpAndSettle` in the
/// existing screen tests still terminates. Reduce-motion skips the warm-up
/// entirely and goes straight to rest.
class MascotSlot extends StatefulWidget {
  const MascotSlot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 120,
    this.semanticLabel,
  });

  final MascotMood mood;
  final double size;
  final String? semanticLabel;

  @override
  State<MascotSlot> createState() => _MascotSlotState();
}

class _MascotSlotState extends State<MascotSlot>
    with SingleTickerProviderStateMixin {
  /// How many breaths the pet takes before settling. The controller runs
  /// once across all of them rather than repeating, so it finishes.
  static const _breaths = 3;
  static const _breathDuration = Duration(milliseconds: 3600);

  /// One controller drives everything. Breathing is a sine over each cycle and
  /// the blink is a short window near the end of it, so the pet never blinks
  /// mid-inhale — the detail that makes it read as alive rather than as two
  /// loops running next to each other.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _breathDuration * _breaths,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery isn't available in initState, and reduce-motion decides
    // whether the warm-up runs at all.
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Follows whichever palette the user picked; falls back to the default
    // pet if the extension is somehow missing rather than rendering nothing.
    final colours =
        Theme.of(context).extension<MascotPalette>() ??
        Palette.warmPaper.mascot;

    final pet = RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _MascotPainter(
              mood: widget.mood,
              // Phase within the current breath. The controller ends on a
              // whole number of cycles, so it lands back at 0 — the rest
              // pose — instead of freezing mid-inhale.
              t: reduceMotion ? 0 : (_controller.value * _breaths) % 1.0,
              body: colours.body,
              bodyShade: colours.bodyShade,
              ink: colours.ink,
              blush: colours.blush,
            ),
          ),
        ),
      ),
    );

    final label = widget.semanticLabel;
    return label == null
        ? ExcludeSemantics(child: pet)
        : Semantics(label: label, image: true, child: pet);
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.mood,
    required this.t,
    required this.body,
    required this.bodyShade,
    required this.ink,
    required this.blush,
  });

  final MascotMood mood;
  final double t;
  final Color body;
  final Color bodyShade;
  final Color ink;
  final Color blush;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Breathing: a shallow sine on the vertical axis only. Scaling both axes
    // reads as zooming; scaling one reads as a chest.
    final breath = math.sin(t * 2 * math.pi);
    final squash = mood == MascotMood.cheering ? 0.045 : 0.022;
    final scaleY = 1 + breath * squash;

    // Cheering adds a hop, so the whole pet leaves the baseline rather than
    // just inflating in place.
    final hop = mood == MascotMood.cheering
        ? -math.max(0.0, math.sin(t * 4 * math.pi)) * h * 0.05
        : 0.0;

    canvas.save();
    canvas.translate(w / 2, h + hop);
    canvas.scale(1, scaleY);
    canvas.translate(-w / 2, -h);

    final bodyRect = Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.76, h * 0.7);

    _paintEars(canvas, bodyRect, w, h);

    // Body: a rounded pebble, lit from the top-left like every other surface
    // in the app so the pet belongs to the same world as the cards.
    final bodyPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          bodyRect,
          topLeft: Radius.circular(w * 0.38),
          topRight: Radius.circular(w * 0.38),
          bottomLeft: Radius.circular(w * 0.3),
          bottomRight: Radius.circular(w * 0.3),
        ),
      );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [body, Color.lerp(body, bodyShade, 0.55)!],
        ).createShader(bodyRect),
    );

    _paintFace(canvas, bodyRect, w, h);
    canvas.restore();
  }

  void _paintEars(Canvas canvas, Rect bodyRect, double w, double h) {
    // Ears perk up while a step is running and flop while resting — the
    // cheapest possible read on "is something happening right now".
    final perk = switch (mood) {
      MascotMood.focused => 1.0,
      MascotMood.cheering => 0.9,
      MascotMood.idle => 0.75,
      MascotMood.resting => 0.35,
    };
    final earPaint = Paint()..color = Color.lerp(body, bodyShade, 0.25)!;
    final earHeight = h * 0.28 * perk;

    for (final dx in [-1.0, 1.0]) {
      final cx = bodyRect.center.dx + dx * bodyRect.width * 0.28;
      final top = bodyRect.top - earHeight + h * 0.03;
      canvas.drawPath(
        Path()
          ..moveTo(cx - w * 0.09, bodyRect.top + h * 0.04)
          ..quadraticBezierTo(cx + dx * w * 0.02, top, cx + w * 0.09,
              bodyRect.top + h * 0.04)
          ..close(),
        earPaint,
      );
    }
  }

  void _paintFace(Canvas canvas, Rect bodyRect, double w, double h) {
    final eyeY = bodyRect.top + bodyRect.height * 0.36;
    final eyeDx = bodyRect.width * 0.2;
    final eyeR = w * 0.05;
    final inkPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    final inkFill = Paint()..color = ink;

    // A blink is a brief window at the end of the cycle, not a separate
    // rhythm. `resting` skips it because those eyes are already shut.
    final blinking = mood != MascotMood.resting && t > 0.92 && t < 0.97;
    final happyEyes = mood == MascotMood.cheering;
    final closedEyes = mood == MascotMood.resting || blinking;

    for (final dx in [-1.0, 1.0]) {
      final cx = bodyRect.center.dx + dx * eyeDx;
      if (closedEyes) {
        // A downward arc: a closed eye, not a dash.
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, eyeY),
            width: eyeR * 2.6,
            height: eyeR * 1.8,
          ),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          inkPaint,
        );
      } else if (happyEyes) {
        // The same arc flipped — the universal "^^" of a delighted face.
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, eyeY + eyeR * 0.5),
            width: eyeR * 2.6,
            height: eyeR * 2.0,
          ),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          inkPaint,
        );
      } else {
        canvas.drawCircle(Offset(cx, eyeY), eyeR, inkFill);
        // A single off-centre catchlight. Without it the eyes read as holes.
        canvas.drawCircle(
          Offset(cx - eyeR * 0.3, eyeY - eyeR * 0.35),
          eyeR * 0.32,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dx * eyeR * 1.9, eyeY + eyeR * 1.9),
          width: eyeR * 1.9,
          height: eyeR * 1.1,
        ),
        Paint()..color = blush.withValues(alpha: 0.22),
      );
    }

    // Mouth. Only `cheering` opens it; the rest keep a small closed curve, so
    // the difference between "working" and "done" is legible at a glance.
    final mouthY = eyeY + h * 0.11;
    if (mood == MascotMood.cheering) {
      canvas.drawPath(
        Path()
          ..moveTo(bodyRect.center.dx - w * 0.055, mouthY)
          ..quadraticBezierTo(
            bodyRect.center.dx,
            mouthY + h * 0.075,
            bodyRect.center.dx + w * 0.055,
            mouthY,
          )
          ..close(),
        inkFill,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(bodyRect.center.dx, mouthY),
          width: w * 0.1,
          height: h * 0.05,
        ),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        inkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.t != t ||
      old.mood != mood ||
      old.body != body ||
      old.bodyShade != bodyShade ||
      old.ink != ink ||
      old.blush != blush;
}
