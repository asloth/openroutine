import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'services/app_prefs.dart';
import 'services/home_widget/widget_launch.dart';
import 'screens/import/import_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/routine_detail/routine_detail_screen.dart';
import 'screens/routine_form/routine_form_screen.dart';
import 'screens/routines_list/routines_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/step_form/step_form_screen.dart';
import 'screens/timer/timer_screen.dart';
import 'models/completion_log.dart';
import 'state/app_prefs_provider.dart';
import 'state/home_widget_provider.dart';
import 'state/timer_provider.dart';
import 'state/sync_provider.dart';
import 'routing/app_page.dart';
import 'theme/theme.dart';

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
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/routines',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: const RoutinesListScreen(),
        ),
      ),
      GoRoute(
        path: '/routines/new',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: const RoutineFormScreen(),
        ),
      ),
      GoRoute(
        path: '/routines/:routineId',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: RoutineDetailScreen(
            routineId: state.pathParameters['routineId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/routines/:routineId/edit',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: RoutineFormScreen(
            routineId: state.pathParameters['routineId'],
          ),
        ),
      ),
      GoRoute(
        path: '/routines/:routineId/timer',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: TimerScreen(
            routineId: state.pathParameters['routineId']!,
            mode: state.uri.queryParameters['mode'] == 'low'
                ? RunMode.low
                : RunMode.full,
            plannedStepIds: state.uri.queryParameters['steps']?.split(','),
          ),
        ),
      ),
      GoRoute(
        path: '/routines/:routineId/steps/new',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: StepFormScreen(routineId: state.pathParameters['routineId']!),
        ),
      ),
      GoRoute(
        path: '/routines/:routineId/steps/:stepId/edit',
        pageBuilder: (context, state) => appPage(
          context,
          key: state.pageKey,
          child: StepFormScreen(
            routineId: state.pathParameters['routineId']!,
            stepId: state.pathParameters['stepId'],
          ),
        ),
      ),
      GoRoute(
        path: '/import',
        pageBuilder: (context, state) =>
            appPage(context, key: state.pageKey, child: const ImportScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            appPage(context, key: state.pageKey, child: const SettingsScreen()),
      ),
    ],
  );
});

/// Keeps app lifecycle tests independent from OAuth and the network while the
/// production callback still resolves the current sync controller.
final foregroundSyncCallbackProvider = Provider<Future<void> Function()>((ref) {
  return ref.read(syncControllerProvider.notifier).syncNow;
});

class OpenRoutineApp extends ConsumerStatefulWidget {
  const OpenRoutineApp({super.key});

  @override
  ConsumerState<OpenRoutineApp> createState() => _OpenRoutineAppState();
}

class _OpenRoutineAppState extends ConsumerState<OpenRoutineApp> {
  AppLifecycleListener? _lifecycle;
  StreamSubscription<Uri?>? _widgetTaps;

  /// The URI that launched the app from the home screen widget, held until the
  /// click stream has had its chance to deliver the same tap a second time.
  String? _launchUri;

  @override
  void initState() {
    super.initState();
    // docs/SPEC.md §5 syncs on app open and on returning to the foreground.
    // Both are deferred past the first frame: restoring a Drive grant is a
    // platform-channel round trip, and startup should not wait on it to draw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Platform.isAndroid rather than defaultTargetPlatform: this reaches for
      // a plugin, and widget tests run with an Android target platform on a
      // host that has no plugins registered.
      if (Platform.isAndroid) {
        unawaited(_openInitialWidgetTap());
        _widgetTaps = HomeWidget.widgetClicked.listen(
          _openFromWidgetTap,
          onError: (Object _) {},
        );
      }
      _lifecycle = AppLifecycleListener(
        onResume: () {
          if (ref.read(storageModeSettingProvider) != StorageMode.drive) return;
          unawaited(ref.read(foregroundSyncCallbackProvider)());
        },
      );
      if (ref.read(storageModeSettingProvider) != StorageMode.drive) return;
      unawaited(ref.read(syncControllerProvider.notifier).restore());
    });
  }

  /// A tap that started the app from cold: the URI is waiting rather than
  /// arriving on the stream, because the stream did not exist yet.
  Future<void> _openInitialWidgetTap() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri == null) return;
      _launchUri = uri.toString();
      _goToWidgetRoute(uri);
    } catch (error) {
      debugPrint('Home widget launch ignored: $error');
    }
  }

  void _openFromWidgetTap(Uri? uri) {
    if (uri == null) return;
    // A cold-start tap can surface twice, once as the launch URI and once on
    // the stream. Drop that echo — but only the first one, since tapping the
    // same routine again later is a real request.
    final echo = _launchUri == uri.toString();
    _launchUri = null;
    if (echo) return;
    _goToWidgetRoute(uri);
  }

  void _goToWidgetRoute(Uri uri) {
    if (!mounted) return;
    final route = widgetLaunchRoute(uri);
    if (route == null) return;
    ref.read(goRouterProvider).go(route);
  }

  @override
  void dispose() {
    unawaited(_widgetTaps?.cancel());
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    // Tapping a routine reminder should land on that routine. The service
    // cannot know about routing, so the wiring happens here, where both exist.
    ref.read(notificationServiceProvider).onOpenRoutine = (routineId) =>
        router.go('/routines/$routineId');
    // Keeps the home screen widget in step with the routine list for the whole
    // session. Watched here rather than from the routines list because a Drive
    // sync can change the list while any screen is on top — or none.
    ref.watch(homeWidgetSyncProvider);
    final localeOverride = ref.watch(localeOverrideSettingProvider);
    final palette = ref.watch(paletteSettingProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeOverride != null ? Locale(localeOverride) : null,
      theme: AppTheme.light(palette),
      darkTheme: AppTheme.dark(palette),
      routerConfig: router,
    );
  }
}
