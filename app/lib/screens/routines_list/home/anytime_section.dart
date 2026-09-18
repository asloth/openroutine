import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'home_routine.dart';
import 'timeline.dart';

/// Matches the timeline's own left inset (`_gutter - 8` in
/// routines_list_screen.dart), so the rail's dot lines up under the
/// timeline's, rather than under its wider header padding.
const _railGutter = 14.0;
const _gutter = 22.0;

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
            padding: const EdgeInsets.fromLTRB(_railGutter, 0, _gutter, 0),
            sliver: SliverList.separated(
              itemCount: routines.length,
              // No gap: HomeRail already pads the card away from its
              // neighbours, and a gap here would break the rail's line into
              // dashes — the loose-cards look this section is fixing.
              separatorBuilder: (_, _) => const SizedBox.shrink(),
              itemBuilder: (context, i) {
                final item = routines[i];
                return HomeRail(
                  child: HomeRoutineRow(
                    item: item,
                    showDot: false,
                    subtitle:
                        '${item.summary(l10n)} · ${l10n.homeStartWhenYouWant}',
                    trailing: HomeTextAction(
                      label: l10n.homeStart,
                      onPressed: () => item.start(context),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
