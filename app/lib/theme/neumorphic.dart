import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

/// The soft-UI surface treatment from the Stitch design pass.
///
/// Every neumorphic surface is the same trick: one shadow down-right where
/// light falls away, one up-left where it catches. Raised surfaces cast them
/// outward, pressed ones inward, which is what makes a control feel physically
/// depressed when tapped.
///
/// Exposed as a [ThemeExtension] rather than bare constants so the shadow pair
/// flips with brightness — the light-mode highlight is pure white, which would
/// glare against a dark surface — and so widgets keep reading from the theme
/// instead of importing colours directly.
@immutable
class NeumorphicTheme extends ThemeExtension<NeumorphicTheme> {
  const NeumorphicTheme({
    required this.shadowColor,
    required this.highlightColor,
    required this.surfaceColor,
  });

  final Color shadowColor;
  final Color highlightColor;

  /// Neumorphism only reads if the surface sits *between* its two shadows.
  /// A card painted a different colour from the background flattens instantly,
  /// which is why this is part of the token rather than left to call sites.
  final Color surfaceColor;

  static const light = NeumorphicTheme(
    shadowColor: AppColors.neumorphicShadow,
    highlightColor: AppColors.neumorphicHighlight,
    surfaceColor: AppColors.surface,
  );

  static final dark = NeumorphicTheme(
    shadowColor: AppColors.neumorphicShadowDark,
    highlightColor: AppColors.neumorphicHighlightDark,
    surfaceColor: AppColors.dark.surface,
  );

  /// A raised surface — cards, unpressed controls.
  ///
  /// [scale] widens the offsets for large elements: the design pass uses 5/10
  /// for cards and 8/16 for the big timer ring, which is the same shadow
  /// relationship at a larger radius.
  BoxDecoration raised({
    BorderRadius? borderRadius,
    BoxShape shape = BoxShape.rectangle,
    Color? color,
    double scale = 1,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: shape == BoxShape.circle ? null : borderRadius ?? AppRadius.cardBorder,
      shape: shape,
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: Offset(5 * scale, 5 * scale),
          blurRadius: 10 * scale,
        ),
        BoxShadow(
          color: highlightColor,
          offset: Offset(-5 * scale, -5 * scale),
          blurRadius: 10 * scale,
        ),
      ],
    );
  }

  /// A recessed well — the inside of the timer ring, input fields, the
  /// pressed state of a raised control.
  ///
  /// Flutter has no inset box-shadow, so this is approximated with an inner
  /// gradient running highlight-to-shadow along the same diagonal. Close
  /// enough at these radii, and it avoids a custom painter on every field.
  BoxDecoration pressed({
    BorderRadius? borderRadius,
    BoxShape shape = BoxShape.rectangle,
    Color? color,
  }) {
    final base = color ?? surfaceColor;
    return BoxDecoration(
      borderRadius: shape == BoxShape.circle ? null : borderRadius ?? AppRadius.cardBorder,
      shape: shape,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(shadowColor.withValues(alpha: 0.55), base),
          base,
          Color.alphaBlend(highlightColor.withValues(alpha: 0.75), base),
        ],
        stops: const [0, 0.5, 1],
      ),
    );
  }

  @override
  NeumorphicTheme copyWith({
    Color? shadowColor,
    Color? highlightColor,
    Color? surfaceColor,
  }) {
    return NeumorphicTheme(
      shadowColor: shadowColor ?? this.shadowColor,
      highlightColor: highlightColor ?? this.highlightColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
    );
  }

  @override
  NeumorphicTheme lerp(NeumorphicTheme? other, double t) {
    if (other == null) return this;
    return NeumorphicTheme(
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
    );
  }
}

/// Convenience accessor so screens read `context.neumorphic.raised()` rather
/// than spelling out the extension lookup every time.
extension NeumorphicContext on BuildContext {
  NeumorphicTheme get neumorphic =>
      Theme.of(this).extension<NeumorphicTheme>() ?? NeumorphicTheme.light;
}

/// A raised card. The default container for grouped content, replacing
/// Material's elevation-and-tint `Card` so surfaces stay consistent.
class NeumorphicCard extends StatelessWidget {
  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.element),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: context.neumorphic.raised(),
      child: Padding(padding: padding, child: child),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: AppRadius.cardBorder,
              child: content,
            ),
    );
  }
}

/// A circular neumorphic control that visibly depresses while held. The press
/// state is the whole point of the idiom, so it lives in the widget rather
/// than being left to each call site to remember.
class NeumorphicCircleButton extends StatefulWidget {
  const NeumorphicCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 64,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  /// Filled controls use the primary colour and read as the main action —
  /// the play/pause button in the middle of the timer's control row.
  final bool filled;

  @override
  State<NeumorphicCircleButton> createState() => _NeumorphicCircleButtonState();
}

class _NeumorphicCircleButtonState extends State<NeumorphicCircleButton> {
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neumorphic = context.neumorphic;
    final enabled = widget.onPressed != null;

    final foreground = !enabled
        ? theme.disabledColor
        : widget.filled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _held = true) : null,
        onTapUp: enabled ? (_) => setState(() => _held = false) : null,
        onTapCancel: enabled ? () => setState(() => _held = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          decoration: _held
              ? neumorphic.pressed(
                  shape: BoxShape.circle,
                  color: widget.filled ? theme.colorScheme.primary : null,
                )
              : neumorphic.raised(
                  shape: BoxShape.circle,
                  scale: widget.size >= 88 ? 1.6 : 1,
                  color: widget.filled ? theme.colorScheme.primary : null,
                ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.45,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// A full-width pill action. Used for the timer's secondary actions, where a
/// filled button would compete with the primary one.
class NeumorphicPillButton extends StatefulWidget {
  const NeumorphicPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? foregroundColor;

  @override
  State<NeumorphicPillButton> createState() => _NeumorphicPillButtonState();
}

class _NeumorphicPillButtonState extends State<NeumorphicPillButton> {
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null;
    final foreground = enabled
        ? widget.foregroundColor ?? theme.colorScheme.primary
        : theme.disabledColor;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _held = true) : null,
      onTapUp: enabled ? (_) => setState(() => _held = false) : null,
      onTapCancel: enabled ? () => setState(() => _held = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(
          minHeight: AppSpacing.touchTargetMin,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.section,
          vertical: AppSpacing.element,
        ),
        decoration: _held
            ? context.neumorphic.pressed(borderRadius: AppRadius.pillBorder)
            : context.neumorphic.raised(borderRadius: AppRadius.pillBorder),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 20, color: foreground),
            const SizedBox(width: AppSpacing.base),
            Text(
              widget.label,
              style: theme.textTheme.labelLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
