import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/stats/stats_period.dart';

/// `MaterialLocalizations.firstDayOfWeekIndex` counts from Sunday.
const _sunday = 0;
const _monday = 1;

void main() {
  group('week', () {
    test('starts on Monday when the locale starts there', () {
      // Sunday 2026-10-18 belongs to the week that began on Monday the 12th.
      final range = StatsPeriod.week(
        DateTime(2026, 10, 18, 21),
        firstDayOfWeek: _monday,
      ).range;

      expect(range.start, DateTime(2026, 10, 12));
      expect(range.end, DateTime(2026, 10, 19));
    });

    test('starts on Sunday when the locale starts there', () {
      // The same Sunday opens a new week instead.
      final range = StatsPeriod.week(
        DateTime(2026, 10, 18, 21),
        firstDayOfWeek: _sunday,
      ).range;

      expect(range.start, DateTime(2026, 10, 18));
      expect(range.end, DateTime(2026, 10, 25));
    });

    test('crosses a year boundary', () {
      final range = StatsPeriod.week(
        DateTime(2027, 1, 1),
        firstDayOfWeek: _monday,
      ).range;

      expect(range.start, DateTime(2026, 12, 28));
      expect(range.end, DateTime(2027, 1, 4));
    });

    test('the same week is equal whichever day it was built from', () {
      expect(
        StatsPeriod.week(DateTime(2026, 10, 13), firstDayOfWeek: _monday),
        StatsPeriod.week(DateTime(2026, 10, 17, 8), firstDayOfWeek: _monday),
      );
    });

    test('steps back and forward by whole weeks', () {
      final week = StatsPeriod.week(
        DateTime(2026, 10, 14),
        firstDayOfWeek: _monday,
      );

      expect(week.previous().range.start, DateTime(2026, 10, 5));
      expect(week.next().range.start, DateTime(2026, 10, 19));
      expect(week.previous().next(), week);
    });
  });

  group('month', () {
    test('runs from the 1st to the 1st of the next month', () {
      final range = StatsPeriod.month(DateTime(2026, 10, 14)).range;

      expect(range.start, DateTime(2026, 10));
      expect(range.end, DateTime(2026, 11));
    });

    test('February in a leap year ends on March 1st', () {
      final range = StatsPeriod.month(DateTime(2028, 2, 29)).range;

      expect(range.start, DateTime(2028, 2));
      expect(range.end, DateTime(2028, 3));
    });

    test('steps across a year boundary', () {
      final january = StatsPeriod.month(DateTime(2027, 1, 20));

      expect(january.previous().range.start, DateTime(2026, 12));
      expect(january.previous().next(), january);
    });
  });

  group('all time', () {
    test('is unbounded at both ends', () {
      final range = const StatsPeriod.allTime().range;

      expect(range.start, isNull);
      expect(range.end, isNull);
    });
  });

  group('isCurrent', () {
    final now = DateTime(2026, 10, 14, 9);

    test('is true for the period that contains now', () {
      expect(
        StatsPeriod.week(now, firstDayOfWeek: _monday).isCurrent(now),
        isTrue,
      );
      expect(StatsPeriod.month(now).isCurrent(now), isTrue);
      expect(const StatsPeriod.allTime().isCurrent(now), isTrue);
    });

    test('is false for an earlier period', () {
      expect(
        StatsPeriod.week(
          now,
          firstDayOfWeek: _monday,
        ).previous().isCurrent(now),
        isFalse,
      );
      expect(StatsPeriod.month(now).previous().isCurrent(now), isFalse);
    });
  });
}
