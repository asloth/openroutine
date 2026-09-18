import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'home_ink.dart';
import 'home_routine.dart';

/// Side padding, matching the rest of home.
const _gutter = 22.0;

/// Flexible routines, which have no start time.
///
/// They ride in a horizontal strip of pills rather than the full-width cards
/// the timeline uses. A routine with no time doesn't need a row of its own —
/// and stacking cards under a card-shaped header made the section read as a
/// pile of loose boxes, which is what this shape fixes.
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

    return SliverMainAxisGroup(
      key: const Key('anytimeToday'),
      slivers: [
        SliverToBoxAdapter(
          child: _Label(
            label: l10n.homeAnytimeToday,
            action: open
                ? l10n.homeAnytimeCountHide(routines.length)
                : l10n.homeAnytimeCountShow(routines.length),
            onTap: onToggle,
          ),
        ),
        if (open)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _gutter),
                itemCount: routines.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _Pill(item: routines[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// The section's name and its show/hide action, set straight on the paper.
/// No card here: the pills below are the only thing in the section carrying an
/// outline, so the name reads as a heading rather than a second box.
class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    final style = HomeInk.label.copyWith(
      fontSize: 11.5,
      color: ink.muted(0.55),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter, 18, _gutter, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: style.copyWith(letterSpacing: 0.9),
            ),
          ),
          const SizedBox(width: 8),
          // Only the action takes the tap, not the whole row — the heading
          // itself isn't a control, and making it one invites a stray tap
          // that collapses the section while you're reaching past it.
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(action, style: style),
            ),
          ),
        ],
      ),
    );
  }
}

/// One flexible routine: a dot, its name, and how long it takes.
///
/// Dashed rather than solid, so it reads as loose — not pinned to a time the
/// way the timeline's cards below are.
class _Pill extends StatelessWidget {
  const _Pill({required this.item});

  final HomeRoutine item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(22));

    return Semantics(
      button: true,
      child: CustomPaint(
        painter: _DashedPill(color: ink.muted(0.3)),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => item.open(context),
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HomeDot(size: 7),
                  const SizedBox(width: 9),
                  Text(
                    item.routine.name,
                    style: HomeInk.title.copyWith(fontSize: 14, color: ink.ink),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    l10n.homeMinutesShort(item.minutes),
                    style: HomeInk.label.copyWith(color: ink.muted(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Strokes a stadium outline as dashes. Flutter's own borders are solid only,
/// so the outline is walked by hand and drawn in alternating runs.
class _DashedPill extends CustomPainter {
  const _DashedPill({required this.color});

  final Color color;

  static const _dash = 4.0;
  static const _gap = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill old) => old.color != color;
}
