import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/tinted/pill_segmented_control.dart';

/// Hosts the control alone, or paired with a `TabBarView` sharing the same
/// controller so swipe-follow behavior can be exercised.
class _Host extends StatefulWidget {
  const _Host({this.withTabBarView = false, this.disableAnimations = false});

  final bool withTabBarView;
  final bool disableAnimations;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Copies the ambient MediaQueryData (which carries the test's text-scale
    // override) rather than constructing a fresh one, so overriding
    // disableAnimations here doesn't silently reset text scale to 1.0.
    final ambient = MediaQueryData.fromView(View.of(context));
    return MediaQuery(
      data: ambient.copyWith(disableAnimations: widget.disableAnimations),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              PillSegmentedControl(
                controller: controller,
                labels: const ['One', 'Two', 'Three'],
              ),
              if (widget.withTabBarView)
                Expanded(
                  child: TabBarView(
                    controller: controller,
                    children: const [
                      Center(child: Text('page 1')),
                      Center(child: Text('page 2')),
                      Center(child: Text('page 3')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

double _pillLeftOf(WidgetTester tester) {
  return tester
      .getTopLeft(find.byKey(const Key('pillSegmentedControl_pill')))
      .dx;
}

void main() {
  group('rendering', () {
    testWidgets('renders a track and one segment per label', (tester) async {
      await tester.pumpWidget(const _Host());

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('track is 48px tall', (tester) async {
      await tester.pumpWidget(const _Host());

      expect(tester.getSize(find.byType(PillSegmentedControl)).height, 48);
    });
  });

  group('interaction', () {
    testWidgets('tapping a segment calls animateTo', (tester) async {
      await tester.pumpWidget(const _Host());

      await tester.tap(find.text('Three'));
      await tester.pumpAndSettle();

      final state = tester.state<_HostState>(find.byType(_Host));
      expect(state.controller.index, 2);
    });
  });

  group('semantics', () {
    testWidgets('reports tab semantics with selection state', (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.pumpAndSettle();

      final selected = tester.getSemantics(find.text('One'));
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);

      final unselected = tester.getSemantics(find.text('Two'));
      expect(unselected.flagsCollection.isSelected, isNot(Tristate.isTrue));
    });
  });

  group('swipe follow', () {
    testWidgets('swiping a paired TabBarView moves the pill mid-gesture', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host(withTabBarView: true));
      await tester.pumpAndSettle();

      final before = _pillLeftOf(tester);

      // Drag partway toward the second page without releasing, so the
      // controller's animation is mid-flight rather than settled.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('page 1')),
      );
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();

      final mid = _pillLeftOf(tester);
      expect(mid, isNot(before));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('text scale', () {
    testWidgets('grows taller rather than clipping at 2.0x text scale', (
      tester,
    ) async {
      final originalScale = tester.platformDispatcher.textScaleFactor;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () =>
            tester.platformDispatcher.textScaleFactorTestValue = originalScale,
      );

      await tester.pumpWidget(const _Host());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(PillSegmentedControl)).height,
        greaterThan(48),
      );
    });
  });

  group('reduced motion', () {
    testWidgets('suppresses the press deform animation', (tester) async {
      await tester.pumpWidget(const _Host(disableAnimations: true));

      final scale = tester.widgetList<AnimatedScale>(
        find.descendant(
          of: find.byType(PillSegmentedControl),
          matching: find.byType(AnimatedScale),
        ),
      );
      for (final s in scale) {
        expect(s.duration, Duration.zero);
      }
    });
  });
}
