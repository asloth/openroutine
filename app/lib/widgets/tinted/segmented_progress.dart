import 'package:flutter/material.dart';

/// A row of rounded progress segments — the tinted-paper stand-in for a
/// linear `ProgressIndicator`, used where progress reads better as discrete
/// steps (a routine's steps, a set count) than as a continuous bar.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.count,
    required this.filled,
    required this.color,
    this.semanticsLabel,
  });

  /// Total segments to render.
  final int count;

  /// How many of [count], counted from the start, render as filled.
  final int filled;

  final Color color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    // Past eight segments the 6px gap starts crowding the segments
    // themselves, so it narrows to 4px.
    final gap = count > 8 ? 4.0 : 6.0;

    final children = <Widget>[];
    for (var i = 0; i < count; i++) {
      if (i > 0) children.add(SizedBox(width: gap));
      final isFilled = i < filled;
      children.add(
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isFilled ? 0.7 : 0.15),
              borderRadius: const BorderRadius.all(Radius.circular(3)),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: Row(children: children),
    );
  }
}
