import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/widgets/tinted/segmented_progress.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, child: child)),
  );
}

List<Container> _segments(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(SegmentedProgress),
          matching: find.byType(Container),
        ),
      )
      .toList();
}

Color? _colorOf(Container c) => (c.decoration as BoxDecoration?)?.color;

void main() {
  const color = Color(0xFFA9502F);

  testWidgets('renders count segments', (tester) async {
    await tester.pumpWidget(
      _host(const SegmentedProgress(count: 5, filled: 2, color: color)),
    );

    expect(_segments(tester).length, 5);
  });

  testWidgets('filled segments use 0.7 opacity, the rest 0.15', (tester) async {
    await tester.pumpWidget(
      _host(const SegmentedProgress(count: 5, filled: 2, color: color)),
    );

    final segments = _segments(tester);
    final filledColor = color.withValues(alpha: 0.7);
    final unfilledColor = color.withValues(alpha: 0.15);

    final filledCount = segments
        .where((s) => _colorOf(s) == filledColor)
        .length;
    final unfilledCount = segments
        .where((s) => _colorOf(s) == unfilledColor)
        .length;

    expect(filledCount, 2);
    expect(unfilledCount, 3);
  });

  testWidgets('segments are 6 tall with radius 3', (tester) async {
    await tester.pumpWidget(
      _host(const SegmentedProgress(count: 3, filled: 1, color: color)),
    );

    for (final segment in _segments(tester)) {
      expect(
        segment.constraints?.maxHeight ??
            tester.getSize(find.byWidget(segment)).height,
        6,
      );
      final decoration = segment.decoration as BoxDecoration;
      expect((decoration.borderRadius as BorderRadius?)?.topLeft.x, 3);
    }
  });

  testWidgets('uses a 4px gap past eight segments, 6px at or below', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const SegmentedProgress(count: 8, filled: 4, color: color)),
    );
    final eight = _segments(tester);
    final gap8 =
        tester.getTopLeft(find.byWidget(eight[1])).dx -
        tester.getTopRight(find.byWidget(eight[0])).dx;
    expect(gap8, 6);

    await tester.pumpWidget(
      _host(const SegmentedProgress(count: 9, filled: 4, color: color)),
    );
    final nine = _segments(tester);
    final gap9 =
        tester.getTopLeft(find.byWidget(nine[1])).dx -
        tester.getTopRight(find.byWidget(nine[0])).dx;
    expect(gap9, 4);
  });

  testWidgets('exposes a semantics label', (tester) async {
    await tester.pumpWidget(
      _host(
        const SegmentedProgress(
          count: 4,
          filled: 1,
          color: color,
          semanticsLabel: '1 of 4 steps done',
        ),
      ),
    );

    expect(find.bySemanticsLabel('1 of 4 steps done'), findsOneWidget);
  });

  testWidgets('fits within its available width without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const SegmentedProgress(count: 12, filled: 6, color: color)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
