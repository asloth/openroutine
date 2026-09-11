// The selected destination's highlight: a wide pill that fully holds its
// icon and label, rather than the near-square shape a label used to poke out
// of at both bottom corners. See
// openspec/changes/fix-nav-highlight/specs/floating-nav/spec.md.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/screens/shell/floating_nav_bar.dart';

const _destinations = [
  FloatingNavDestination(
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
    label: 'Routines',
  ),
  FloatingNavDestination(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    label: 'Statistics',
  ),
];

/// The Spanish labels, used only to check that the longer "Estadísticas"
/// still fits the bar on a narrow phone. `FloatingNavBar` takes plain
/// strings, so this stands in for the localized copy without pulling in the
/// full localization delegate.
const _spanishDestinations = [
  FloatingNavDestination(
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
    label: 'Rutinas',
  ),
  FloatingNavDestination(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    label: 'Estadísticas',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  List<FloatingNavDestination> destinations,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      bottomNavigationBar: FloatingNavBar(
        currentIndex: 0,
        destinations: destinations,
        onDestinationSelected: (_) {},
      ),
    ),
  ),
);

/// The `AnimatedContainer` that paints the selected fill, found from the
/// selected destination's own label so the unselected (transparent) one
/// never gets picked up by mistake.
Finder _highlightFor(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(AnimatedContainer),
);

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets(
      'the selected highlight is a wide pill that holds its label at ${scale}x',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pump(tester, _destinations);
        await tester.pumpAndSettle();

        final highlight = tester.getRect(_highlightFor('Routines'));
        final label = tester.getRect(find.text('Routines'));

        expect(
          highlight.width,
          greaterThan(highlight.height),
          reason: 'the highlight should read as a pill, not a circle',
        );
        expect(
          highlight.left,
          lessThan(label.left),
          reason: "the pill needs breathing room left of the label",
        );
        expect(
          highlight.right,
          greaterThan(label.right),
          reason: "the pill needs breathing room right of the label",
        );
      },
    );
  }

  testWidgets('the bar fits a 360dp phone at 1.6x with the Spanish labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, _spanishDestinations);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final pill = tester.getRect(find.byKey(FloatingNavBar.pillKey));
    expect(pill.left, greaterThanOrEqualTo(0));
    expect(pill.right, lessThanOrEqualTo(360));
  });
}
