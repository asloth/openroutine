import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/stats/stats_screen.dart';
import 'package:openroutine/services/stats/routine_statistics.dart';
import 'package:openroutine/state/stats_provider.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/tinted/segmented_progress.dart';
import 'package:openroutine/widgets/tinted/tinted_card.dart';

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
    expect(find.text(l10n.statsCompletionTitle), findsNothing);
    expect(find.text(l10n.statsEstimateTitle), findsNothing);
    expect(find.byType(TintedCard), findsNothing);
    expect(find.byType(SegmentedProgress), findsNothing);
  });

  group('hero finishing card', () {
    testWidgets('fills with the accent container pair and shows the split '
        'sentence', (tester) async {
      final stats = _statsWith(finished: 3, abandoned: 1, streak: 2);
      await _pump(tester, stats);
      final l10n = await _l10n();

      final card = tester.widget<TintedCard>(find.byType(TintedCard));
      final theme = AppTheme.light();
      final colors = theme.extension<RoutineCardColors>()!;
      expect(card.color, colors.fill);
      expect(card.foregroundColor, colors.onFill);

      expect(find.text(l10n.statsCompletionFinished(3)), findsOneWidget);
      expect(find.text(l10n.statsCompletionOfTotal(4)), findsOneWidget);
      expect(find.text(l10n.statsStreak(2)), findsOneWidget);
    });

    testWidgets(
      'exposes one semantics node carrying the full sentence',
      (tester) async {
        final stats = _statsWith(finished: 5, abandoned: 2, streak: 4);
        await _pump(tester, stats);
        final l10n = await _l10n();

        final expectedLabel =
            '${l10n.statsCompletionRate(5, 7)}. ${l10n.statsStreak(4)}';

        final semantics = tester.getSemantics(
          find.byKey(const Key('statsHeroSemantics')),
        );
        expect(semantics.label, expectedLabel);

        // The visible figures underneath are excluded from the semantics tree,
        // so a screen reader hears one sentence, not the fragments too.
        expect(
          find.descendant(
            of: find.byKey(const Key('statsHeroSemantics')),
            matching: find.text(l10n.statsCompletionFinished(5)),
          ),
          findsOneWidget,
        );
      },
      semanticsEnabled: true,
    );

    testWidgets('segments at total 5: filled matches finished proportion', (
      tester,
    ) async {
      await _pump(tester, _statsWith(finished: 2, abandoned: 3));
      final progress = tester.widget<SegmentedProgress>(
        find.byType(SegmentedProgress),
      );
      expect(progress.count, 5);
      expect(progress.filled, 2);
    });

    testWidgets('segments cap at 20 past a total of 20', (tester) async {
      await _pump(tester, _statsWith(finished: 26, abandoned: 14));
      final progress = tester.widget<SegmentedProgress>(
        find.byType(SegmentedProgress),
      );
      expect(progress.count, 20);
      expect(progress.filled, 13);
    });

    testWidgets('guards against a zero total instead of throwing', (
      tester,
    ) async {
      await _pump(tester, _guardedZeroTotal);
      expect(tester.takeException(), isNull);

      final progress = tester.widget<SegmentedProgress>(
        find.byType(SegmentedProgress),
      );
      expect(progress.count, 0);
      expect(progress.filled, 0);
    });
  });

  group('flat sections', () {
    testWidgets('most-skipped renders dividers between rows only', (
      tester,
    ) async {
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

      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);

      final skippedSection = find.ancestor(
        of: find.text(l10n.statsSkippedTitle.toUpperCase()),
        matching: find.byType(Column),
      );
      final dividers = find.descendant(
        of: skippedSection.first,
        matching: find.byType(Divider),
      );
      // Three rows: two dividers between them, none after the last.
      expect(tester.widgetList(dividers).length, 2);
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

      expect(find.text(l10n.statsEstimateOver('8m')), findsOneWidget);
      expect(find.text('18m / 10m'), findsOneWidget);
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

      expect(find.text(l10n.statsTimeHour('07')), findsOneWidget);
      expect(find.text(l10n.statsTimeHour('21')), findsOneWidget);
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

    expect(find.text(l10n.statsCompletionOfTotal(4)), findsOneWidget);
    expect(find.text(l10n.statsStreak(2)), findsOneWidget);
    expect(find.text(l10n.statsCompletionTitle.toUpperCase()), findsOneWidget);
  });
}
