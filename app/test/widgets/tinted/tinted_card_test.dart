import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/spacing.dart';
import 'package:openroutine/widgets/tinted/tinted_card.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  const fill = Color(0xFFEDE5D9);
  const foreground = Color(0xFF2E2822);

  group('surface', () {
    testWidgets('fills with color and casts no shadow', (tester) async {
      await tester.pumpWidget(
        _host(
          const TintedCard(
            color: fill,
            foregroundColor: foreground,
            child: Text('hello'),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TintedCard),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, fill);
      expect(material.elevation, 0);
      expect(material.shadowColor == null || material.elevation == 0, isTrue);
    });

    testWidgets('defaults to AppRadius.tinted', (tester) async {
      await tester.pumpWidget(
        _host(
          const TintedCard(
            color: fill,
            foregroundColor: foreground,
            child: Text('hello'),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TintedCard),
          matching: find.byType(Material),
        ),
      );
      expect(material.borderRadius, AppRadius.tintedBorder);
    });

    testWidgets('applies foregroundColor to text and icons', (tester) async {
      await tester.pumpWidget(
        _host(
          const TintedCard(
            color: fill,
            foregroundColor: foreground,
            child: Row(children: [Icon(Icons.star), Text('hello')]),
          ),
        ),
      );

      final textStyle = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('hello'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(textStyle.color, foreground);

      final iconTheme = IconTheme.of(tester.element(find.byIcon(Icons.star)));
      expect(iconTheme.color, foreground);
    });
  });

  group('tap behavior', () {
    testWidgets('invokes onTap once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          TintedCard(
            color: fill,
            foregroundColor: foreground,
            onTap: () => taps++,
            child: const Text('hello'),
          ),
        ),
      );

      await tester.tap(find.byType(TintedCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('reports button semantics when tappable', (tester) async {
      await tester.pumpWidget(
        _host(
          TintedCard(
            color: fill,
            foregroundColor: foreground,
            onTap: () {},
            child: const Text('hello'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TintedCard));
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('does not report button semantics without onTap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const TintedCard(
            color: fill,
            foregroundColor: foreground,
            child: Text('hello'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TintedCard));
      expect(semantics.flagsCollection.isButton, isFalse);
    });
  });

  group('press deform', () {
    testWidgets('deforms by no more than 5% while held', (tester) async {
      await tester.pumpWidget(
        _host(
          TintedCard(
            color: fill,
            foregroundColor: foreground,
            onTap: () {},
            child: const Text('hello'),
          ),
        ),
      );

      final scale0 = tester
          .widget<AnimatedScale>(
            find.descendant(
              of: find.byType(TintedCard),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale;
      expect(scale0, 1.0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TintedCard)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final scale1 = tester
          .widget<AnimatedScale>(
            find.descendant(
              of: find.byType(TintedCard),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale;
      expect(scale1, greaterThanOrEqualTo(0.95));
      expect(scale1, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('suppresses the deform animation under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          TintedCard(
            color: fill,
            foregroundColor: foreground,
            onTap: () {},
            child: const Text('hello'),
          ),
          disableAnimations: true,
        ),
      );

      final scale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(TintedCard),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(scale.duration, Duration.zero);
    });
  });

  group('text scale', () {
    testWidgets('does not overflow at 2.0x text scale', (tester) async {
      final originalScale = tester.platformDispatcher.textScaleFactor;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () =>
            tester.platformDispatcher.textScaleFactorTestValue = originalScale,
      );

      await tester.pumpWidget(
        _host(
          const TintedCard(
            color: fill,
            foregroundColor: foreground,
            child: Text(
              'A fairly long line of text that must not overflow its card',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
