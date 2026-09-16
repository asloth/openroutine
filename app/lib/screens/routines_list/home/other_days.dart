import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'home_ink.dart';
import 'home_routine.dart';

/// Scheduled routines that aren't due today, folded away at the bottom so
/// they stay reachable without crowding the day.
class OtherDays extends StatelessWidget {
  const OtherDays({
    super.key,
    required this.routines,
    required this.open,
    required this.onToggle,
  });

  final List<HomeRoutine> routines;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    return Column(
      key: const Key('otherDays'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionToggle(
          leading: Icon(
            open ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: ink.muted(0.5),
          ),
          label: '${l10n.homeOtherDays} · ${routines.length}',
          trailing: '',
          onTap: onToggle,
        ),
        if (open)
          for (final item in routines) ...[
            const SizedBox(height: 8),
            HomeRoutineRow(item: item, subtitle: item.summary(l10n)),
          ],
      ],
    );
  }
}
