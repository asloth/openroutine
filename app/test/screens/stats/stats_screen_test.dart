import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/stats/stats_screen.dart';
import 'package:openroutine/services/stats/routine_statistics.dart';
import 'package:openroutine/state/stats_provider.dart';
import 'package:openroutine/theme/theme.dart';

Future<AppLocalizations> _l10n([Locale locale = const Locale('en')]) =>
    AppLocalizations.delegate.load(locale);

Future<void> _pump(
  WidgetTester tester,
  RoutineStatistics stats, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [statisticsProvider.overrideWith((ref) async => stats)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
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

const _guardedZeroTotal = RoutineStatistics(
  estimates: null,
  completion: CompletionRate(finished: 0, abandoned: 0, currentStreakDays: 0),
  skipped: [],
  startTimes: [],
  // hasData: true with a zero-total completion never happens through the
  // real aggregation service, but the screen must not crash on it — this is
  // the guard the segment math needs against dividing by zero.
  hasData: true,
);

RoutineStatistics _statsWith({
  required int finished,
  required int abandoned,
  int streak = 1,
}) {
  return RoutineStatistics(
    estimates: null,
    completion: CompletionRate(
      finished: finished,
      abandoned: abandoned,
      currentStreakDays: streak,
    ),
    skipped: const [],
    startTimes: const [],
    hasData: true,
  );
}

void main() {
  testWidgets('has no AppBar', (tester) async {
    await _pump(tester, _noStats);
    expect(find.byType(AppBar), findsNothing);

    await _pump(tester, _statsWith(finished: 3, abandoned: 1));
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('with no runs it explains what will appear, not zeros', (
    tester,
  ) async {
    await _pump(tester, _noStats);
    final l10n = await _l10n();

    expect(find.text(l10n.statsEmptyTitle), findsOneWidget);
    expect(find.text(l10n.statsEmptyBody), findsOneWidget);

    // The point of the empty state: no section headings, no zeroed figures.
    // An empty chart reads as a score of zero.
    expect(find.text(l10n.statsFinishingHeadlineMost), findsNothing);
    expect(find.text(l10n.statsEstimateHeadlineOver), findsNothing);
    expect(find.text(l10n.statsEstimateHeadlineUnder), findsNothing);
  });

  group('hero finishing card', () {
    testWidgets('leads with the finding, not the figure', (tester) async {
      // 3 of 4 is 75%, so the middle headline rather than the best one.
      final stats = _statsWith(finished: 3, abandoned: 1, streak: 2);
      await _pump(tester, stats);
      final l10n = await _l10n();

      expect(find.text(l10n.statsFinishingHeadlineHalf), findsOneWidget);
      expect(find.text(l10n.statsFinishingDetail(8)), findsOneWidget);
      expect(find.text(l10n.statsStreak(2)), findsOneWidget);
    });

    testWidgets('at nine in ten, the headline says most', (tester) async {
      await _pump(tester, _statsWith(finished: 9, abandoned: 1));
      expect(
        find.text((await _l10n()).statsFinishingHeadlineMost),
        findsOneWidget,
      );
    });

    testWidgets('below half, the headline states it plainly', (tester) async {
      // Descriptive, not a reproach: nothing on this screen scolds.
      await _pump(tester, _statsWith(finished: 3, abandoned: 7));
      expect(
        find.text((await _l10n()).statsFinishingHeadlineFew),
        findsOneWidget,
      );
    });

    testWidgets(
      'exposes one semantics node carrying the full sentence',
      (tester) async {
        final stats = _statsWith(finished: 5, abandoned: 2, streak: 4);
        await _pump(tester, stats);
        final l10n = await _l10n();

        final expectedLabel =
            '${l10n.statsFinishingHeadlineHalf} '
            '${l10n.statsFinishingDetail(7)} ${l10n.statsStreak(4)}';

        final semantics = tester.getSemantics(
          find.byKey(const Key('statsHeroSemantics')),
        );
        expect(semantics.label, expectedLabel);

        // The visible figures underneath are excluded from the semantics tree,
        // so a screen reader hears one sentence, not the fragments too.
        expect(
          find.descendant(
            of: find.byKey(const Key('statsHeroSemantics')),
            matching: find.text(l10n.statsFinishingHeadlineHalf),
          ),
          findsOneWidget,
        );
      },
      semanticsEnabled: true,
    );

    testWidgets('ten dots carry the rate however many runs there are', (
      tester,
    ) async {
      await _pump(tester, _statsWith(finished: 2, abandoned: 3));
      expect(
        find.text((await _l10n()).statsFinishingDetail(4)),
        findsOneWidget,
      );
    });

    testWidgets('one finished run never rounds away to none', (tester) async {
      // 1 of 40 rounds to zero, which would read as "you finish nothing" —
      // untrue while a run did finish.
      await _pump(tester, _statsWith(finished: 1, abandoned: 39));
      expect(
        find.text((await _l10n()).statsFinishingDetail(1)),
        findsOneWidget,
      );
    });

    testWidgets('one unfinished run never rounds up to all', (tester) async {
      // 39 of 40 rounds to ten, which would read as a clean sweep.
      await _pump(tester, _statsWith(finished: 39, abandoned: 1));
      expect(
        find.text((await _l10n()).statsFinishingDetail(9)),
        findsOneWidget,
      );
    });

    testWidgets('a clean sweep really does read as ten', (tester) async {
      await _pump(tester, _statsWith(finished: 40, abandoned: 0));
      expect(
        find.text((await _l10n()).statsFinishingDetail(10)),
        findsOneWidget,
      );
    });

    testWidgets('guards against a zero total instead of throwing', (
      tester,
    ) async {
      await _pump(tester, _guardedZeroTotal);
      expect(tester.takeException(), isNull);
      expect(
        find.text((await _l10n()).statsFinishingDetail(0)),
        findsOneWidget,
      );
    });
  });

  group('flat sections', () {
    testWidgets('most-skipped names every step and its count', (tester) async {
      await _pump(
        tester,
        RoutineStatistics(
          estimates: null,
          completion: const CompletionRate(
            finished: 1,
            abandoned: 0,
            currentStreakDays: 1,
          ),
          skipped: const [
            SkippedStep(stepId: 'a', name: 'Shower', count: 4),
            SkippedStep(stepId: 'b', name: 'Stretch', count: 2),
            SkippedStep(stepId: 'c', name: 'Journal', count: 1),
          ],
          startTimes: const [],
          hasData: true,
        ),
      );
      final l10n = await _l10n();

      // The headline names the worst one; the others wait behind the link.
      expect(find.text(l10n.statsSkippedHeadline('Shower')), findsOneWidget);
      expect(find.text(l10n.statsSkippedDetail(4)), findsOneWidget);
      expect(find.text('Stretch'), findsNothing);

      await tester.tap(find.text(l10n.statsSkippedShowRest));
      await tester.pumpAndSettle();

      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);

      // Each skipped step carries its own count rather than sharing one
      // scale the reader has to infer.
      expect(find.text(l10n.statsSkippedCount(4)), findsOneWidget);
      expect(find.text(l10n.statsSkippedCount(2)), findsOneWidget);
      expect(find.text(l10n.statsSkippedCount(1)), findsOneWidget);
    });

    testWidgets('says nothing was skipped rather than showing an empty list', (
      tester,
    ) async {
      await _pump(tester, _statsWith(finished: 1, abandoned: 0));
      final l10n = await _l10n();

      expect(find.text(l10n.statsSkippedNone), findsOneWidget);
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
      final l10n = await _l10n();

      expect(find.text(l10n.statsEstimateHeadlineOver), findsOneWidget);
      expect(find.text('+8m'), findsNothing);

      await tester.tap(find.text(l10n.statsEstimateShowSteps));
      await tester.pumpAndSettle();

      // The row says which way the step went, not two raw durations the
      // reader has to subtract.
      expect(find.text('+8m'), findsOneWidget);
    });

    testWidgets('a step that came in under reads as a minus', (tester) async {
      await _pump(
        tester,
        const RoutineStatistics(
          estimates: EstimateAccuracy(
            estimated: Duration(minutes: 10),
            actual: Duration(minutes: 7),
            steps: [
              StepEstimate(
                stepId: 'a',
                name: 'Water',
                estimated: Duration(minutes: 10),
                actual: Duration(minutes: 7),
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
      final l10n = await _l10n();

      expect(find.text(l10n.statsEstimateHeadlineUnder), findsOneWidget);

      await tester.tap(find.text(l10n.statsEstimateShowSteps));
      await tester.pumpAndSettle();

      // U+2212, not a hyphen: it has to read as a sign at a glance.
      expect(find.text('\u22123m'), findsOneWidget);
    });

    testWidgets('draws its data in the accent, not a colour of its own', (
      tester,
    ) async {
      await _pump(
        tester,
        const RoutineStatistics(
          estimates: null,
          completion: CompletionRate(
            finished: 3,
            abandoned: 1,
            currentStreakDays: 1,
          ),
          skipped: [],
          startTimes: [],
          hasData: true,
        ),
      );

      // Everything on this screen is a single series — how many runs, how
      // many skips, which part of the day. None of it carries a good-or-bad
      // reading that would need a hue outside the palette's accent, so it
      // follows whichever accent is set.
      final accent = Theme.of(
        tester.element(find.byType(StatsScreen)),
      ).colorScheme.primary;

      final painted = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(const Key('statsHeroCard')),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .toSet();

      expect(painted, contains(accent.withValues(alpha: 0.75)));
      expect(painted, isNot(contains(AppColors.secondary)));
      expect(painted, isNot(contains(AppColors.tertiary)));
    });

    testWidgets('labels start-time buckets by hour', (tester) async {
      await _pump(
        tester,
        RoutineStatistics(
          estimates: null,
          completion: const CompletionRate(
            finished: 2,
            abandoned: 0,
            currentStreakDays: 1,
          ),
          skipped: const [],
          startTimes: const [
            HourBucket(hour: 7, runs: 2),
            HourBucket(hour: 21, runs: 1),
          ],
          hasData: true,
        ),
      );
      final l10n = await _l10n();

      // The card answers with the part of the day; the hours are the
      // evidence behind it.
      expect(find.text(l10n.statsTimeHeadlineMorning), findsOneWidget);
      expect(find.text(l10n.statsTimePartMorning), findsOneWidget);
      expect(find.text(l10n.statsTimeHour('07')), findsNothing);

      // The card is the last one on the page, so the link starts below the
      // fold and a bare tap would miss it.
      await tester.ensureVisible(find.text(l10n.statsTimeShowHours));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.statsTimeShowHours));
      await tester.pumpAndSettle();

      expect(find.text(l10n.statsTimeHour('07')), findsOneWidget);
      expect(find.text(l10n.statsTimeHour('21')), findsOneWidget);
    });

    testWidgets('an evening person gets an evening headline', (tester) async {
      await _pump(
        tester,
        RoutineStatistics(
          estimates: null,
          completion: const CompletionRate(
            finished: 2,
            abandoned: 0,
            currentStreakDays: 1,
          ),
          skipped: const [],
          startTimes: const [
            HourBucket(hour: 7, runs: 1),
            // 01:00 is the tail of a night, not the start of a morning.
            HourBucket(hour: 1, runs: 2),
            HourBucket(hour: 22, runs: 1),
          ],
          hasData: true,
        ),
      );

      expect(
        find.text((await _l10n()).statsTimeHeadlineEvening),
        findsOneWidget,
      );
    });
  });

  group('text scale', () {
    testWidgets('no overflow at 1.5x', (tester) async {
      final originalScale = tester.platformDispatcher.textScaleFactor;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(
        () =>
            tester.platformDispatcher.textScaleFactorTestValue = originalScale,
      );

      await _pump(
        tester,
        RoutineStatistics(
          estimates: const EstimateAccuracy(
            estimated: Duration(minutes: 10),
            actual: Duration(minutes: 18),
            steps: [
              StepEstimate(
                stepId: 'a',
                name: 'A considerably longer step name than usual',
                estimated: Duration(minutes: 10),
                actual: Duration(minutes: 18),
              ),
            ],
          ),
          completion: const CompletionRate(
            finished: 5,
            abandoned: 2,
            currentStreakDays: 4,
          ),
          skipped: const [SkippedStep(stepId: 'a', name: 'Shower', count: 4)],
          startTimes: const [HourBucket(hour: 7, runs: 2)],
          hasData: true,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 2.0x', (tester) async {
      final originalScale = tester.platformDispatcher.textScaleFactor;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () =>
            tester.platformDispatcher.textScaleFactorTestValue = originalScale,
      );

      await _pump(
        tester,
        RoutineStatistics(
          estimates: const EstimateAccuracy(
            estimated: Duration(minutes: 10),
            actual: Duration(minutes: 18),
            steps: [
              StepEstimate(
                stepId: 'a',
                name: 'A considerably longer step name than usual',
                estimated: Duration(minutes: 10),
                actual: Duration(minutes: 18),
              ),
            ],
          ),
          completion: const CompletionRate(
            finished: 5,
            abandoned: 2,
            currentStreakDays: 4,
          ),
          skipped: const [SkippedStep(stepId: 'a', name: 'Shower', count: 4)],
          startTimes: const [HourBucket(hour: 7, runs: 2)],
          hasData: true,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Spanish strings render in an es locale', (tester) async {
    await _pump(
      tester,
      _statsWith(finished: 3, abandoned: 1, streak: 2),
      locale: const Locale('es'),
    );
    final l10n = await _l10n(const Locale('es'));

    expect(find.text(l10n.statsFinishingHeadlineHalf), findsOneWidget);
    expect(find.text(l10n.statsFinishingDetail(8)), findsOneWidget);
    expect(find.text(l10n.statsStreak(2)), findsOneWidget);
  });
}
