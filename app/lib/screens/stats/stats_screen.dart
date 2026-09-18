import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/stats/routine_statistics.dart';
import '../../state/stats_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/mascot_slot.dart';
import '../../widgets/tinted/tinted.dart';
import '../routines_list/home/home_ink.dart';
import '../routines_list/home/home_routine.dart' show HomeDot;

/// Side padding, matching home.
const _gutter = 22.0;

/// Space between one section and the next.
const _sectionGap = 26.0;

/// What the app reports back about past runs.
///
/// The figures here are read as judgements about the person, not summaries of
/// data, so the copy stays descriptive: a difference against an estimate, not
/// an error rate; runs finished, not runs failed. Nothing on this screen
/// should scold.
///
/// Laid out the way home is — a quiet heading on the paper over the thing it
/// names — so the two destinations read as one app.
///
/// A destination root on the bottom nav, so there is no back target and no
/// stock `AppBar`.
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
                padding: const EdgeInsets.fromLTRB(_gutter, 16, _gutter, 0),
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
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        _gutter,
        AppSpacing.container,
        _gutter,
        MediaQuery.paddingOf(context).bottom + 32,
      ),
      children: [
        _SectionLabel(l10n.statsCompletionTitle),
        _FinishingCard(rate: stats.completion),
        const SizedBox(height: _sectionGap),
        _SectionLabel(l10n.statsEstimateTitle),
        _EstimateBlock(accuracy: stats.estimates),
        const SizedBox(height: _sectionGap),
        _SectionLabel(l10n.statsSkippedTitle),
        _SkippedBlock(skipped: stats.skipped),
        const SizedBox(height: _sectionGap),
        _SectionLabel(l10n.statsTimeTitle),
        _StartTimesBlock(buckets: stats.startTimes),
      ],
    );
  }
}

/// A section's name, set on the paper rather than inside the thing it names.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: HomeInk.label.copyWith(
          fontSize: 11.5,
          letterSpacing: 0.9,
          color: HomeInk.of(context).muted(0.55),
        ),
      ),
    );
  }
}

/// A white card on the paper, the same one home uses.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding, this.onKey});

  final Widget child;
  final EdgeInsets? padding;
  final Key? onKey;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Material(
      key: onKey,
      color: ink.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: ink.hairline),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: child,
      ),
    );
  }
}

/// How many of `SegmentedProgress`'s segments to draw, and how many of those
/// read as filled, for a `finished`-of-`total` completion rate.
///
/// One segment per run while that stays legible, so the bar is countable
/// rather than merely proportional. Past 60 runs the segments would be
/// thinner than the gaps between them, so it falls back to a scaled bar.
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
  final segments = total <= 60 ? total : 60;
  final filled = (finished * segments / total).round();
  return (segments, filled);
}

/// Finishing, as the hero: the number this screen exists to answer. The
/// other three sections explain *why* it looks the way it does, so this one
/// carries the visual weight.
class _FinishingCard extends StatelessWidget {
  const _FinishingCard({required this.rate});

