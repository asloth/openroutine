import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/routines/upcoming.dart';

const _defaultLead = Duration(minutes: 15);
const _defaultEstimate = Duration(minutes: 20);

/// The inverse of `ScheduleTime.weekday`, so a test can schedule a routine
/// on whatever weekday its fixed `now` actually falls on.
DayOfWeek _dayOfWeek(DateTime date) => switch (date.weekday) {
  DateTime.monday => DayOfWeek.mon,
  DateTime.tuesday => DayOfWeek.tue,
  DateTime.wednesday => DayOfWeek.wed,
  DateTime.thursday => DayOfWeek.thu,
  DateTime.friday => DayOfWeek.fri,
  DateTime.saturday => DayOfWeek.sat,
  _ => DayOfWeek.sun,
};

Routine _routine({
  ScheduleMode mode = ScheduleMode.scheduled,
  List<DayOfWeek>? days,
  String? startTime = '08:00',
}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return Routine(
    id: 'r1',
    name: 'Morning Routine',
    triggerId: null,
    schedule: Schedule(
      mode: mode,
      days: days ?? const [],
      startTime: startTime,
    ),
    stepIds: const [],
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  group('upcomingState', () {
    // A fixed Monday so every test can schedule the routine on "today"
    // without depending on the day the suite happens to run.
    final today = DateTime(2026, 6, 15, 8);
    final scheduledToday = [_dayOfWeek(today)];

    test('16 minutes before the start is not upcoming', () {
      final now = today.subtract(const Duration(minutes: 16));
      final routine = _routine(days: scheduledToday);

      expect(
        upcomingState(
          routine,
          now: now,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('15 minutes before the start counts down', () {
      final now = today.subtract(const Duration(minutes: 15));
      final routine = _routine(days: scheduledToday);

      final result = upcomingState(
        routine,
        now: now,
        estimate: _defaultEstimate,
        completedToday: false,
        lead: _defaultLead,
      );

      expect(result, isA<StartsIn>());
      expect((result as StartsIn).remaining, const Duration(minutes: 15));
    });

    test('exactly the start time is in progress', () {
      final routine = _routine(days: scheduledToday);

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isA<InProgress>(),
      );
    });

    test('one second before the estimate ends is still in progress', () {
      final routine = _routine(days: scheduledToday);
      final now = today
          .add(_defaultEstimate)
          .subtract(const Duration(seconds: 1));

      expect(
        upcomingState(
          routine,
          now: now,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isA<InProgress>(),
      );
    });

    test('exactly when the estimate ends is no longer upcoming', () {
      final routine = _routine(days: scheduledToday);
      final now = today.add(_defaultEstimate);

      expect(
        upcomingState(
          routine,
          now: now,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('a zero estimate ends the window at the start time', () {
      final routine = _routine(days: scheduledToday);

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: Duration.zero,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('a zero estimate still counts down before the start', () {
      final routine = _routine(days: scheduledToday);
      final now = today.subtract(const Duration(minutes: 5));

      expect(
        upcomingState(
          routine,
          now: now,
          estimate: Duration.zero,
          completedToday: false,
          lead: _defaultLead,
        ),
        isA<StartsIn>(),
      );
    });

    test('not scheduled on today\'s weekday is never upcoming', () {
      final otherDay = today.weekday == DateTime.monday
          ? DayOfWeek.tue
          : DayOfWeek.mon;
      final routine = _routine(days: [otherDay]);

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('a flexible routine is never upcoming', () {
      final routine = _routine(
        mode: ScheduleMode.flexible,
        days: scheduledToday,
      );

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('a missing start time is never upcoming', () {
      final routine = _routine(days: scheduledToday, startTime: null);

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('a malformed start time is never upcoming', () {
      final routine = _routine(days: scheduledToday, startTime: 'noon');

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: _defaultEstimate,
          completedToday: false,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('completed today is never upcoming, even inside the window', () {
      final routine = _routine(days: scheduledToday);

      expect(
        upcomingState(
          routine,
          now: today,
          estimate: _defaultEstimate,
          completedToday: true,
          lead: _defaultLead,
        ),
        isNull,
      );
    });

    test('a window crossing midnight is in progress before midnight', () {
      final start = DateTime(2026, 6, 15, 22, 50);
      final routine = _routine(days: [_dayOfWeek(start)], startTime: '22:50');
      final now = DateTime(2026, 6, 15, 23, 10);

      expect(
        upcomingState(
          routine,
          now: now,
          estimate: const Duration(minutes: 30),
          completedToday: false,
          lead: _defaultLead,
        ),
        isA<InProgress>(),
      );
    });

    test(
      'past midnight, on a day the routine is not scheduled, is not upcoming',
      () {
        // Same routine as the previous scenario: scheduled only on the day
        // that has now ended.
        final scheduledDay = _dayOfWeek(DateTime(2026, 6, 15, 22, 50));
        final routine = _routine(days: [scheduledDay], startTime: '22:50');
        final now = DateTime(2026, 6, 16, 0, 5);

        expect(
          upcomingState(
            routine,
            now: now,
            estimate: const Duration(minutes: 30),
            completedToday: false,
            lead: _defaultLead,
          ),
          isNull,
        );
      },
    );
  });
}
