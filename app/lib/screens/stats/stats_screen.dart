import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/stats/routine_statistics.dart';
import '../../state/stats_provider.dart';
import '../../theme/neumorphic.dart';
import '../../theme/spacing.dart';
import '../../widgets/mascot_slot.dart';

/// What the app reports back about past runs.
///
/// The figures here are read as judgements about the person, not summaries of
/// data, so the copy stays descriptive: a difference against an estimate, not
/// an error rate; runs finished, not runs failed. Nothing on this screen
/// should scold.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        // A destination root, not a pushed page: there is nothing behind it
        // to go back to.
        automaticallyImplyLeading: false,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: AppSpacing.allContainer,
            child: Text(l10n.routinesLoadError, textAlign: TextAlign.center),
          ),
        ),
        data: (stats) => stats.hasData ? _Report(stats: stats) : const _Empty(),
      ),
    );
  }
}

/// Shown when nothing has been run yet.
///
/// Deliberately not four zeroed charts: an empty chart reads as a score of
/// zero, which is a judgement the absence of data does not support.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.allContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotSlot(mood: MascotMood.idle, size: 112),
            AppSpacing.gapContainer,
            Text(
              l10n.statsEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapBase,
            Text(
              l10n.statsEmptyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.stats});

  final RoutineStatistics stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.element,
        AppSpacing.element,
        AppSpacing.element,
        AppSpacing.section,
      ),
      children: [
        _EstimateCard(accuracy: stats.estimates),
        AppSpacing.gapElement,
        _CompletionCard(rate: stats.completion),
        AppSpacing.gapElement,
        _SkippedCard(skipped: stats.skipped),
        AppSpacing.gapElement,
        _StartTimesCard(buckets: stats.startTimes),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeumorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          AppSpacing.gapElement,
          child,
        ],
      ),
    );
  }
}

/// Estimated against actual time.
///
/// Phrased as a difference rather than an accuracy percentage: "eight minutes
/// longer than estimated" is information, "62% accurate" is a grade.
class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.accuracy});

  final EstimateAccuracy? accuracy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final a = accuracy;

    if (a == null) {
      return _Section(
        title: l10n.statsEstimateTitle,
        child: Text(
          l10n.statsEstimateNone,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final difference = a.difference;
    final headline = difference.inSeconds == 0
        ? l10n.statsEstimateExact
        : difference.isNegative
        ? l10n.statsEstimateUnder(_short(difference.abs()))
        : l10n.statsEstimateOver(_short(difference));

    return _Section(
      title: l10n.statsEstimateTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: theme.textTheme.titleMedium),
          AppSpacing.gapElement,
          for (final step in a.steps.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      step.name,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_short(step.actual)} / ${_short(step.estimated)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.rate});

  final CompletionRate rate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _Section(
      title: l10n.statsCompletionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statsCompletionRate(rate.finished, rate.total),
            style: theme.textTheme.titleMedium,
          ),
          AppSpacing.gapBase,
          // The streak sits next to the rate on purpose. A streak alone is the
          // figure most likely to feel like an accusation once it breaks.
          Text(
            l10n.statsStreak(rate.currentStreakDays),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapElement,
          ClipRRect(
            borderRadius: AppRadius.mediumBorder,
            child: LinearProgressIndicator(
              value: rate.rate,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkippedCard extends StatelessWidget {
  const _SkippedCard({required this.skipped});

  final List<SkippedStep> skipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _Section(
      title: l10n.statsSkippedTitle,
      child: skipped.isEmpty
          ? Text(
              l10n.statsSkippedNone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in skipped.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.base),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.name,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          l10n.statsSkippedCount(step.count),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// When runs actually start, as bars per local hour.
///
/// Painted with layout rather than a charting dependency: it is a row of
/// proportional bars, which does not justify a package.
class _StartTimesCard extends StatelessWidget {
  const _StartTimesCard({required this.buckets});

  final List<HourBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final busiest = buckets.fold(0, (m, b) => b.runs > m ? b.runs : m);

    return _Section(
      title: l10n.statsTimeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final bucket in buckets)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      l10n.statsTimeHour(
                        bucket.hour.toString().padLeft(2, '0'),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.mediumBorder,
                      child: LinearProgressIndicator(
                        value: busiest == 0 ? 0 : bucket.runs / busiest,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact duration: "1h 05m", "12m", "45s". Long enough to be exact where it
/// matters and short enough to sit at the end of a row.
String _short(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}
