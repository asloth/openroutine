import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// One entry in a [FloatingNavBar]: the outlined and filled icon pair and the
/// label a destination carries.
@immutable
class FloatingNavDestination {
  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Shown when this destination isn't the one selected.
  final IconData icon;

  /// Shown when this destination is selected.
  final IconData selectedIcon;

  final String label;
}

/// The floating pill that replaces the stock `NavigationBar` under the
/// "tinted paper" direction: a flat, bordered pill centered above the bottom
/// safe area, rather than a full-width Material bar. No shadow — depth comes
/// from the border and the fill behind the selected destination, the same
/// idiom `app/lib/widgets/tinted/` uses elsewhere.
///
/// This widget doesn't route anything itself; a caller supplies
/// [currentIndex] and reacts to [onDestinationSelected], the same shape
/// `NavigationBar` uses.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final List<FloatingNavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  /// Identifies the pill itself (the bordered, filled shape), separately from
  /// the margin around it — so a caller measuring "the pill's height" isn't
  /// also measuring the gap above the safe area.
  static const pillKey = Key('floatingNavBarPill');

  static const _pillPadding = 5.0;
  static const _gap = 4.0;
  static const _bottomGap = 16.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: _bottomGap + bottomInset),
          child: DecoratedBox(
            key: pillKey,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: AppRadius.pillBorder,
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_pillPadding),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    _Destination(
                      destination: destinations[i],
                      selected: i == currentIndex,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const _iconSize = 22.0;

  /// The label never grows past this scale, even at a large system text
  /// scale.
  ///
  /// Material's own `NavigationBar` clamps its labels at 1.3x. This bar
  /// deliberately allows more growth than that — but with icon above label
  /// rather than side by side, and with two locale strings that both have to
  /// fit next to each other (`Estadísticas` is the long one), letting the
  /// label grow all the way to a 2.0x system scale would widen the pill past
  /// a 360px phone's screen. 1.6x is the floor this change's brief allows,
  /// and it's already more headroom than Material's own bar gives its
  /// labels; past it, staying legible and on-screen matters more than
  /// continuing to track the system scale exactly.
  static const _labelScaleCap = 1.6;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: ConstrainedBox(
        // `maxWidth` is what keeps a long label from pushing the pill past
        // the screen edge once [_labelScaleCap] has done what it can: past
        // this width the label wraps onto a second line instead, the same
        // trade `PageHeader` makes for its title at a large text scale.
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTargetMin,
          minHeight: AppSpacing.touchTargetMin,
          maxWidth: 140,
        ),
        child: AnimatedContainer(
          duration: context.motion(AppMotion.standard),
          curve: AppMotion.transition,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: AppRadius.pillBorder,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.pillBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: _iconSize,
                      color: foreground,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.label,
                      textScaler: MediaQuery.textScalerOf(
                        context,
                      ).clamp(maxScaleFactor: _labelScaleCap),
                      style: TextStyle(
                        fontFamily: AppTypography.display,
                        fontSize: 12,
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
