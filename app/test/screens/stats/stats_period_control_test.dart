import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/stats/stats_screen.dart';
import 'package:openroutine/services/stats/routine_statistics.dart';
import 'package:openroutine/services/stats/stats_period.dart';
import 'package:openroutine/state/stats_provider.dart';
import 'package:openroutine/theme/theme.dart';

const _someRuns = RoutineStatistics(
  estimates: null,
  completion: CompletionRate(finished: 3, abandoned: 1, currentStreakDays: 2),
  skipped: [],
  startTimes: [],
  hasData: true,
);

const _noRuns = RoutineStatistics(
  estimates: null,
  completion: CompletionRate(finished: 0, abandoned: 0, currentStreakDays: 2),
  skipped: [],
  startTimes: [],
  hasData: false,
);

/// Every period the screen asked statistics for, in order.
late List<StatsPeriod> _requested;

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  RoutineStatistics Function(StatsPeriod) statsFor = _alwaysSome,
}) async {
  _requested = [];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        statisticsProvider.overrideWith((ref, period) async {
          _requested.add(period);
          return statsFor(period);
        }),
      ],
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

RoutineStatistics _alwaysSome(StatsPeriod _) => _someRuns;

/// `MaterialLocalizations.firstDayOfWeekIndex` for each test locale.
const _sundayFirst = 0;
const _mondayFirst = 1;

final _previous = find.byKey(const Key('stats-period-previous'));
final _next = find.byKey(const Key('stats-period-next'));

IconButton _button(WidgetTester tester, Finder finder) =>
    tester.widget<IconButton>(finder);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('opens on this week', (tester) async {
    await _pump(tester);

    expect(
      _requested.last,
      StatsPeriod.week(DateTime.now(), firstDayOfWeek: _sundayFirst),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('stats-period-week'))),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('a Spanish phone starts the week on Monday', (tester) async {
    await _pump(tester, locale: const Locale('es'));

    expect(
      _requested.last,
      StatsPeriod.week(DateTime.now(), firstDayOfWeek: _mondayFirst),
    );
  });

  testWidgets('switches to this month and to all time', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(l10n.statsPeriodMonth));
    await tester.pumpAndSettle();
    expect(_requested.last, StatsPeriod.month(DateTime.now()));
    expect(
      find.text(DateFormat.yMMMM('en').format(DateTime.now())),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.statsPeriodAllTime));
    await tester.pumpAndSettle();
    expect(_requested.last, const StatsPeriod.allTime());
    // All time has nowhere to step to.
    expect(_previous, findsNothing);
    expect(_next, findsNothing);
  });

  testWidgets('steps back a week and labels it with its dates', (tester) async {
    await _pump(tester);
    final thisWeek = StatsPeriod.week(
      DateTime.now(),
      firstDayOfWeek: _sundayFirst,
    );

    await tester.tap(_previous);
    await tester.pumpAndSettle();

    final lastWeek = thisWeek.previous();
    expect(_requested.last, lastWeek);
    final start = lastWeek.range.start!;
    expect(
      find.textContaining(DateFormat.MMMd('en').format(start)),
      findsOneWidget,
    );

    // And forward again, back to now.
    await tester.tap(_next);
    await tester.pumpAndSettle();
    expect(_requested.last, thisWeek);
  });

  testWidgets('cannot step past the current period', (tester) async {
    await _pump(tester);
    expect(_button(tester, _next).onPressed, isNull);

    await tester.tap(_previous);
    await tester.pumpAndSettle();
    expect(_button(tester, _next).onPressed, isNotNull);
  });

  testWidgets('a quiet period keeps the control and says nothing ran', (
    tester,
  ) async {
    await _pump(
      tester,
      statsFor: (period) =>
          period.kind == StatsPeriodKind.allTime ? _someRuns : _noRuns,
    );

    expect(find.text(l10n.statsEmptyPeriod), findsOneWidget);
    expect(find.text(l10n.statsPeriodWeek), findsOneWidget);
    expect(_previous, findsOneWidget);
    // Not the first-run screen: there are runs, just not this week.
    expect(find.text(l10n.statsEmptyTitle), findsNothing);
  });

  testWidgets('with no runs ever it shows the first-run screen alone', (
    tester,
  ) async {
    await _pump(tester, statsFor: (_) => _noRuns);

    expect(find.text(l10n.statsEmptyTitle), findsOneWidget);
    expect(find.text(l10n.statsPeriodWeek), findsNothing);
    expect(_previous, findsNothing);
  });
}
