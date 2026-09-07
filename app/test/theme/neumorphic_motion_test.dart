import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/motion.dart';
import 'package:openroutine/theme/theme.dart';

/// Wraps a control in enough app scaffolding that the neumorphic theme
/// extension resolves, with the reduced-motion flag under test control.
Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

AnimatedContainer _containerIn(WidgetTester tester, Type control) {
  return tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(control),
      matching: find.byType(AnimatedContainer),
    ),
  );
}

void main() {
  const circle = NeumorphicCircleButton(
    icon: Icons.play_arrow,
    onPressed: _noop,
    tooltip: 'Play',
  );
  const pill = NeumorphicPillButton(
    label: 'Start',
    icon: Icons.play_arrow,
    onPressed: _noop,
  );

  group('press animation easing', () {
    // AnimatedContainer defaults to Curves.linear when no curve is given.
    // Linear is reserved for progress indicators; a control depicting a press
    // is an object moving, so it must not use it.
    testWidgets('the circle button does not animate linearly', (tester) async {
      await tester.pumpWidget(_host(circle));

      expect(
        _containerIn(tester, NeumorphicCircleButton).curve,
        isNot(Curves.linear),
      );
    });

    testWidgets('the pill button does not animate linearly', (tester) async {
      await tester.pumpWidget(_host(pill));

      expect(
        _containerIn(tester, NeumorphicPillButton).curve,
        isNot(Curves.linear),
      );
    });
  });

  group('press deformation', () {
    double scaleIn(WidgetTester tester, Type control) {
      return tester
          .widget<AnimatedScale>(
            find.descendant(
              of: find.byType(control),
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale;
    }

    Future<void> expectDeforms(WidgetTester tester, Widget control) async {
      await tester.pumpWidget(_host(control));
      final type = control.runtimeType;

      expect(scaleIn(tester, type), 1.0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(type)),
      );
      // The circle button sits inside a Tooltip, whose long-press recognizer
      // competes in the gesture arena. With a competitor present the tap
      // recognizer holds onTapDown until kPressTimeout (100ms) rather than
      // firing at once, so a single pump is not enough to observe the press.
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        scaleIn(tester, type),
        AppMotion.pressScale,
        reason: 'a control that does not deform on press feels dead',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scaleIn(tester, type), 1.0);
    }

    testWidgets('the circle button deforms while held', (tester) async {
      await expectDeforms(tester, circle);
    });

    testWidgets('the pill button deforms while held', (tester) async {
      await expectDeforms(tester, pill);
    });
  });

  group('reduced motion', () {
    Future<void> expectSuppressed(WidgetTester tester, Widget control) async {
      await tester.pumpWidget(_host(control, disableAnimations: true));
      final type = control.runtimeType;

      expect(_containerIn(tester, type).duration, Duration.zero);
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byType(type),
                matching: find.byType(AnimatedScale),
              ),
            )
            .duration,
        Duration.zero,
      );
    }

    testWidgets('the circle button suppresses its press animation', (
      tester,
    ) async {
      await expectSuppressed(tester, circle);
    });

    testWidgets('the pill button suppresses its press animation', (
      tester,
    ) async {
      await expectSuppressed(tester, pill);
    });
  });
}

void _noop() {}
