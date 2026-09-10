import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/typography.dart';
import 'package:openroutine/widgets/tinted/page_header.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('layout', () {
    testWidgets('renders 48px tall', (tester) async {
      await tester.pumpWidget(_host(const PageHeader(title: 'Routines')));

      expect(tester.getSize(find.byType(PageHeader)).height, 48);
    });

    testWidgets('renders no AppBar, elevation, or shadow', (tester) async {
      await tester.pumpWidget(
        _host(
          PageHeader(
            title: 'Routines',
            actions: [
              IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
            ],
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.byType(Material),
        ),
      );
      for (final material in materials) {
        expect(material.elevation, 0);
      }
    });

    testWidgets('renders title in pageTitle style, left-aligned', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const PageHeader(title: 'Routines')));

      final text = tester.widget<Text>(find.text('Routines'));
      expect(text.style?.fontSize, AppTypography.pageTitle.fontSize);
      expect(text.textAlign, isNot(TextAlign.right));
      expect(text.textAlign, isNot(TextAlign.center));
    });

    testWidgets('spaces actions 8px apart', (tester) async {
      await tester.pumpWidget(
        _host(
          PageHeader(
            actions: [
              IconButton(
                key: const Key('a'),
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              IconButton(
                key: const Key('b'),
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      final aRight = tester.getTopRight(find.byKey(const Key('a'))).dx;
      final bLeft = tester.getTopLeft(find.byKey(const Key('b'))).dx;
      expect(bLeft - aRight, 8);
    });
  });

  group('text scale', () {
    testWidgets('wraps the title instead of overflowing at 2.0x', (
      tester,
    ) async {
      final originalScale = tester.platformDispatcher.textScaleFactor;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () =>
            tester.platformDispatcher.textScaleFactorTestValue = originalScale,
      );

      await tester.pumpWidget(
        _host(
          const PageHeader(
            title: 'A considerably longer page title than usual',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
