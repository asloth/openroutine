import 'package:flutter/material.dart';

import 'soft_circle_button.dart';

/// The back control every screen with an `AppBar` uses: a 48px
/// [SoftCircleButton] with the chevron-left glyph, in place of the stock
/// Material back arrow. `AppBar`'s automatic leading paints a plain `←`,
/// which is the mismatch this fixes — the redesigned screens (routine
/// detail, timer, home) already use `SoftCircleButton` for back, and the
/// screens still on a stock `AppBar` are the odd ones out.
///
/// [onPressed] defaults to [Navigator.maybePop], the same behavior the stock
/// back button uses, which go_router respects.
class SoftBackButton extends StatelessWidget {
  const SoftBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  /// The `AppBar.leadingWidth` that pairs with [asAppBarLeading]: the
  /// button's own 48px plus the 16px inset from the left edge.
  static const double appBarLeadingWidth = 64;

  /// The standard placement for a [SoftBackButton] as an `AppBar`'s
  /// `leading`: 16px from the left edge, vertically centered in the
  /// toolbar. Pair with [appBarLeadingWidth] as the `AppBar`'s
  /// `leadingWidth`, or the button crowds the title.
  static Widget asAppBarLeading({VoidCallback? onPressed}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: SoftBackButton(onPressed: onPressed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftCircleButton(
      icon: Icons.chevron_left,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
