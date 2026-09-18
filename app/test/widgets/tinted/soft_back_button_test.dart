import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/widgets/tinted/soft_back_button.dart';
import 'package:openroutine/widgets/tinted/soft_circle_button.dart';

void main() {
  testWidgets('renders a SoftCircleButton with the chevron-left icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SoftBackButton())),
    );

    final button = tester.widget<SoftCircleButton>(
      find.byType(SoftCircleButton),
    );
    expect(button.icon, Icons.chevron_left);
  });

  testWidgets('exposes the platform back-button tooltip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SoftBackButton())),
    );

    final context = tester.element(find.byType(SoftBackButton));
    final tooltip = MaterialLocalizations.of(context).backButtonTooltip;

    expect(find.byTooltip(tooltip), findsOneWidget);
  });

  testWidgets('pops the route by default when tapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(body: SoftBackButton()),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(SoftBackButton), findsOneWidget);

    await tester.tap(find.byType(SoftBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(SoftBackButton), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('runs a custom onPressed instead of popping when given one', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SoftBackButton(onPressed: () => taps++)),
      ),
    );

    await tester.tap(find.byType(SoftBackButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.byType(SoftBackButton), findsOneWidget);
  });
}
