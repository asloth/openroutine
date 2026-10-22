import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
// Rive ships its own renderer types; the stand-in painter below wants
// Flutter's.
import 'package:rive/rive.dart' hide PaintingStyle;

import '../theme/palette.dart';

/// What a [MascotSlot] should paint at a given point in loading the Rive
/// file, or the state machine inside it: nothing yet while a step is still in
/// flight, the hand-drawn stand-in when there's no pet to show at all, or the
/// real thing once it's ready.
@visibleForTesting
enum MascotSlotVisual { empty, placeholder, rive }

/// Maps a [FutureBuilder]'s snapshot of the shared Rive file onto what to
/// show while it's in flight. Staying empty while it loads is what keeps the
/// old placeholder from flashing on screen before the real pet takes over;
/// landing on `null` — because Rive is unavailable, or the file failed to
/// decode — falls back to the placeholder.
@visibleForTesting
MascotSlotVisual mascotLoadVisual<T>(AsyncSnapshot<T?> snapshot) {
  if (snapshot.connectionState != ConnectionState.done) {
    return MascotSlotVisual.empty;
  }
  return snapshot.data == null
      ? MascotSlotVisual.placeholder
      : MascotSlotVisual.rive;
}

/// The same idea for the state machine's own loading stage, once the file
/// itself is ready.
@visibleForTesting
MascotSlotVisual mascotRiveVisual(RiveState state) => switch (state) {
  RiveLoading() => MascotSlotVisual.empty,
  RiveFailed() => MascotSlotVisual.placeholder,
  RiveLoaded() => MascotSlotVisual.rive,
};

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

/// A one-time move the pet plays in response to something the user just did.
enum MascotReaction {
  /// A mini cheer: a small hop with one arm up. A step was marked done.
  stepDone('stepDone'),

  /// An okay nod. A step was skipped, and that's fine.
  skip('skip'),

  /// A wave. A step was put off until the end of the run, or a hello.
  wave('wave'),

  /// Feet out and a jogging stride on the spot. Move the slot to make it
  /// travel.
  run('run'),

  /// A crouch and a leap with both arms up.
  jump('jump'),

  /// A few soft, content hops with the feet tucked.
  bounce('bounce'),

  /// Both arms up, feet out: something big just got done.
  celebrate('celebrate'),

  /// A slow sip from the coffee, eye closed. Only plays while the pet holds
  /// one (see [MascotSlot.hasCoffee]).
  sip('sip');

  const MascotReaction(this.trigger);

  /// The trigger on the Rive file's `Mascot` view model.
  final String trigger;
}

/// One request to play a [MascotReaction].
///
/// Compared by identity, not value: doing the same thing twice in a row is two
/// cues, and the pet should react to both. Build a new one per event.
class MascotCue {
  MascotCue(this.reaction);

  final MascotReaction reaction;
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
/// The pet keeps moving for as long as it's on screen. Pausing it after a
/// warm-up froze it on whatever frame was showing, sometimes mid-blink, which
/// read as a stuck app rather than a calm one. Reduce-motion holds it still.
class MascotSlot extends StatefulWidget {
  const MascotSlot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 120,
    this.semanticLabel,
    this.cue,
    this.hasCoffee = false,
  });

  final MascotMood mood;

  /// Holds a cup of coffee, for a long stretch of work. The pet brings the
  /// mug up and holds it still; a [MascotReaction.sip] cue takes a sip.
  final bool hasCoffee;

  /// Plays once each time a new cue arrives. Null means nothing to react to.
  final MascotCue? cue;
  final double size;
  final String? semanticLabel;

  /// Test-only: swaps out the loader behind the shared, once-per-run Rive
  /// file future, and clears whatever's already cached, so a widget test can
  /// hold the "still loading" state open (with a [Completer] that never
  /// completes), force a resolved-with-no-file outcome, or count how many
  /// times the loader itself actually runs. Pass `null` to restore the real
  /// loader.
  @visibleForTesting
  static set debugFileLoader(Future<File?> Function()? loader) {
    _MascotSlotState._debugFileLoader = loader;
    _MascotSlotState._sharedFile = null;
  }

  @override
  State<MascotSlot> createState() => _MascotSlotState();
}

class _MascotSlotState extends State<MascotSlot> {
  /// The decoded Rive file, loaded at most once per app run and shared by
  /// every slot. Decoding the `.riv` is slow enough to see on a phone, so
  /// only the first slot built pays that cost; every slot after — including
  /// the one on the very next screen — reuses the same result instead of
  /// repeating the delay. Loaded here rather than by `RiveWidgetBuilder` so a
  /// missing `rive_native` library lands in [_load]'s catch instead of
  /// escaping as an unhandled async error on any platform where the runtime
  /// is unavailable.
  static Future<File?>? _sharedFile;

