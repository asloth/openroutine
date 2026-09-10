import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/stats/routine_statistics.dart';
import '../../state/stats_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/mascot_slot.dart';
import '../../widgets/tinted/tinted.dart';

/// What the app reports back about past runs.
///
/// The figures here are read as judgements about the person, not summaries of
/// data, so the copy stays descriptive: a difference against an estimate, not
/// an error rate; runs finished, not runs failed. Nothing on this screen
/// should scold.
///
/// A destination root on the bottom nav, so there is no back target and no
/// stock `AppBar` — a `PageHeader` carries the title instead, over the same
/// tinted ground as the rest of the screen.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(statisticsProvider);
    final brightness = Theme.of(context).brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PageHeader(title: l10n.statsTitle),
              ),
              Expanded(
                child: statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Padding(
                      padding: AppSpacing.allContainer,
                      child: Text(
                        l10n.routinesLoadError,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (stats) =>
                      stats.hasData ? _Report(stats: stats) : const _Empty(),
                ),
              ),
            ],
          ),
        ),
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
      padding: EdgeInsets.fromLTRB(
        16,
        AppSpacing.container,
        16,
        MediaQuery.paddingOf(context).bottom + 32,
      ),
      children: [
        _HeroCard(rate: stats.completion),
        AppSpacing.gapContainer,
        _EstimateSection(accuracy: stats.estimates),
        AppSpacing.gapContainer,
        _SkippedSection(skipped: stats.skipped),
        AppSpacing.gapContainer,
        _StartTimesSection(buckets: stats.startTimes),
      ],
    );
  }
}

/// How many of `SegmentedProgress`'s segments to draw, and how many of those
/// read as filled, for a `finished`-of-`total` completion rate.
///
/// Guarded against a zero total: the real aggregation service never reports
/// `hasData: true` with a zero-total completion, but this screen doesn't
/// assume that invariant holds — the guard is what keeps a division by zero
/// from ever surfacing as a crash instead of an empty bar.
(int segments, int filled) _heroSegments({
  required int finished,
  required int total,
}) {
  if (total <= 0) return (0, 0);
  final segments = total < 20 ? total : 20;
  final filled = (finished * segments / total).round();
  return (segments, filled);
}

/// Finishing, as the hero: the number this screen exists to answer. The
/// other three sections explain *why* it looks the way it does, so this one
/// carries the visual weight.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.rate});

  final CompletionRate rate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.routineCardColors;
    final (segments, filled) = _heroSegments(
      finished: rate.finished,
      total: rate.total,
    );

    final sentence =
        '${l10n.statsCompletionRate(rate.finished, rate.total)}. '
        '${l10n.statsStreak(rate.currentStreakDays)}';

    return Semantics(
      key: const Key('statsHeroSemantics'),
      container: true,
      label: sentence,
      child: ExcludeSemantics(
        child: TintedCard(
          key: const Key('statsHeroCard'),
          color: colors.fill,
          foregroundColor: colors.onFill,
          borderRadius: AppRadius.heroBorder,
          padding: const EdgeInsets.fromLTRB(22, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.statsCompletionTitle.toUpperCase(),
                style: AppTypography.sectionLabel.copyWith(
                  color: colors.onFill.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              // A `Wrap`, not a `Row`: at the base text scale both pieces sit
              // on one baseline-aligned line, but a large accessibility text
              // scale can no longer fit "of N runs finished" beside a
              // 64-point number, so the phrase drops to its own line instead
              // of overflowing.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 4,
                children: [
                  Text(
                    l10n.statsCompletionFinished(rate.finished),
                    style: const TextStyle(
                      fontFamily: AppTypography.display,
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.5,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    l10n.statsCompletionOfTotal(rate.total),
                    style: const TextStyle(
                      fontFamily: AppTypography.display,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.statsStreak(rate.currentStreakDays),
                style: const TextStyle(
                  fontFamily: AppTypography.body,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedProgress(
                count: segments,
                filled: filled,
                color: colors.onFill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A `SectionLabel` over rows laid flat on the page, divided by a hairline
/// between rows and no divider after the last one — the "flat on the page"
/// treatment the three non-hero sections share, in place of a bounding card.
class _FlatSection extends StatelessWidget {
  const _FlatSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        AppSpacing.gapBase,
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) divider,
        ],
      ],
    );
  }
}

/// One 44px-tall, 8px-inset row inside a `_FlatSection`.
class _FlatRow extends StatelessWidget {
  const _FlatRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }
}

/// Estimated against actual time.
///
/// Phrased as a difference rather than an accuracy percentage: "eight minutes
/// longer than estimated" is information, "62% accurate" is a grade.
class _EstimateSection extends StatelessWidget {
  const _EstimateSection({required this.accuracy});

  final EstimateAccuracy? accuracy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final a = accuracy;

    if (a == null) {
      return _FlatSection(
        title: l10n.statsEstimateTitle,
        rows: [
          _FlatRow(
            child: Text(
              l10n.statsEstimateNone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    final difference = a.difference;
    final headline = difference.inSeconds == 0
        ? l10n.statsEstimateExact
        : difference.isNegative
        ? l10n.statsEstimateUnder(_short(difference.abs()))
        : l10n.statsEstimateOver(_short(difference));

    return _FlatSection(
      title: l10n.statsEstimateTitle,
      rows: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            headline,
            style: const TextStyle(
              fontFamily: AppTypography.display,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final step in a.steps.take(5))
          _FlatRow(
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
    );
  }
}

class _SkippedSection extends StatelessWidget {
  const _SkippedSection({required this.skipped});

  final List<SkippedStep> skipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (skipped.isEmpty) {
      return _FlatSection(
        title: l10n.statsSkippedTitle,
        rows: [
          _FlatRow(
            child: Text(
              l10n.statsSkippedNone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return _FlatSection(
      title: l10n.statsSkippedTitle,
      rows: [
        for (final step in skipped.take(5))
          _FlatRow(
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
    );
  }
}

/// When runs actually start, as bars per local hour.
///
/// Painted with layout rather than a charting dependency: it is a row of
/// proportional bars, which does not justify a package.
class _StartTimesSection extends StatelessWidget {
  const _StartTimesSection({required this.buckets});

  final List<HourBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final busiest = buckets.fold(0, (m, b) => b.runs > m ? b.runs : m);

    return _FlatSection(
      title: l10n.statsTimeTitle,
      rows: [
        for (final bucket in buckets)
          _FlatRow(
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    l10n.statsTimeHour(bucket.hour.toString().padLeft(2, '0')),
                    style: TextStyle(
                      fontFamily: AppTypography.body,
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      color: theme.colorScheme.surfaceContainer,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: busiest == 0 ? 0 : bucket.runs / busiest,
                        child: Container(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