  final CompletionRate rate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final scheme = Theme.of(context).colorScheme;
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
        child: _Card(
          onKey: const Key('statsHeroCard'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A `Wrap`, not a `Row`: at the base text scale both pieces sit
              // on one baseline-aligned line, but a large accessibility text
              // scale can no longer fit "of N runs finished" beside a
              // 56-point number, so the phrase drops to its own line instead
              // of overflowing.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 10,
                runSpacing: 4,
                children: [
                  Text(
                    l10n.statsCompletionFinished(rate.finished),
                    style: TextStyle(
                      fontFamily: AppTypography.display,
                      fontSize: 56,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.5,
                      height: 1,
                      color: ink.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l10n.statsCompletionOfTotal(rate.total),
                      style: HomeInk.detail.copyWith(
                        fontSize: 14.5,
                        color: ink.muted(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SegmentedProgress(
                count: segments,
                filled: filled,
                color: scheme.secondary,
              ),
              const SizedBox(height: 14),
              // The legend is what makes the bar readable: without it the
              // pale half looks like nothing rather than like runs that
              // ended early.
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Swatch(
                    color: scheme.secondary.withValues(alpha: 0.7),
                    label: l10n.statsCompletionFinishedLegend(rate.finished),
                  ),
                  _Swatch(
                    color: scheme.secondary.withValues(alpha: 0.15),
                    label: l10n.statsCompletionLeftEarly(rate.abandoned),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, thickness: 1, color: ink.hairline),
              const SizedBox(height: 14),
              Row(
                children: [
                  const HomeDot(size: 7),
                  const SizedBox(width: 9),
                  Text(
                    l10n.statsStreak(rate.currentStreakDays),
                    style: HomeInk.title.copyWith(fontSize: 14.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small colour chip and the thing it stands for.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: HomeInk.detail.copyWith(
            fontSize: 12.5,
            color: HomeInk.of(context).muted(0.6),
          ),
        ),
      ],
    );
  }
}

/// Estimated against actual time.
///
/// Phrased as a difference rather than an accuracy percentage: "eight minutes
/// longer than estimated" is information, "62% accurate" is a grade.
class _EstimateBlock extends StatelessWidget {
  const _EstimateBlock({required this.accuracy});

  final EstimateAccuracy? accuracy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final a = accuracy;

    if (a == null) {
      return Text(
        l10n.statsEstimateNone,
        style: HomeInk.detail.copyWith(color: ink.muted(0.6)),
      );
    }

    final difference = a.difference;
    final headline = difference.inSeconds == 0
        ? l10n.statsEstimateExact
        : difference.isNegative
        ? l10n.statsEstimateUnder(_short(difference.abs()))
        : l10n.statsEstimateOver(_short(difference));

    final steps = a.steps.take(5).toList();
    // Every bar is drawn against the worst overrun on screen, so the lengths
    // stay comparable to each other rather than each filling its own row.
    final widest = steps.fold(
      0,
      (m, s) =>
          s.difference.inSeconds.abs() > m ? s.difference.inSeconds.abs() : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: TextStyle(
            fontFamily: AppTypography.display,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: ink.ink,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: ink.hairline),
          _EstimateRow(step: steps[i], widest: widest),
        ],
      ],
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({required this.step, required this.widest});

  final StepEstimate step;
  final int widest;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    final scheme = Theme.of(context).colorScheme;
    final seconds = step.difference.inSeconds;
    final over = seconds > 0;
    final factor = widest == 0 ? 0.0 : seconds.abs() / widest;

    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Text(
              step.name,
              style: HomeInk.detail.copyWith(fontSize: 14, color: ink.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: _DivergingBar(
              factor: factor,
              over: over,
              overColor: scheme.tertiary,
              underColor: scheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              // The sign is the point of the row, so it is always shown —
              // "+6m" and "−1m", never a bare "6m" that reads the same
              // either way. A real minus sign, not a hyphen.
              '${over ? '+' : '−'}${_short(step.difference.abs())}',
              textAlign: TextAlign.end,
              style: HomeInk.detail.copyWith(
                fontSize: 13,
                color: ink.muted(0.6),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bar growing out of a centre line: right and warm when a step ran long,
/// left and green when it came in under. The centre is what lets one glance
/// separate the two, without reading a single number.
class _DivergingBar extends StatelessWidget {
  const _DivergingBar({
    required this.factor,
    required this.over,
    required this.overColor,
    required this.underColor,
  });

  final double factor;
  final bool over;
  final Color overColor;
  final Color underColor;

  @override
  Widget build(BuildContext context) {
    Widget half(Alignment side, bool mine) => Expanded(
      child: Align(
        alignment: side,
        child: FractionallySizedBox(
          widthFactor: mine ? factor.clamp(0.0, 1.0) : 0.0,
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              color: over ? overColor : underColor,
              borderRadius: const BorderRadius.all(Radius.circular(3.5)),
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        half(Alignment.centerRight, !over),
        half(Alignment.centerLeft, over),
      ],
    );
  }
}

/// The steps you skip most, each on its own card.
class _SkippedBlock extends StatelessWidget {
  const _SkippedBlock({required this.skipped});

  final List<SkippedStep> skipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (skipped.isEmpty) {
      return Text(
        l10n.statsSkippedNone,
        style: HomeInk.detail.copyWith(color: ink.muted(0.6)),
      );
    }

    final steps = skipped.take(5).toList();
    final most = steps.fold(0, (m, s) => s.count > m ? s.count : m);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _Card(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    steps[i].name,
                    style: HomeInk.title.copyWith(fontSize: 14.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: _TrackBar(
                    factor: most == 0 ? 0 : steps[i].count / most,
                    color: scheme.tertiary,
                    track: ink.muted(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.statsSkippedCount(steps[i].count),
                  style: HomeInk.detail.copyWith(
                    fontSize: 12.5,
                    color: ink.muted(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A bar filled from the left against a visible track.
class _TrackBar extends StatelessWidget {
  const _TrackBar({
    required this.factor,
    required this.color,
    required this.track,
  });

  final double factor;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(3.5)),
      child: Container(
        height: 7,
        color: track,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: factor.clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}

/// When runs actually start, as bars per local hour.
///
/// Painted with layout rather than a charting dependency: it is a row of
/// proportional bars, which does not justify a package.
class _StartTimesBlock extends StatelessWidget {
  const _StartTimesBlock({required this.buckets});

  final List<HourBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final scheme = Theme.of(context).colorScheme;
    final busiest = buckets.fold(0, (m, b) => b.runs > m ? b.runs : m);

    return Column(
      children: [
        for (final bucket in buckets)
          SizedBox(
            height: 34,
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    l10n.statsTimeHour(bucket.hour.toString().padLeft(2, '0')),
                    style: HomeInk.detail.copyWith(
                      fontSize: 12.5,
                      color: ink.muted(0.55),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: bucket.runs,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            // The busiest hour wears the full colour and the
                            // rest a wash of it: the shape already says which
                            // is longest, the tint says it is the answer.
                            color: bucket.runs == busiest
                                ? scheme.secondary
                                : scheme.secondary.withValues(alpha: 0.3),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${bucket.runs}',
                        style: HomeInk.detail.copyWith(
                          fontSize: 12.5,
                          color: ink.muted(0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (busiest > bucket.runs)
                        Spacer(flex: busiest - bucket.runs),
                    ],
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
