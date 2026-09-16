import 'package:flutter/material.dart';

import '../../../theme/typography.dart';

/// The home redesign's colours, read from the palette's roles rather than the
/// design file's green, so home follows whichever palette and brightness is
/// active.
class HomeInk {
  HomeInk.of(BuildContext context) : scheme = Theme.of(context).colorScheme;

  final ColorScheme scheme;

  Color get ink => scheme.onSurface;

  /// Secondary text, from 0.35 for the quietest labels to 0.62 for prose.
  Color muted(double alpha) => scheme.onSurface.withValues(alpha: alpha);

  /// White cards sitting on the paper.
  Color get card => scheme.surfaceContainerLowest;

  /// The hairline around a card.
  Color get hairline => scheme.onSurface.withValues(alpha: 0.07);

  /// Dots, filled pips, and highlighted borders.
  Color get accent => scheme.primary;

  /// Solid actions: Start and Add a routine.
  Color get action => scheme.primary;
  Color get onAction => scheme.onPrimary;

  static const label = TextStyle(
    fontFamily: AppTypography.body,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );

  static const title = TextStyle(
    fontFamily: AppTypography.body,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  static const detail = TextStyle(fontFamily: AppTypography.body, fontSize: 13);
}

/// A solid, compact action in the palette's primary colour, at least 48px
/// tall so it clears the touch-target floor.
class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Material(
      color: ink.action,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: HomeInk.label.copyWith(
                  fontSize: 13.5,
                  color: ink.onAction,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
