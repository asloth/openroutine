import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'floating_nav_bar.dart';

/// Hosts the app's top-level destinations and the floating pill that
/// switches between them.
///
/// The bar carries two destinations, not three: Settings sits behind the gear
/// on the routine list instead. Two labels have room to grow at a large text
/// scale, which is the size this app is actually used at — see
/// `step_template_card_test.dart` for what happens to a label that doesn't.
///
/// Each destination keeps its own `Navigator`, so leaving the routine list
/// part-way into a routine and coming back lands where it was left rather than
/// at the top. That is what `StatefulShellRoute.indexedStack` buys, and the
/// reason this is a shell rather than a `Scaffold` with an index.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // The pill floats over the body rather than reserving its own strip,
      // so the body scrolls under it. `extendBody` is also what makes
      // Scaffold report the pill's rendered height back to the body's
      // `MediaQuery.padding.bottom` — see scaffold.dart's `_BodyBuilder` —
      // which is how a redesigned screen knows how much to pad its list by.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          // A second tap on the current destination sends it back to that
          // branch's root, which is what a bottom bar is expected to do.
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          FloatingNavDestination(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: l10n.navRoutines,
          ),
          FloatingNavDestination(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: l10n.navStats,
          ),
        ],
      ),
    );
  }
}
