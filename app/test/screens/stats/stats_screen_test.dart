import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/stats/stats_screen.dart';
import 'package:openroutine/services/stats/routine_statistics.dart';
import 'package:openroutine/state/stats_provider.dart';
import 'package:openroutine/theme/theme.dart';

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

Future<void> _pump(WidgetTester tester, RoutineStatistics stats) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [statisticsProvider.overrideWith((ref) async => stats)],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _noStats = RoutineStatistics(
  estimates: null,
  completion: CompletionRate(finished: 0, abandoned: 0, currentStreakDays: 0),
  skipped: [],
  startTimes: [],
  hasData: false,
);

void main() {
  testWidgets('with no runs it explains what will appear, not zeros', (
    tester,
  ) async {
    await _pump(tester, _noStats);
    final l10n = await _en();

    expect(find.text(l10n.statsEmptyTitle), findsOneWidget);
    expect(find.text(l10n.statsEmptyBody), findsOneWidget);

    // The point of the empty state: no section headings, no zeroed figures.
    // An empty chart reads as a score of zero.
    expect(find.text(l10n.statsCompletionTitle), findsNothing);
    expect(find.text(l10n.statsEstimateTitle), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('with runs but no estimates it says so and still reports the '
      'rest', (tester) async {
    await _pump(
      tester,
      const RoutineStatistics(
        estimates: null,
        completion: CompletionRate(
          finished: 3,
          abandoned: 1,
          currentStreakDays: 2,
        ),
        skipped: [SkippedStep(stepId: 'a', name: 'Shower', count: 2)],
        startTimes: [HourBucket(hour: 7, runs: 3)],
        hasData: true,
      ),
    );
    final l10n = await _en();

    expect(find.text(l10n.statsEstimateNone), findsOneWidget);
    expect(find.text(l10n.statsCompletionRate(3, 4)), findsOneWidget);
    expect(find.text(l10n.statsStreak(2)), findsOneWidget);
    expect(find.text('Shower'), findsOneWidget);
  });

  testWidgets('reports an overrun as a difference, not a grade', (
    tester,
  ) async {
    await _pump(
      tester,
      const RoutineStatistics(
        estimates: EstimateAccuracy(
          estimated: Duration(minutes: 10),
          actual: Duration(minutes: 18),
          steps: [
            StepEstimate(
              stepId: 'a',
              name: 'Shower',
              estimated: Duration(minutes: 10),
              actual: Duration(minutes: 18),
            ),
          ],
        ),
        completion: CompletionRate(
          finished: 1,
          abandoned: 0,
          currentStreakDays: 1,
        ),
        skipped: [],
        startTimes: [],
        hasData: true,
      ),
    );
    final l10n = await _en();

    expect(find.text(l10n.statsEstimateOver('8m')), findsOneWidget);
    expect(find.text('18m / 10m'), findsOneWidget);
  });

  testWidgets('says nothing was skipped rather than showing an empty list', (
    tester,
  ) async {
    await _pump(
      tester,
      const RoutineStatistics(
        estimates: null,
        completion: CompletionRate(
          finished: 1,
          abandoned: 0,
          currentStreakDays: 1,
        ),
        skipped: [],
        startTimes: [HourBucket(hour: 9, runs: 1)],
        hasData: true,
      ),
    );
    final l10n = await _en();

    expect(find.text(l10n.statsSkippedNone), findsOneWidget);
  });

  testWidgets('labels start-time buckets by hour', (tester) async {
    await _pump(
      tester,
      const RoutineStatistics(
        estimates: null,
        completion: CompletionRate(
          finished: 2,
          abandoned: 0,
          currentStreakDays: 1,
        ),
        skipped: [],
        startTimes: [
          HourBucket(hour: 7, runs: 2),
          HourBucket(hour: 21, runs: 1),
        ],
        hasData: true,
      ),
    );
    final l10n = await _en();

    expect(find.text(l10n.statsTimeHour('07')), findsOneWidget);
    expect(find.text(l10n.statsTimeHour('21')), findsOneWidget);
  });
}
