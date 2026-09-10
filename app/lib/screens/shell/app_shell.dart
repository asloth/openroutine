import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Hosts the app's top-level destinations and the bar that switches between
/// them.
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
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // `initialLocation: true` sends a second tap on the current
        // destination back to that branch's root, which is what a bottom bar
        // is expected to do.
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l10n.navRoutines,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.navStats,
          ),
        ],
      ),
    );
  }
}
