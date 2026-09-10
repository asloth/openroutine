import 'package:flutter/material.dart';

import '../../theme/typography.dart';

/// A screen header with no stock Material chrome: no `AppBar`, no bottom
/// border, no elevation. Just a row — optional leading content, an optional
/// title, and trailing actions — so a redesigned screen supplies its own
/// background instead of inheriting one from a bar widget.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    this.leading,
    this.title,
    this.actions = const [],
  });

  final Widget? leading;
  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ?leading,
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: title == null
              ? const SizedBox.shrink()
              : Text(
                  title!,
                  style: AppTypography.pageTitle,
                  textAlign: TextAlign.left,
                ),
        ),
      ),
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        actions[i],
      ],
    ];

    // A min height rather than a fixed one: at the base text scale the row
    // sits at 48px, but a wrapped two-line title at a larger text scale must
    // be free to grow the row rather than clip.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}
