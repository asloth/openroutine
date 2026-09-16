import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'home_routine.dart';

/// Flexible routines, which have no start time. The toggle row stays pinned
/// while you scroll, so the section can be closed from anywhere on the page.
class AnytimeSection extends StatelessWidget {
  const AnytimeSection({
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
    final background = Theme.of(context).colorScheme.surface;

    return SliverMainAxisGroup(
      key: const Key('anytimeToday'),
      slivers: [
        PinnedHeaderSliver(
          child: ColoredBox(
            color: background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
              child: HomeSectionToggle(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < math.min(routines.length, 3); i++)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: HomeDot(),
                      ),
                  ],
                ),
                label: l10n.homeAnytimeToday,
                trailing: open
                    ? l10n.homeAnytimeHide
                    : l10n.homeAnytimeReady(routines.length),
                onTap: onToggle,
              ),
            ),
          ),
        ),
        if (open)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverList.separated(
              itemCount: routines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = routines[i];
                return HomeRoutineRow(
                  item: item,
                  subtitle:
                      '${item.summary(l10n)} · ${l10n.homeStartWhenYouWant}',
                  trailing: HomeTextAction(
                    label: l10n.homeStart,
                    onPressed: () => item.start(context),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
