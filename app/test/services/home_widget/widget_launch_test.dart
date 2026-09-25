import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/services/home_widget/widget_launch.dart';

void main() {
  _stackTests();

  test('a routine row opens that routine in Timer Mode', () {
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://timer?routineId=abc123')),
      '/routines/abc123/timer',
    );
  });

  test('the empty state only opens the app', () {
    expect(widgetLaunchRoute(Uri.parse('openroutine://open')), isNull);
  });

  test('ignores a tap that names no routine', () {
    expect(widgetLaunchRoute(Uri.parse('openroutine://timer')), isNull);
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://timer?routineId=')),
      isNull,
    );
  });

  test('ignores a URI from anywhere else', () {
    expect(
      widgetLaunchRoute(Uri.parse('https://example.com/timer?routineId=a')),
      isNull,
    );
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://elsewhere?routineId=a')),
      isNull,
    );
  });

  test('percent-encodes a routine id into the path', () {
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://timer?routineId=a%2Fb')),
      '/routines/a%2Fb/timer',
    );
  });
}

// A widget tap has to leave something under the timer: its Close button and
// the back gesture both pop, and popping the only page throws.
void _stackTests() {
  GoRouter router() => GoRouter(
    initialLocation: '/routines',
    routes: [
      GoRoute(path: '/routines', builder: (_, _) => const Text('list')),
      GoRoute(
        path: '/routines/:routineId/timer',
        builder: (context, _) => TextButton(
          onPressed: () => context.pop(),
          child: const Text('close'),
        ),
      ),
    ],
  );

  testWidgets('closing the timer a widget tap opened lands on the list', (
    tester,
  ) async {
    final r = router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: r));

    openWidgetRoute(r, '/routines/abc/timer');
    await tester.pumpAndSettle();
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('a tap while the app is deep in another screen still works', (
    tester,
  ) async {
    final r = router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: r));
    r.push('/routines/other/timer');
    await tester.pumpAndSettle();

    openWidgetRoute(r, '/routines/abc/timer');
    await tester.pumpAndSettle();
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(find.text('list'), findsOneWidget);
  });
}
