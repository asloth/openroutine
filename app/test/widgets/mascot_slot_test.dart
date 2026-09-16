import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/mascot_slot.dart';

/// The pet itself is a Rive file, and `rive_native` is not loaded in a widget
/// test, so these cover the contract around it: the slot fills its space, it
/// comes to rest, and it stays out of the semantics tree unless asked.
void main() {
  Widget host(Widget child, {Palette? palette}) => MaterialApp(
    theme: AppTheme.light(palette ?? Palette.inkIris),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('fills the size it is given and settles', (tester) async {
    await tester.pumpWidget(host(const MascotSlot(size: 96)));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(MascotSlot)), const Size(96, 96));
  });

  testWidgets('draws something for every mood', (tester) async {
    for (final mood in MascotMood.values) {
      await tester.pumpWidget(host(MascotSlot(mood: mood, size: 72)));
      await tester.pumpAndSettle();

      expect(find.byType(MascotSlot), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('is decorative unless it is given a label', (tester) async {
    await tester.pumpWidget(host(const MascotSlot(size: 64)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Pet'), findsNothing);

    await tester.pumpWidget(
      host(const MascotSlot(size: 64, semanticLabel: 'Pet')),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Pet'), findsOneWidget);
  });

  testWidgets('holds still when the system asks for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(const MascotSlot(size: 80)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
