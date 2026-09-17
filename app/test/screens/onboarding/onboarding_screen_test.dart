import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/onboarding/onboarding_screen.dart';
import 'package:openroutine/services/app_prefs.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/widgets/mascot_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stubs stand in for Today and the builder, and print the full location so a
/// test can see the query the builder was opened with.
GoRouter _router() {
  Widget stub(GoRouterState state) => Scaffold(body: Text('at ${state.uri}'));
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/routines', builder: (context, state) => stub(state)),
      GoRoute(path: '/routines/new', builder: (context, state) => stub(state)),
    ],
  );
}

Future<(GoRouter, SharedPreferences, AppLocalizations)> _pump(
  WidgetTester tester, {
  Size size = const Size(1170, 2532),
}) async {
  // Tall enough that every beat, its demo, and the stage fit without a
  // scroll, like a phone.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = _router();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(
    tester.element(find.byType(OnboardingScreen)),
  )!;
  return (router, prefs, l10n);
}

MascotReaction? _lastMove(WidgetTester tester) =>
    tester.widget<MascotSlot>(find.byType(MascotSlot)).cue?.reaction;

Future<void> _next(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the story opens on the hello beat, and the pet waves', (
    tester,
  ) async {
    final (_, _, l10n) = await _pump(tester);

    expect(find.text(l10n.onboardingHelloTitle), findsOneWidget);
    expect(find.text(l10n.onboardingHelloFootnote), findsOneWidget);
    expect(find.text(l10n.onboardingGetStarted), findsOneWidget);
    expect(_lastMove(tester), MascotReaction.wave);
  });

  // A phone held sideways has little height to spare. The words still have
  // to fit beside the pet instead of being squeezed out by its stage.
  testWidgets('in landscape the words stay visible beside the pet', (
    tester,
  ) async {
    final (_, _, l10n) = await _pump(tester, size: const Size(2424, 1080));

    final title = tester.getRect(find.text(l10n.onboardingHelloTitle));
    final pet = tester.getRect(find.byType(MascotSlot));
    expect(title.height, greaterThan(30));
    expect(title.right, lessThanOrEqualTo(pet.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the beats play in order, each with its own move', (
    tester,
  ) async {
    final (_, _, l10n) = await _pump(tester);

    await _next(tester, l10n.onboardingGetStarted);
    expect(find.text(l10n.onboardingScheduledTitle), findsOneWidget);
    expect(find.text(l10n.onboardingScheduledDemoName), findsOneWidget);
    expect(_lastMove(tester), MascotReaction.jump);

    await _next(tester, l10n.onboardingNext);
    expect(find.text(l10n.onboardingFlexibleTitle), findsOneWidget);
    expect(_lastMove(tester), MascotReaction.bounce);

    await _next(tester, l10n.onboardingNext);
    expect(find.text(l10n.onboardingStepsTitle), findsOneWidget);
    expect(find.text(l10n.onboardingStepsDone), findsOneWidget);
    expect(find.text(l10n.onboardingStepsSkipped), findsOneWidget);
    expect(_lastMove(tester), MascotReaction.skip);

    await _next(tester, l10n.onboardingNext);
    expect(find.text(l10n.onboardingCreateTitle), findsOneWidget);
    expect(find.text(l10n.onboardingCreateScheduled), findsOneWidget);
    expect(find.text(l10n.onboardingCreateFlexible), findsOneWidget);
    expect(_lastMove(tester), MascotReaction.celebrate);
  });

  testWidgets('the scheduled beat runs the pet in before it jumps', (
    tester,
  ) async {
    final (_, _, l10n) = await _pump(tester);

    await tester.tap(find.text(l10n.onboardingGetStarted));
    // Past the page turn, before the bell.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_lastMove(tester), MascotReaction.run);

    await tester.pumpAndSettle();
    expect(_lastMove(tester), MascotReaction.jump);
  });

  testWidgets('onboarding never asks where routines are stored', (
    tester,
  ) async {
    final (_, _, l10n) = await _pump(tester);

    for (final label in [
      l10n.onboardingGetStarted,
      l10n.onboardingNext,
      l10n.onboardingNext,
      l10n.onboardingNext,
    ]) {
      await _next(tester, label);
    }
    expect(find.text(l10n.storageModeLocalOnly), findsNothing);
    expect(find.byType(RadioListTile<StorageMode>), findsNothing);
  });

  testWidgets('Skip completes onboarding and opens Today', (tester) async {
    final (router, prefs, l10n) = await _pump(tester);

    await _next(tester, l10n.onboardingGetStarted);
    await _next(tester, l10n.onboardingSkip);

    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.text('at /routines'), findsOneWidget);
    expect(router.state.uri.toString(), '/routines');
  });

  testWidgets(
    'choosing a scheduled routine opens the builder on top of Today',
    (tester) async {
      final (router, prefs, l10n) = await _pump(tester);

      for (final label in [
        l10n.onboardingGetStarted,
        l10n.onboardingNext,
        l10n.onboardingNext,
        l10n.onboardingNext,
      ]) {
        await _next(tester, label);
      }
      await _next(tester, l10n.onboardingCreateScheduled);

      expect(prefs.getBool('onboarding_complete'), isTrue);
      expect(find.text('at /routines/new?mode=scheduled'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('at /routines'), findsOneWidget);
    },
  );

  testWidgets('choosing a flexible routine opens the builder on Flexible', (
    tester,
  ) async {
    final (_, _, l10n) = await _pump(tester);

    for (final label in [
      l10n.onboardingGetStarted,
      l10n.onboardingNext,
      l10n.onboardingNext,
      l10n.onboardingNext,
    ]) {
      await _next(tester, label);
    }
    await _next(tester, l10n.onboardingCreateFlexible);

    expect(find.text('at /routines/new?mode=flexible'), findsOneWidget);
  });
}
