import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/spacing.dart';

/// A flat, tinted surface — the tinted-paper redesign's replacement for
/// `NeumorphicCard`. No shadow: depth comes from color contrast against the
/// screen behind it, not from a shadow pair, so a caller supplies both the
/// fill and the foreground rather than the card guessing at either.
class TintedCard extends StatefulWidget {
  const TintedCard({
    super.key,
    required this.child,
    required this.color,
    required this.foregroundColor,
    this.borderRadius = AppRadius.tintedBorder,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 18),
    this.onTap,
  });

  final Widget child;

  /// The card's fill.
  final Color color;

  /// Applied to descendant text and icons, so a caller doesn't restyle each
  /// child by hand.
  final Color foregroundColor;

  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// When set, the card responds to a tap with an ink splash and a small
  /// press deform, and reports itself as a button. Left unset, the card is
  /// inert — a plain grouping surface with no button semantics.
  final VoidCallback? onTap;

  @override
  State<TintedCard> createState() => _TintedCardState();
}

class _TintedCardState extends State<TintedCard> {
  static const _pressScale = 0.98;

  bool _held = false;

  void _setHeld(bool value) {
    if (_held == value) return;
    setState(() => _held = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = DefaultTextStyle.merge(
      style: TextStyle(color: widget.foregroundColor),
      child: IconTheme.merge(
        data: IconThemeData(color: widget.foregroundColor),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    final surface = Material(
      type: MaterialType.canvas,
      color: widget.color,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: widget.onTap == null
          ? content
          : InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setHeld,
              child: content,
            ),
    );

    final scaled = AnimatedScale(
      scale: _held ? _pressScale : 1.0,
      duration: context.motion(AppMotion.feedback),
      curve: AppMotion.transition,
      child: surface,
    );

    if (widget.onTap == null) return scaled;

    return Semantics(button: true, child: scaled);
  }
}
