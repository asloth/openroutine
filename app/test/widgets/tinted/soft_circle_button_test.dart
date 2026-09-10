import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/tinted/soft_circle_button.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Material _materialOf(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(SoftCircleButton),
      matching: find.byType(Material),
    ),
  );
}

void main() {
  group('sizing', () {
    testWidgets('defaults to 48 with a 22px icon', (tester) async {
      await tester.pumpWidget(
        _host(
          SoftCircleButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
        ),
      );

      final size = tester.getSize(find.byType(SoftCircleButton));
      expect(size.width, 48);
      expect(size.height, 48);
      expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, 22);
    });

    testWidgets('at 64 renders a 24px icon', (tester) async {
      await tester.pumpWidget(
        _host(
          SoftCircleButton(
            icon: Icons.add,
            tooltip: 'Add',
            onPressed: () {},
            size: 64,
          ),
        ),
      );

      final size = tester.getSize(find.byType(SoftCircleButton));
      expect(size.width, 64);
      expect(size.height, 64);
      expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, 24);
    });

    testWidgets('never renders a hit target below 48', (tester) async {
      await tester.pumpWidget(
        _host(
          SoftCircleButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
        ),
      );

      final size = tester.getSize(find.byType(SoftCircleButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('styles', () {
    testWidgets('neutral uses surfaceContainer fill and onSurface icon', (
      tester,
    ) async {
      final theme = AppTheme.light();
      await tester.pumpWidget(
        _host(
          SoftCircleButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
        ),
      );

      expect(_materialOf(tester).color, theme.colorScheme.surfaceContainer);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.add)).color,
        theme.colorScheme.onSurface,
      );
    });

    testWidgets(
      'accent uses primaryContainer fill and onPrimaryContainer icon',
      (tester) async {
        final theme = AppTheme.light();
        await tester.pumpWidget(
          _host(
            SoftCircleButton(
              icon: Icons.add,
              tooltip: 'Add',
              onPressed: () {},
              style: SoftCircleButtonStyle.accent,
            ),
          ),
        );

        expect(_materialOf(tester).color, theme.colorScheme.primaryContainer);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.add)).color,
          theme.colorScheme.onPrimaryContainer,
        );
      },
    );
  });

  group('interaction', () {
    testWidgets('invokes onPressed once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SoftCircleButton(
            icon: Icons.add,
            tooltip: 'Add',
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(SoftCircleButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('exposes its tooltip', (tester) async {
      await tester.pumpWidget(
        _host(
          SoftCircleButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
        ),
      );

      expect(find.byTooltip('Add'), findsOneWidget);
    });
  });

  group('press deform', () {
    testWidgets('deforms by no more than 5% while held', (tester) async {
      await tester.pumpWidget(
        _host(
          SoftCircleButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SoftCircleButton)),
      );
      await tester.pump(const Duration(milliseconds: 150));

      final scale = tester
          .widget<AnimatedScale>(
            find.descendant(
              of: find.byType(SoftCircleButton),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale;
      expect(scale, greaterThanOrEqualTo(0.95));
      expect(scale, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('suppresses the deform animation under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SoftCircleButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
          disableAnimations: true,
        ),
      );

      final scale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(SoftCircleButton),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(scale.duration, Duration.zero);
    });
  });
}
