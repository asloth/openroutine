import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/routines/schedule_time.dart';
import '../../../services/routines/today_progress.dart';
import 'home_ink.dart';
import 'home_routine.dart';

/// Today's scheduled routines down a rail, earliest first.
class Timeline extends StatelessWidget {
  const Timeline({super.key, required this.routines});

  final List<HomeRoutine> routines;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('timeline'),
      children: [for (final item in routines) _TimelineRow(item: item)],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item});

  final HomeRoutine item;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    final highlighted = item.upcoming != null || item.progress is PartwayToday;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _StartTime(item: item, strong: highlighted),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 8,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(width: 1, color: ink.muted(0.1)),
                  ),
                ),
                const Positioned(top: 24, child: HomeDot(size: 8)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _TimelineCard(item: item, highlighted: highlighted),
            ),
          ),
        ],
      ),
    );
  }
}

/// "7:00" over "AM", or a single 24-hour time when the phone uses one.
class _StartTime extends StatelessWidget {
  const _StartTime({required this.item, required this.strong});

  final HomeRoutine item;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    final time = ScheduleTime.parseStartTime(item.routine.schedule.startTime);
    if (time == null) return const SizedBox.shrink();

    final at = DateTime(2000, 1, 1, time.$1, time.$2);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final twentyFour = MediaQuery.alwaysUse24HourFormatOf(context);
    final clock = twentyFour
        ? DateFormat.Hm(locale).format(at)
        : DateFormat('h:mm', locale).format(at);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          clock,
          style: HomeInk.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: strong ? ink.ink : ink.muted(0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (!twentyFour)
          Text(
            DateFormat('a', locale).format(at),
            style: HomeInk.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ink.muted(0.4),
            ),
          ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item, required this.highlighted});

  final HomeRoutine item;
  final bool highlighted;

  /// Past this, pips get too thin to read, so the bar tops out.
  static const _maxPips = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(24));

    final total = item.routine.stepIds.length;
    final (done, badge) = switch (item.progress) {
      DoneToday() => (total, l10n.homeDone),
      PartwayToday(:final done, :final total) => (
        done,
        l10n.homeProgress(done, total),
      ),
      null => (0, null),
    };
    final pips = total.clamp(0, _maxPips);
    final filled = total == 0 ? 0 : (done * pips / total).round();

    return Material(
      color: highlighted ? ink.card : ink.card.withValues(alpha: 0.62),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: highlighted
              ? ink.accent.withValues(alpha: 0.42)
              : ink.hairline,
        ),
      ),
      child: InkWell(
        onTap: () => item.open(context),
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 16, item.hasCoreSteps ? 8 : 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(right: item.hasCoreSteps ? 10 : 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.routine.name,
                        style: HomeInk.title.copyWith(
                          fontSize: 17.5,
                          color: ink.ink,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        badge,
                        style: HomeInk.label.copyWith(color: ink.accent),
                      ),
                    ],
                  ],
                ),
              ),
              if (pips > 0) ...[
                const SizedBox(height: 11),
                Padding(
                  padding: EdgeInsets.only(right: item.hasCoreSteps ? 10 : 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < pips; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: i < filled ? ink.accent : ink.muted(0.1),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        item.summary(l10n),
                        style: HomeInk.detail.copyWith(color: ink.muted(0.55)),
                      ),
                    ),
                  ),
                  if (item.hasCoreSteps)
                    HomeTextAction(
                      label: l10n.routinesStartLowMode,
                      onPressed: () => item.startLowMode(context),
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
