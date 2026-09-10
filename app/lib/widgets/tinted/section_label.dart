import 'package:flutter/material.dart';

import '../../theme/typography.dart';

/// An uppercase section caption above a group of tinted cards. Takes the
/// caller's text as-written and uppercases it for display, so a caller never
/// has to remember to shout its own copy.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.sectionLabel.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
