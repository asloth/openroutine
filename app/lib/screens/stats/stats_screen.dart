import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../services/stats/routine_statistics.dart';
import '../../services/stats/stats_period.dart';
import '../../state/stats_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/mascot_slot.dart';
import '../../widgets/tinted/tinted.dart';
import '../routines_list/home/home_ink.dart';
import '../routines_list/home/home_routine.dart' show HomeDot;

/// Side padding, matching home.
const _gutter = 22.0;

/// What the app reports back about past runs.
///
/// Each card leads with the finding in a sentence, because that is the thing
/// worth knowing — "mornings are when you actually start" is the answer, a
/// bar at 07:00 is only the evidence. The evidence stays one tap away rather
/// than up front.
///
/// The figures here are read as judgements about the person, not summaries of
/// data, so the copy stays descriptive: a difference against an estimate, not
/// an error rate; runs finished, not runs failed. Nothing on this screen
/// should scold.
///
/// A destination root on the bottom nav, so there is no back target and no
/// stock `AppBar`.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  /// The period on screen. Starts on this week, and isn't remembered across
  /// launches: the question people open this screen with is "how's it going",
  /// which is about now.
  StatsPeriod? _period;

  /// The current period of [kind], with the week starting where the phone's
  /// locale starts it.
  StatsPeriod _current(StatsPeriodKind kind) {
    final now = DateTime.now();
    return switch (kind) {
      StatsPeriodKind.week => StatsPeriod.week(
        now,
        firstDayOfWeek: MaterialLocalizations.of(context).firstDayOfWeekIndex,
      ),
      StatsPeriodKind.month => StatsPeriod.month(now),
      StatsPeriodKind.allTime => const StatsPeriod.allTime(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final period = _period ??= _current(StatsPeriodKind.week);
    final statsAsync = ref.watch(statisticsProvider(period));
    final brightness = Theme.of(context).brightness;

    // An empty period means one of two things: a quiet week, or someone who
    // has never run a routine. Only the second gets the full first-run
    // screen, because there's nothing yet to browse back through. All time is
    // only asked for when it decides between them.
    final periodEmpty = statsAsync.value?.hasData == false;
    final neverRan =
        periodEmpty &&
        (period.kind == StatsPeriodKind.allTime ||
            ref
                    .watch(statisticsProvider(const StatsPeriod.allTime()))
                    .value
                    ?.hasData ==
                false);

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
              if (neverRan)
                const Expanded(child: _Empty())
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(_gutter, 16, _gutter, 0),
                  child: _PeriodControls(
                    period: period,
                    onKind: (kind) => setState(() => _period = _current(kind)),
                    onPeriod: (next) => setState(() => _period = next),
                  ),
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
                    data: (stats) => stats.hasData
                        ? _Report(stats: stats)
                        : const _EmptyPeriod(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Week, Month, or All time, and for the first two, arrows to step through
/// earlier ones.
class _PeriodControls extends StatelessWidget {
  const _PeriodControls({
    required this.period,
    required this.onKind,
    required this.onPeriod,
  });

  final StatsPeriod period;
  final ValueChanged<StatsPeriodKind> onKind;
  final ValueChanged<StatsPeriod> onPeriod;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);

    return Column(
      children: [
        _PeriodTrack(selected: period.kind, onSelected: onKind),
        if (period.kind != StatsPeriodKind.allTime)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                IconButton(
                  key: const Key('stats-period-previous'),
                  tooltip: l10n.statsPeriodPrevious,
                  color: ink.accent,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => onPeriod(period.previous()),
                ),
                Expanded(
                  child: Text(
                    _label(context, period),
                    textAlign: TextAlign.center,
                    style: HomeInk.label.copyWith(fontSize: 14, color: ink.ink),
                  ),
                ),
                IconButton(
                  key: const Key('stats-period-next'),
                  tooltip: l10n.statsPeriodNext,
                  color: ink.accent,
                  icon: const Icon(Icons.chevron_right_rounded),
                  // Nothing has happened in the future yet.
                  onPressed: period.isCurrent(DateTime.now())
                      ? null
                      : () => onPeriod(period.next()),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// "Oct 12 – Oct 18" or "October 2026", in the phone's language. A week
  /// from another year carries its year, so last December isn't mistaken for
  /// this one.
  static String _label(BuildContext context, StatsPeriod period) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = period.range.start!;
    final end = period.range.end!;
    if (period.kind == StatsPeriodKind.month) {
      return DateFormat.yMMMM(locale).format(start);
    }
    final last = DateTime(end.year, end.month, end.day - 1);
    final day = start.year == DateTime.now().year && last.year == start.year
        ? DateFormat.MMMd(locale)
        : DateFormat.yMMMd(locale);
    return '${day.format(start)} – ${day.format(last)}';
  }
}

/// The three periods as one segmented track, the same shape as the duration
/// presets on the step form.
class _PeriodTrack extends StatelessWidget {
  const _PeriodTrack({required this.selected, required this.onSelected});

  final StatsPeriodKind selected;
  final ValueChanged<StatsPeriodKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(12));
    final options = [
      (StatsPeriodKind.week, 'week', l10n.statsPeriodWeek),
      (StatsPeriodKind.month, 'month', l10n.statsPeriodMonth),
      (StatsPeriodKind.allTime, 'all-time', l10n.statsPeriodAllTime),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.accent.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final (kind, id, label) in options)
              Expanded(
                child: Semantics(
                  key: Key('stats-period-$id'),
                  button: true,
                  selected: kind == selected,
                  label: label,
                  excludeSemantics: true,
                  child: Material(
                    color: kind == selected ? ink.card : Colors.transparent,
                    borderRadius: radius,
                    child: InkWell(
                      // Selecting the current kind again returns to now.
                      onTap: () => onSelected(kind),
                      borderRadius: radius,
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Text(
                            label,
                            style: HomeInk.label.copyWith(
                              fontSize: 13,
                              color: kind == selected
                                  ? ink.ink
                                  : ink.muted(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the selected period had no runs but others did. Short, and
/// under the control, so the next step is obvious: go look at another one.
class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod();

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Align(
      alignment: const Alignment(0, -0.4),
      child: Padding(
        padding: AppSpacing.allContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotSlot(mood: MascotMood.idle, size: 88),
            AppSpacing.gapBase,
            Text(
              AppLocalizations.of(context)!.statsEmptyPeriod,
              textAlign: TextAlign.center,
              style: HomeInk.detail.copyWith(
                fontSize: 14,
                height: 1.45,
                color: ink.muted(0.62),
              ),
            ),
          ],
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
        _gutter,
        AppSpacing.container,
        _gutter,
        MediaQuery.paddingOf(context).bottom + 32,
      ),
      children: [
        _FinishingCard(rate: stats.completion),
        const SizedBox(height: 12),
        _EstimateCard(accuracy: stats.estimates),
        const SizedBox(height: 12),
        _SkippedCard(skipped: stats.skipped),
        const SizedBox(height: 12),
        _StartTimesCard(parts: stats.dayParts, hours: stats.startTimes),
      ],
    );
  }
}

/// A white card on the paper, the same one home uses.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.cardKey});

  final Widget child;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Material(
      key: cardKey,
      color: ink.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: ink.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: child,
      ),
    );
  }
}

/// The finding, in a sentence. The largest thing on its card.
class _Headline extends StatelessWidget {
  const _Headline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.display,
        fontSize: 19.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
        color: HomeInk.of(context).ink,
      ),
    );
  }
}

/// The evidence behind a headline, in one quiet line.
class _Detail extends StatelessWidget {
  const _Detail({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Text.rich(
      TextSpan(children: spans),
      style: HomeInk.detail.copyWith(
        fontSize: 13.5,
        height: 1.45,
        color: ink.muted(0.62),
      ),
    );
  }
}

/// Splits an ICU message around its one placeholder so the value can be
/// styled differently from the sentence carrying it.
///
/// The message is rendered once with a sentinel no translation would contain,
/// then cut at it. That keeps the word order the translator chose instead of
/// gluing fragments together in English order.
List<InlineSpan> _around(
  String Function(String) message,
  String value,
  TextStyle emphasis,
) {
  const sentinel = '⁣';
  final parts = message(sentinel).split(sentinel);
  return [
    TextSpan(text: parts.first),
    TextSpan(text: value, style: emphasis),
    if (parts.length > 1) TextSpan(text: parts.last),
  ];
}

/// The link that opens a card's evidence.
class _Disclosure extends StatelessWidget {
  const _Disclosure({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            label,
            style: HomeInk.label.copyWith(
              fontSize: 12.5,
              color: ink.muted(0.62),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card whose evidence expands in place.
class _Expandable extends StatefulWidget {
  const _Expandable({
    required this.summary,
    required this.showLabel,
    required this.hideLabel,
    required this.detail,
    this.cardKey,
  });

  final Widget summary;
  final String showLabel;
  final String hideLabel;
  final Widget detail;
  final Key? cardKey;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return _Card(
      cardKey: widget.cardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.summary,
          const SizedBox(height: 2),
          _Disclosure(
            label: _open ? widget.hideLabel : widget.showLabel,
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open) ...[
            const SizedBox(height: 6),
            Divider(height: 1, thickness: 1, color: ink.hairline),
            const SizedBox(height: 14),
            widget.detail,
          ],
        ],
      ),
    );
  }
}

/// Ten dots, however many runs there have been: the rate as a proportion you
/// can count, not a bar you have to measure.
class _RatioDots extends StatelessWidget {
  const _RatioDots({required this.filled, required this.color});

  final int filled;
  final Color color;

  static const total = 10;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: color.withValues(alpha: i < filled ? 0.75 : 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

/// How many of ten dots read as filled.
///
/// Rounded, but never all ten unless every run finished, and never zero while
/// any run has: a full row of dots next to "9 out of every 10" would be a lie
/// in the direction that flatters, and an empty row would be one in the
/// direction that stings.
int _filledDots(CompletionRate rate) {
  if (rate.total <= 0 || rate.finished == 0) return 0;
  if (rate.finished == rate.total) return _RatioDots.total;
  return (rate.rate * _RatioDots.total).round().clamp(1, _RatioDots.total - 1);
}

class _FinishingCard extends StatelessWidget {
  const _FinishingCard({required this.rate});

  final CompletionRate rate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final filled = _filledDots(rate);

    final headline = rate.rate >= 0.8
        ? l10n.statsFinishingHeadlineMost
        : rate.rate >= 0.5
        ? l10n.statsFinishingHeadlineHalf
        : l10n.statsFinishingHeadlineFew;

    final sentence =
        '$headline ${l10n.statsFinishingDetail(filled)} '
        '${l10n.statsStreak(rate.currentStreakDays)}';

    return Semantics(
      key: const Key('statsHeroSemantics'),
      container: true,
      label: sentence,
      child: ExcludeSemantics(
        child: _Card(
          cardKey: const Key('statsHeroCard'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Headline(headline),
              const SizedBox(height: 16),
              _RatioDots(filled: filled, color: ink.accent),
              const SizedBox(height: 14),
              _Detail(
                spans: [TextSpan(text: l10n.statsFinishingDetail(filled))],
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

/// Estimated against actual time.
///
/// Phrased as a difference rather than an accuracy percentage: "eight minutes
/// longer than you plan" is information, "62% accurate" is a grade.
class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.accuracy});

  final EstimateAccuracy? accuracy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final a = accuracy;

    if (a == null) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Headline(l10n.statsEstimateHeadlineExact),
            const SizedBox(height: 10),
            _Detail(spans: [TextSpan(text: l10n.statsEstimateNone)]),
          ],
        ),
      );
    }

    final difference = a.difference;
    final over = difference.inSeconds > 0;
    final headline = difference.inSeconds == 0
        ? l10n.statsEstimateHeadlineExact
        : over
        ? l10n.statsEstimateHeadlineOver
        : l10n.statsEstimateHeadlineUnder;

    final steps = a.steps.take(5).toList();
    // Every bar is drawn against the worst overrun on screen, so the lengths
    // stay comparable to each other rather than each filling its own row.
    final widest = steps.fold(
      0,
      (m, s) =>
          s.difference.inSeconds.abs() > m ? s.difference.inSeconds.abs() : m,
    );

    final biggest = steps.isEmpty ? null : steps.first;
    final emphasis = TextStyle(
      fontWeight: FontWeight.w700,
      color: ink.muted(0.85),
    );

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Headline(headline),
        const SizedBox(height: 10),
        _Detail(
          spans: [
            if (difference.inSeconds != 0)
              TextSpan(
                text: over
                    ? '${l10n.statsEstimateDetailOver(_short(difference))} '
                    : '${l10n.statsEstimateDetailUnder(_short(difference.abs()))} ',
              ),
            if (biggest != null)
              ..._around(l10n.statsEstimateBiggest, biggest.name, emphasis),
          ],
        ),
      ],
    );

    if (steps.isEmpty) return _Card(child: summary);

    return _Expandable(
      summary: summary,
      showLabel: l10n.statsEstimateShowSteps,
      hideLabel: l10n.statsEstimateHideSteps,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: ink.hairline),
            _EstimateRow(step: steps[i], widest: widest),
          ],
        ],
      ),
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
              style: HomeInk.detail.copyWith(fontSize: 13.5, color: ink.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: _DivergingBar(factor: factor, over: over, color: ink.accent),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              // The sign is the point of the row, so it is always shown —
              // "+6m" and a real minus for the other direction, never a bare
              // "6m" that reads the same either way.
              '${over ? '+' : '−'}${_short(step.difference.abs())}',
              textAlign: TextAlign.end,
              style: HomeInk.detail.copyWith(
                fontSize: 12.5,
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

/// A bar growing out of a centre line: right when a step ran long, left when
/// it came in under.
///
/// One colour, not two. The side the bar grows to already separates the two
/// directions at a glance, and the row carries a signed number besides, so a
/// second hue would only be saying a third time what the shape says once —
/// and it would have to come from outside the accent to do it.
class _DivergingBar extends StatelessWidget {
  const _DivergingBar({
    required this.factor,
    required this.over,
    required this.color,
  });

  final double factor;
  final bool over;
  final Color color;

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
              color: color,
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

class _SkippedCard extends StatelessWidget {
  const _SkippedCard({required this.skipped});

  final List<SkippedStep> skipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);

    if (skipped.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Headline(l10n.statsSkippedHeadlineNone),
            const SizedBox(height: 10),
            _Detail(spans: [TextSpan(text: l10n.statsSkippedNone)]),
          ],
        ),
      );
    }

    final steps = skipped.take(5).toList();
    final worst = steps.first;
    final most = steps.fold(0, (m, s) => s.count > m ? s.count : m);

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Headline(l10n.statsSkippedHeadline(worst.name)),
        const SizedBox(height: 10),
        _Detail(spans: [TextSpan(text: l10n.statsSkippedDetail(worst.count))]),
      ],
    );

    // One skipped step is the whole story already; there is no rest to show.
    if (steps.length == 1) return _Card(child: summary);

    return _Expandable(
      summary: summary,
      showLabel: l10n.statsSkippedShowRest,
      hideLabel: l10n.statsSkippedHideRest,
      detail: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: ink.hairline),
            SizedBox(
              height: 42,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      steps[i].name,
                      style: HomeInk.detail.copyWith(
                        fontSize: 13.5,
                        color: ink.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 64,
                    child: _TrackBar(
                      factor: most == 0 ? 0 : steps[i].count / most,
                      color: ink.accent,
                      track: ink.muted(0.1),
                    ),
                  ),
                  const SizedBox(width: 10),
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
      ),
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

