import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/tinted/section_label.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('uppercases its text', (tester) async {
    await tester.pumpWidget(_host(const SectionLabel('scheduled')));

    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('scheduled'), findsNothing);
  });

  testWidgets('renders sectionLabel style and onSurfaceVariant color', (
    tester,
  ) async {
    final theme = AppTheme.light();
    await tester.pumpWidget(_host(const SectionLabel('flexible')));

    final text = tester.widget<Text>(find.text('FLEXIBLE'));
    expect(text.style?.fontSize, AppTypography.sectionLabel.fontSize);
    expect(text.style?.letterSpacing, AppTypography.sectionLabel.letterSpacing);
    expect(text.style?.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('insets 8px horizontally', (tester) async {
    await tester.pumpWidget(
      _host(
        const Padding(
          padding: EdgeInsets.zero,
          child: Align(
            alignment: Alignment.topLeft,
            child: SectionLabel('flexible'),
          ),
        ),
      ),
    );

    final labelLeft = tester.getTopLeft(find.byType(SectionLabel)).dx;
    final textLeft = tester.getTopLeft(find.text('FLEXIBLE')).dx;
    expect(textLeft - labelLeft, 8);
  });

  testWidgets('does not overflow at 2.0x text scale', (tester) async {
    final originalScale = tester.platformDispatcher.textScaleFactor;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(
      () => tester.platformDispatcher.textScaleFactorTestValue = originalScale,
    );

    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 200,
          child: SectionLabel('a considerably longer section label'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