  /// Test-only substitute for [_load]. See [MascotSlot.debugFileLoader].
  static Future<File?> Function()? _debugFileLoader;

  Future<File?> get _file => _sharedFile ??= (_debugFileLoader ?? _load)();

  /// Made once per file and reused. `RiveWidgetBuilder` compares loaders by
  /// identity, so a fresh one on every build reloads the artboard from
  /// scratch: a new state machine and view model each time. The running
  /// timer rebuilds every second, which kept resetting the pet to the start
  /// of idle and threw away every reaction fired at the old instance.
  FileLoader? _loader;

  RiveWidgetController? _controller;
  ViewModelInstance? _mascot;

  /// `flutter test` has the `rive_native` library but no renderer, and
  /// loading a file there trips a native assertion that aborts the whole test
  /// process — no Dart `catch` can stop it. So widget tests get the stand-in.
  static final _riveAvailable = !Platform.environment.containsKey(
    'FLUTTER_TEST',
  );

  static Future<File?> _load() async {
    if (!_riveAvailable) return null;
    try {
      return await File.asset('assets/mascot.riv', riveFactory: Factory.rive);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    // The file is shared across every slot in the app, so disposing it here
    // would pull it out from under every other slot still using it.
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
    // Reduce-motion holds the pet still; otherwise it never stops.
    _controller!.active = !MediaQuery.disableAnimationsOf(context);
    // A slot that arrives already cheering, like the finished timer, never
    // sees a mood change, so it celebrates here instead.
    if (widget.mood == MascotMood.cheering) {
      _mascot?.trigger('celebrate')?.trigger();
    }
  }

  /// Pushes the mood and the theme's colours into the artboard. Cheap enough
  /// to run on every build, which is what keeps the pet in step with a palette
  /// change or a mood change without a separate listener.
  void _apply() {
    final mascot = _mascot;
    if (mascot == null) return;

    final colours =
        Theme.of(context).extension<MascotPalette>() ??
        Palette.defaultAccent.mascot;
    mascot.color('bodyColor')?.value = colours.body;
    mascot.color('inkColor')?.value = colours.ink;
    // Thought dots and Z's float outside the pet, so they contrast with the
    // screen behind it rather than with its fur.
    mascot.color('accentColor')?.value = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant;

    mascot.boolean('isThinking')?.value = widget.mood == MascotMood.focused;
    mascot.boolean('isSleeping')?.value = widget.mood == MascotMood.resting;
    mascot.boolean('hasCoffee')?.value = widget.hasCoffee;
  }

  @override
  void didUpdateWidget(MascotSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cue = widget.cue;
    if (cue != null && !identical(cue, oldWidget.cue)) {
      _mascot?.trigger(cue.reaction.trigger)?.trigger();
    }
    if (oldWidget.mood == widget.mood &&
        oldWidget.hasCoffee == widget.hasCoffee) {
      return;
    }
    _apply();
    if (widget.mood == MascotMood.cheering && oldWidget.mood != widget.mood) {
      _mascot?.trigger('celebrate')?.trigger();
    }
  }

  /// Renders an empty box or the placeholder for any [MascotSlotVisual] other
  /// than `rive`, which the caller builds for itself since it needs data
  /// (the loaded file, or the live controller) this widget doesn't have.
  Widget _visual(MascotSlotVisual visual, Widget Function() rive) =>
      switch (visual) {
        MascotSlotVisual.empty => SizedBox(
          width: widget.size,
          height: widget.size,
        ),
        MascotSlotVisual.placeholder => _MascotPlaceholder(
          mood: widget.mood,
          size: widget.size,
        ),
        MascotSlotVisual.rive => rive(),
      };

  @override
  Widget build(BuildContext context) {
    final pet = RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<File?>(
          future: _file,
          builder: (context, snapshot) => _visual(
            mascotLoadVisual(snapshot),
            () => RiveWidgetBuilder(
              fileLoader: _loader ??= FileLoader.fromFile(
                snapshot.data!,
                riveFactory: Factory.rive,
              ),
              dataBind: DataBind.auto(),
              onLoaded: _onLoaded,
              builder: (context, state) => _visual(
                mascotRiveVisual(state),
                () => RiveWidget(controller: (state as RiveLoaded).controller),
              ),
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

/// The pre-Rive drawing, kept as the fallback for when there's no pet to show
/// at all: no renderer under `flutter test`, or the file failed to decode.
/// While the shared file — or the state machine inside it — is still
/// loading, the slot stays empty instead, so the placeholder never flashes
/// in front of the real pet.
class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder({required this.mood, required this.size});

  final MascotMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colours =
        Theme.of(context).extension<MascotPalette>() ??
        Palette.defaultAccent.mascot;
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
