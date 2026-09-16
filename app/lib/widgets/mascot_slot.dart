import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
// Rive ships its own renderer types; the stand-in painter below wants
// Flutter's.
import 'package:rive/rive.dart' hide PaintingStyle;

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

class _MascotSlotState extends State<MascotSlot> {
  /// How long the pet moves on arrival before it settles into a still pose.
  /// Perpetual motion in the corner of the eye is the kind of competing
  /// stimulus this app exists to remove — see the note on [MascotSlot].
  static const _warmUp = Duration(seconds: 11);

  /// Loaded here rather than by `RiveWidgetBuilder` so a missing
  /// `rive_native` library lands in [_load]'s catch instead of escaping as an
  /// unhandled async error on any platform where the runtime is unavailable.
  late final Future<File?> _file = _load();

  RiveWidgetController? _controller;
  ViewModelInstance? _mascot;
  Timer? _settle;

  /// `flutter test` has the `rive_native` library but no renderer, and
  /// loading a file there trips a native assertion that aborts the whole test
  /// process — no Dart `catch` can stop it. So widget tests get the stand-in.
  static final _riveAvailable = !Platform.environment.containsKey(
    'FLUTTER_TEST',
  );

  Future<File?> _load() async {
    if (!_riveAvailable) return null;
    try {
      return await File.asset('assets/mascot.riv', riveFactory: Factory.rive);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    _file.then((file) => file?.dispose());
    super.dispose();
  }

  void _onLoaded(RiveLoaded loaded) {
    _controller = loaded.controller
      ..fit = Fit.contain
      // The pet's own listeners react to a press, so the artboard has to see
      // the pointer rather than letting it fall through to the screen.
      ..hitTestBehavior = RiveHitTestBehavior.opaque;
    _mascot = loaded.viewModelInstance;
    _apply();
    _restAfterWarmUp();
    // A slot that arrives already cheering, like the finished timer, never
    // sees a mood change, so it celebrates here instead.
    if (widget.mood == MascotMood.cheering) {
      _mascot?.trigger('celebrate')?.trigger();
    }
  }

  /// Stops advancing once the warm-up is over, and does not start at all when
  /// the system asks for reduced motion.
  void _restAfterWarmUp() {
    _settle?.cancel();
    final controller = _controller;
    if (controller == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.active = false;
      return;
    }
    controller.active = true;
    _settle = Timer(_warmUp, () {
      if (mounted) _controller?.active = false;
    });
  }

  /// Pushes the mood and the theme's colours into the artboard. Cheap enough
  /// to run on every build, which is what keeps the pet in step with a palette
  /// change or a mood change without a separate listener.
  void _apply() {
    final mascot = _mascot;
    if (mascot == null) return;

    final colours =
        Theme.of(context).extension<MascotPalette>() ??
        Palette.defaultPalette.mascot;
    mascot.color('bodyColor')?.value = colours.body;
    mascot.color('inkColor')?.value = colours.ink;
    // Thought dots and Z's float outside the pet, so they contrast with the
    // screen behind it rather than with its fur.
    mascot.color('accentColor')?.value = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant;

    mascot.boolean('isThinking')?.value = widget.mood == MascotMood.focused;
    mascot.boolean('isSleeping')?.value = widget.mood == MascotMood.resting;
  }

  @override
  void didUpdateWidget(MascotSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood == widget.mood) return;
    _apply();
    // A mood change is worth moving for, even if the pet had already settled.
    _wake();
    if (widget.mood == MascotMood.cheering) {
      _mascot?.trigger('celebrate')?.trigger();
    }
  }

  /// Runs again for another warm-up, so a settled pet still reacts.
  void _wake() {
    _controller?.active = true;
    _restAfterWarmUp();
  }

  @override
  Widget build(BuildContext context) {
    final pet = RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<File?>(
          future: _file,
          builder: (context, snapshot) {
            final file = snapshot.data;
            // Until the file is ready — and if it never loads — the
            // hand-drawn stand-in keeps the slot filled rather than punching
            // a hole in the layout.
            if (file == null) {
              return _MascotPlaceholder(mood: widget.mood, size: widget.size);
            }
            return RiveWidgetBuilder(
              fileLoader: FileLoader.fromFile(file, riveFactory: Factory.rive),
              dataBind: DataBind.auto(),
              onLoaded: _onLoaded,
              builder: (context, state) => switch (state) {
                RiveLoaded(:final controller) => Listener(
                  // The artboard's own listener fires `tap`, but a settled pet
                  // is not advancing and so never sees it. Waking it here is
                  // what makes a poke work at any moment.
                  onPointerDown: (_) => _wake(),
                  child: RiveWidget(controller: controller),
                ),
                _ => _MascotPlaceholder(mood: widget.mood, size: widget.size),
              },
            );
          },
        ),
      ),
    );

    final label = widget.semanticLabel;
    return label == null
        ? ExcludeSemantics(child: pet)
        : Semantics(label: label, image: true, child: pet);
  }
}

/// The pre-Rive drawing, kept as the fallback for the moments before the file
/// loads and for any platform where it cannot.
class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder({required this.mood, required this.size});

  final MascotMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colours =
        Theme.of(context).extension<MascotPalette>() ??
        Palette.defaultPalette.mascot;
    return CustomPaint(
      size: Size(size, size),
      painter: _MascotPainter(
        mood: mood,
        t: 0,
        body: colours.body,
        bodyShade: colours.bodyShade,
        ink: colours.ink,
        blush: colours.blush,
      ),
    );
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
          ..quadraticBezierTo(
            cx + dx * w * 0.02,
            top,
            cx + w * 0.09,
            bodyRect.top + h * 0.04,
          )
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
