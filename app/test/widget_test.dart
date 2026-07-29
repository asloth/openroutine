// M1 smoke test: the skeleton app boots, wires up Riverpod + go_router +
// localizations, and renders the placeholder screen's localized strings.
// Real screen tests land alongside their screens starting in M2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/main.dart';

void main() {
  testWidgets('renders the localized app title and placeholder message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: OpenRoutineApp()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.appTitle), findsWidgets);
    expect(find.text(l10n.skeletonPlaceholderMessage), findsOneWidget);
  });
}
