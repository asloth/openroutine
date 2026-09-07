import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/routing/app_page.dart';
import 'package:openroutine/theme/motion.dart';

/// Captures a BuildContext with a controllable reduced-motion setting.
Future<BuildContext> _context(
  WidgetTester tester, {
  bool disableAnimations = false,
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

/// Renders the page's transition frozen at [t] and returns the opacity the
/// arriving screen is drawn at. Freezing the animation rather than pumping it
/// lets the curve's shape be asserted directly.
Future<double> _opacityAt(
  WidgetTester tester,
  double t, {
  bool outgoing = false,
}) async {
  final context = await _context(tester);
  final page = appPage(context, key: const ValueKey('dest'), child: const Text('dest'));

  const held = AlwaysStoppedAnimation<double>(1.0);
  final moving = AlwaysStoppedAnimation<double>(t);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (inner) => page.transitionsBuilder(
          inner,
          outgoing ? held : moving,
          outgoing ? moving : held,
          const Text('dest'),
        ),
      ),
    ),
  );

  return tester
      .widget<FadeTransition>(find.byType(FadeTransition).first)
      .opacity
      .value;
}

void main() {
  group('shared page transition', () {
    testWidgets('uses the standard duration', (tester) async {
      final context = await _context(tester);

      expect(appPage(context, key: const ValueKey('p'), child: const SizedBox()).transitionDuration, AppMotion.standard);
    });

    testWidgets('collapses to zero under reduced motion', (tester) async {
      final context = await _context(tester, disableAnimations: true);

      expect(
        appPage(context, key: const ValueKey('p'), child: const SizedBox()).transitionDuration,
        Duration.zero,
      );
    });

    testWidgets('the arriving screen decelerates in', (tester) async {
      // An entrance curve is ahead of linear early: at a quarter of the way
      // through, more than a quarter of the fade has happened.
      expect(await _opacityAt(tester, 0.25), greaterThan(0.25));
    });

    testWidgets('the departing screen accelerates out', (tester) async {
      // The reverse: a quarter of the way out, less than a quarter of the
      // fade has been spent, so the screen is still mostly visible.
      expect(await _opacityAt(tester, 0.25, outgoing: true), greaterThan(0.75));
    });
  });

  group('navigation through a router', () {
    GoRouter buildRouter() => GoRouter(
      initialLocation: '/a',
      routes: [
        GoRoute(
          path: '/a',
          pageBuilder: (context, state) => appPage(
            context,
            key: state.pageKey,
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => context.go('/b'),
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/b',
          pageBuilder: (context, state) => appPage(
            context,
            key: state.pageKey,
            child: const Scaffold(body: Text('arrived')),
          ),
        ),
      ],
    );

    testWidgets('the destination fades in rather than appearing at once', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Present in the tree but still mid-fade, which is the whole point:
      // an instant push would already be fully opaque here.
      final midFade = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((f) => f.opacity.value);
      expect(midFade.any((o) => o > 0 && o < 1), isTrue);

      await tester.pumpAndSettle();
      expect(find.text('arrived'), findsOneWidget);
    });

    testWidgets('under reduced motion the destination arrives immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(routerConfig: buildRouter()),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump();

      expect(find.text('arrived'), findsOneWidget);
    });
  });
}
