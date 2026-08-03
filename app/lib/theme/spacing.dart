import 'package:flutter/widgets.dart';

/// The spacing scale from the Stitch design pass. Screens should reach for
/// these rather than inventing an `EdgeInsets.all(16)` each time — the whole
/// point of a scale is that a reviewer can tell a deliberate gap from a
/// typo-sized one.
abstract final class AppSpacing {
  /// The unit everything else is a multiple of.
  static const base = 8.0;

  /// Between siblings inside a group — a label and its field, two chips.
  static const element = 16.0;

  /// Screen edges.
  static const container = 24.0;

  /// Between sections that aren't related to each other.
  static const section = 32.0;

  /// Minimum tap target, per the design pass and Material's own guidance.
  /// Anything interactive smaller than this is a bug, not a style choice.
  static const touchTargetMin = 48.0;

  static const allContainer = EdgeInsets.all(container);
  static const horizontalContainer = EdgeInsets.symmetric(
    horizontal: container,
  );

  static const gapBase = SizedBox(height: base);
  static const gapElement = SizedBox(height: element);
  static const gapContainer = SizedBox(height: container);
  static const gapSection = SizedBox(height: section);
}

/// Corner radii. `card` is the one to reach for by default; `pill` is for
/// anything that reads as an action.
abstract final class AppRadius {
  static const small = 4.0;
  static const medium = 8.0;
  static const card = 12.0;
  static const pill = 9999.0;

  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const mediumBorder = BorderRadius.all(Radius.circular(medium));
  static const pillBorder = BorderRadius.all(Radius.circular(pill));
}
