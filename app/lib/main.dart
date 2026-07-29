import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';

/// M1 skeleton entrypoint.
///
/// This is intentionally minimal: a single placeholder route wired through
/// go_router, Riverpod's [ProviderScope], and generated localizations. Real
/// screens, state, and storage land in M2+ (see docs/SPEC.md §12).
void main() {
  runApp(const ProviderScope(child: OpenRoutineApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _SkeletonHomeScreen(),
    ),
  ],
);

class OpenRoutineApp extends StatelessWidget {
  const OpenRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: _router,
    );
  }
}

class _SkeletonHomeScreen extends StatelessWidget {
  const _SkeletonHomeScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.skeletonPlaceholderMessage)),
    );
  }
}
