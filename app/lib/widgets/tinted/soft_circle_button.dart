import 'package:flutter/material.dart';

import '../../theme/motion.dart';

/// [SoftCircleButton]'s two fill/icon-color pairings.
enum SoftCircleButtonStyle {
  /// The default: a neutral surface tint, for a circular control that isn't
  /// the primary action on its row.
  neutral,

  /// A primary-container tint, for the one circular control that carries the
  /// main action.
  accent,
}

/// A flat circular control — the tinted-paper redesign's replacement for
/// `NeumorphicCircleButton`. Same job (an icon button that visibly depresses
/// while held), no shadow.
class SoftCircleButton extends StatefulWidget {
  const SoftCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48,
    this.style = SoftCircleButtonStyle.neutral,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 48 or 64. Below 48 the control would fall under the app's hit-target
  /// floor, so nothing calls for a smaller size.
  final double size;

  final SoftCircleButtonStyle style;

  @override
  State<SoftCircleButton> createState() => _SoftCircleButtonState();
}

class _SoftCircleButtonState extends State<SoftCircleButton> {
  static const _pressScale = 0.98;

  bool _held = false;

  void _setHeld(bool value) {
    if (_held == value) return;
    setState(() => _held = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final Color fill;
    final Color iconColor;
    switch (widget.style) {
      case SoftCircleButtonStyle.neutral:
        fill = colorScheme.surfaceContainer;
        iconColor = colorScheme.onSurface;
      case SoftCircleButtonStyle.accent:
        fill = colorScheme.primaryContainer;
        iconColor = colorScheme.onPrimaryContainer;
    }

    final iconSize = widget.size >= 64 ? 24.0 : 22.0;

    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        scale: _held ? _pressScale : 1.0,
        duration: context.motion(AppMotion.feedback),
        curve: AppMotion.transition,
        child: Material(
          color: fill,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: InkWell(
              onTap: widget.onPressed,
              onHighlightChanged: enabled ? _setHeld : null,
              customBorder: const CircleBorder(),
              child: Icon(
                widget.icon,
                size: iconSize,
                color: enabled ? iconColor : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
