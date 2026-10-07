import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A one-shot handful of confetti that pops up out of its child's center,
/// arcs, and drifts down. It plays once when it mounts and then gets out of
/// the way: it never loops, never takes a tap, and paints nothing once it's
/// done.
///
/// The pieces come in the palette's own colours, so the party follows
/// whichever accent is active rather than bringing a rainbow of its own.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.child,
    this.pieces = 56,
    this.duration = const Duration(milliseconds: 2600),
    this.seed = 7,
  });

  final Widget child;
  final int pieces;
  final Duration duration;

  /// Fixes the scatter so the burst looks the same every time it plays.
  final int seed;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final List<_Piece> _pieces = _scatter(
    math.Random(widget.seed),
    widget.pieces,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colours = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
    ];
    return CustomPaint(
      foregroundPainter: _ConfettiPainter(
        progress: _controller,
        pieces: _pieces,
        colours: colours,
        seconds: widget.duration.inMilliseconds / 1000,
      ),
      child: widget.child,
    );
  }
}

/// One scrap of paper: where it's headed, how it spins, and what it looks
/// like. Velocities are in logical pixels per second.
class _Piece {
  const _Piece({
    required this.vx,
    required this.vy,
    required this.spin,
    required this.turn,
    required this.width,
    required this.height,
    required this.round,
    required this.colour,
  });

  final double vx;
  final double vy;
  final double spin;
  final double turn;
  final double width;
  final double height;
  final bool round;
  final int colour;
}

List<_Piece> _scatter(math.Random random, int count) {
  double between(double a, double b) => a + random.nextDouble() * (b - a);
  return List.generate(count, (i) {
    // Mostly upward, fanned from about 20 degrees above either horizon.
    final angle = between(-math.pi + 0.35, -0.35);
    final speed = between(260, 640);
    final round = random.nextDouble() < 0.3;
    final size = between(6, 10);
    return _Piece(
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed,
      spin: between(-9, 9),
      turn: between(0, math.pi),
      width: size,
      height: round ? size : size * between(0.4, 0.6),
      round: round,
      colour: i,
    );
  });
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.pieces,
    required this.colours,
    required this.seconds,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<_Piece> pieces;
  final List<Color> colours;
  final double seconds;

  static const _gravity = 900.0;

  /// Air resistance, so pieces float down rather than drop like stones.
  static const _drag = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value;
    if (p == 0 || p == 1) return;
    final t = p * seconds;
    // Ease into the burst's last third, so it fades instead of vanishing.
    final opacity = p < 0.66 ? 1.0 : (1 - p) / 0.34;
    final origin = size.center(Offset.zero);
    final slowed = (1 - math.exp(-_drag * t)) / _drag;
    final fall = _gravity / _drag * (t - slowed);
    final paint = Paint();
    for (final piece in pieces) {
      final at = origin + Offset(piece.vx * slowed, piece.vy * slowed + fall);
      paint.color = colours[piece.colour % colours.length].withValues(
        alpha: opacity,
      );
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(piece.turn + piece.spin * t);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.width,
        // A flat scrap flips as it tumbles; a round one stays round.
        height: piece.round
            ? piece.height
            : piece.height * math.cos(piece.spin * t * 0.7).abs().clamp(0.2, 1),
      );
      if (piece.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || !listEquals(oldDelegate.colours, colours);
}
