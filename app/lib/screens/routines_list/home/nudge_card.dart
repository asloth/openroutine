import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/routine.dart';
import '../../../services/routines/upcoming.dart';
import '../../../widgets/mascot_slot.dart';
import 'home_ink.dart';

/// The mascot pointing at the next routine: when it starts, and a way to
/// start it now.
class NudgeCard extends StatelessWidget {
  const NudgeCard({super.key, required this.routine, required this.upcoming});

  final Routine routine;
  final UpcomingState upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final headline = switch (upcoming) {
      // Rounded up and never zero: 40 seconds out still reads "1 min".
      StartsIn(:final remaining) => l10n.homeNudgeStartsIn(
        routine.name,
        (remaining.inSeconds / 60).ceil().clamp(1, 1 << 30),
      ),
      InProgress() => l10n.homeNudgeOnNow(routine.name),
    };

    return Container(
      key: const Key('nudgeCard'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ink.scheme.primaryContainer, ink.scheme.surfaceContainerLow],
        ),
        border: Border.all(color: ink.accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const MascotSlot(size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: HomeInk.title.copyWith(
                    fontSize: 14.5,
                    height: 1.35,
                    color: ink.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.homeNudgeCompanion,
                  style: HomeInk.detail.copyWith(color: ink.muted(0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          HomeActionButton(
            label: l10n.homeStart,
            onPressed: () => context.push('/routines/${routine.id}/timer'),
          ),
        ],
      ),
    );
  }
}