/// When runs actually start: the part of the day up front, the hours behind
/// it.
///
/// Painted with layout rather than a charting dependency: it is a row of
/// proportional bars, which does not justify a package.
class _StartTimesCard extends StatelessWidget {
  const _StartTimesCard({required this.parts, required this.hours});

  final List<DayPartBucket> parts;
  final List<HourBucket> hours;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);

    final busiest = parts.fold(0, (m, p) => p.runs > m ? p.runs : m);
    if (busiest == 0) return const SizedBox.shrink();

    final top = parts.firstWhere((p) => p.runs == busiest);
    final headline = switch (top.part) {
      DayPart.morning => l10n.statsTimeHeadlineMorning,
      DayPart.afternoon => l10n.statsTimeHeadlineAfternoon,
      DayPart.evening => l10n.statsTimeHeadlineEvening,
    };

    String partLabel(DayPart part) => switch (part) {
      DayPart.morning => l10n.statsTimePartMorning,
      DayPart.afternoon => l10n.statsTimePartAfternoon,
      DayPart.evening => l10n.statsTimePartEvening,
    };

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Headline(headline),
        const SizedBox(height: 16),
        for (final part in parts)
          SizedBox(
            height: 30,
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    partLabel(part.part),
                    style: HomeInk.detail.copyWith(
                      fontSize: 13,
                      color: ink.muted(0.62),
                    ),
                  ),
                ),
                Expanded(
                  child: _TrackBar(
                    factor: part.runs / busiest,
                    // The busiest part wears the full colour and the others a
                    // wash of it: the lengths already say which is longest,
                    // the tint says it is the answer in the headline.
                    color: part.runs == busiest
                        ? ink.accent
                        : ink.accent.withValues(alpha: 0.4),
                    track: ink.muted(0.06),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (hours.isEmpty) return _Card(child: summary);

    final busiestHour = hours.fold(0, (m, h) => h.runs > m ? h.runs : m);

    return _Expandable(
      cardKey: const Key('statsStartTimes'),
      summary: summary,
      showLabel: l10n.statsTimeShowHours,
      hideLabel: l10n.statsTimeHideHours,
      detail: Column(
        children: [
          for (final bucket in hours)
            SizedBox(
              height: 30,
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      l10n.statsTimeHour(
                        bucket.hour.toString().padLeft(2, '0'),
                      ),
                      style: HomeInk.detail.copyWith(
                        fontSize: 12.5,
                        color: ink.muted(0.55),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: bucket.runs,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: bucket.runs == busiestHour
                                  ? ink.accent
                                  : ink.accent.withValues(alpha: 0.35),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(4),
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
                        if (busiestHour > bucket.runs)
                          Spacer(flex: busiestHour - bucket.runs),
                      ],
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
