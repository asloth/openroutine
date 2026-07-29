import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'screens/import/import_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/routine_detail/routine_detail_screen.dart';
import 'screens/routine_form/routine_form_screen.dart';
import 'screens/routines_list/routines_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/step_form/step_form_screen.dart';
import 'state/app_prefs_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const OpenRoutineApp(),
    ),
  );
}

/// Redirect reads onboardingComplete via ref.read (not watch) so this
/// provider — and the GoRouter instance it builds — stays stable across the
/// app's lifetime; only the per-navigation redirect check needs the latest
/// value, not a full router rebuild.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/routines',
    redirect: (context, state) {
      final onboardingComplete = ref.read(onboardingCompleteProvider);
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!onboardingComplete && !goingToOnboarding) return '/onboarding';
      if (onboardingComplete && goingToOnboarding) return '/routines';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/routines',
        builder: (context, state) => const RoutinesListScreen(),
      ),
      GoRoute(
        path: '/routines/new',
        builder: (context, state) => const RoutineFormScreen(),
      ),
      GoRoute(
        path: '/routines/:routineId',
        builder: (context, state) =>
            RoutineDetailScreen(routineId: state.pathParameters['routineId']!),
      ),
      GoRoute(
        path: '/routines/:routineId/edit',
        builder: (context, state) =>
            RoutineFormScreen(routineId: state.pathParameters['routineId']),
      ),
      GoRoute(
        path: '/routines/:routineId/steps/new',
        builder: (context, state) =>
            StepFormScreen(routineId: state.pathParameters['routineId']!),
      ),
      GoRoute(
        path: '/routines/:routineId/steps/:stepId/edit',
        builder: (context, state) => StepFormScreen(
          routineId: state.pathParameters['routineId']!,
          stepId: state.pathParameters['stepId'],
        ),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class OpenRoutineApp extends ConsumerWidget {
  const OpenRoutineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final localeOverride = ref.watch(localeOverrideSettingProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeOverride != null ? Locale(localeOverride) : null,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: router,
    );
  }
}
