import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/spacing.dart';

/// A pill-shaped segmented control driven by a `TabController` — the
/// tinted-paper stand-in for a `TabBar`. Following the controller's
/// `animation` rather than its `index` means the pill tracks a swipe on a
/// paired `TabBarView` continuously, rather than snapping into place once the
/// swipe settles.
class PillSegmentedControl extends StatefulWidget {
  const PillSegmentedControl({
    super.key,
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  @override
  State<PillSegmentedControl> createState() => _PillSegmentedControlState();
}

class _PillSegmentedControlState extends State<PillSegmentedControl> {
  @override
  void initState() {
    super.initState();
    widget.controller.animation?.addListener(_onAnimate);
  }

  @override
  void didUpdateWidget(covariant PillSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.animation?.removeListener(_onAnimate);
      widget.controller.animation?.addListener(_onAnimate);
    }
  }

  @override
  void dispose() {
    widget.controller.animation?.removeListener(_onAnimate);
    super.dispose();
  }

  void _onAnimate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = widget.labels.length;
    final position =
        widget.controller.animation?.value ??
        widget.controller.index.toDouble();

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppRadius.pillBorder,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / count;
            return Stack(
              children: [
                Positioned(
                  left: position * segmentWidth,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: DecoratedBox(
                    key: const Key('pillSegmentedControl_pill'),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: _Segment(
                          label: widget.labels[i],
                          index: i,
                          selected: widget.controller.index == i,
                          controller: widget.controller,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.index,
    required this.selected,
    required this.controller,
  });

  final String label;
  final int index;
  final bool selected;
  final TabController controller;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  static const _pressScale = 0.98;

  bool _held = false;

  void _setHeld(bool value) {
    if (_held == value) return;
    setState(() => _held = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontFamily: 'Lexend',
      fontSize: 15,
      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
      color: widget.selected
          ? colorScheme.onSurface
          : colorScheme.onSurfaceVariant,
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.selected,
        child: GestureDetector(
          onTap: () => widget.controller.animateTo(widget.index),
          onTapDown: (_) => _setHeld(true),
          onTapUp: (_) => _setHeld(false),
          onTapCancel: () => _setHeld(false),
          child: AnimatedScale(
            scale: _held ? _pressScale : 1.0,
            duration: context.motion(AppMotion.feedback),
            curve: AppMotion.transition,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  widget.label,
                  style: style,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
