import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/motion.dart';

void main() {
  group('duration tokens', () {
    test('every user-initiated duration completes within 300ms', () {
      expect(AppMotion.userInitiated, isNotEmpty);
      for (final duration in AppMotion.userInitiated) {
        expect(
          duration.inMilliseconds,
          lessThanOrEqualTo(300),
          reason: 'user-initiated motion must resolve within 300ms',
        );
      }
    });
  });

  group('curve tokens', () {
    // A decelerating curve is ahead of linear early and behind it late; an
    // accelerating curve is the mirror. Sampling either side of the midpoint
    // proves the shape without pinning the token to one named curve.
    test('the entrance curve decelerates into place', () {
      expect(AppMotion.entrance.transform(0.25), greaterThan(0.25));
      expect(AppMotion.entrance.transform(0.75), greaterThan(0.75));
    });

    test('the exit curve accelerates away', () {
      expect(AppMotion.exit.transform(0.25), lessThan(0.25));
      expect(AppMotion.exit.transform(0.75), lessThan(0.75));
    });

    test('progress is the only linear token', () {
      expect(AppMotion.progress.transform(0.25), closeTo(0.25, 1e-9));
      expect(AppMotion.progress.transform(0.75), closeTo(0.75, 1e-9));

      expect(AppMotion.objectCurves, isNotEmpty);
      for (final curve in AppMotion.objectCurves) {
        final departsFromLinear =
            (curve.transform(0.25) - 0.25).abs() > 1e-3 ||
            (curve.transform(0.75) - 0.75).abs() > 1e-3;
        expect(
          departsFromLinear,
          isTrue,
          reason: 'a curve depicting an object moving must not be linear',
        );
      }
    });
  });

  group('physics tokens', () {
    test('press feedback deforms subtly', () {
      expect(AppMotion.pressScale, greaterThanOrEqualTo(0.95));
      expect(AppMotion.pressScale, lessThanOrEqualTo(1.05));
      expect(
        AppMotion.pressScale,
        isNot(1.0),
        reason: 'a control that does not deform on press feels dead',
      );
    });

    test('stagger stays within the grouping budget', () {
      expect(AppMotion.stagger.inMilliseconds, lessThanOrEqualTo(50));
      expect(AppMotion.stagger.inMilliseconds, greaterThan(0));
    });

    test('the overshoot spring is underdamped', () {
      final spring = AppMotion.overshoot;
      // Damping ratio below 1 is what makes a spring overshoot and settle
      // rather than merely easing to a stop.
      final dampingRatio =
          spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));
      expect(dampingRatio, lessThan(1.0));
      expect(
        dampingRatio,
        greaterThan(0.3),
        reason: 'too little damping oscillates visibly instead of settling',
      );
    });
  });

  group('reduced motion', () {
    Future<BuildContext> pumpContext(
      WidgetTester tester, {
      required bool disableAnimations,
    }) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('every duration collapses to zero when animations are '
        'disabled', (tester) async {
      final context = await pumpContext(tester, disableAnimations: true);

      for (final duration in [...AppMotion.userInitiated, AppMotion.stagger]) {
        expect(context.motion(duration), Duration.zero);
      }
    });

    testWidgets('durations are unchanged when no preference is set', (
      tester,
    ) async {
      final context = await pumpContext(tester, disableAnimations: false);

      for (final duration in [...AppMotion.userInitiated, AppMotion.stagger]) {
        expect(context.motion(duration), duration);
      }
    });

    /// Taps the trigger and returns the box width once the frame that applies
    /// the change has been rendered. Deliberately not `pumpAndSettle`, which
    /// would wait out a real animation and make the assertion vacuous.
    Future<double> widthAfterChange(
      WidgetTester tester, {
      required bool disableAnimations,
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: _Resizing(),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(_Resizing.boxKey)).width, 100);

      await tester.tap(find.byKey(_Resizing.triggerKey));
      await tester.pump();
      await tester.pump();

      return tester.getSize(find.byKey(_Resizing.boxKey)).width;
    }

    testWidgets('an animated change lands on its end state without waiting out '
        'a transition', (tester) async {
      expect(await widthAfterChange(tester, disableAnimations: true), 200);
    });

    testWidgets('the same change is still in flight when motion is allowed', (
      tester,
    ) async {
      // The contrast case: without it the assertion above could pass simply
      // because the animation is fast, rather than because it was suppressed.
      expect(
        await widthAfterChange(tester, disableAnimations: false),
        lessThan(200),
      );
    });
  });
}

/// A minimal animated surface used to prove the reduced-motion contract from
/// the outside: the end state must be rendered without waiting out a
/// transition.
class _Resizing extends StatefulWidget {
  const _Resizing();

  static const boxKey = Key('resizing-box');
  static const triggerKey = Key('resizing-trigger');

  @override
  State<_Resizing> createState() => _ResizingState();
}

class _ResizingState extends State<_Resizing> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          key: _Resizing.boxKey,
          duration: context.motion(AppMotion.standard),
          curve: AppMotion.transition,
          width: _expanded ? 200 : 100,
          height: 20,
        ),
        GestureDetector(
          key: _Resizing.triggerKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = true),
          child: const SizedBox(width: 50, height: 50),
        ),
      ],
    );
  }
}
