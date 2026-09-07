import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/notifications/routine_reminders.dart';

Routine _routine({
  String id = 'r1',
  String name = 'Morning',
  ScheduleMode mode = ScheduleMode.scheduled,
  List<DayOfWeek> days = const [DayOfWeek.mon],
  String? startTime = '07:00',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Routine(
    id: id,
    name: name,
    triggerId: null,
    schedule: Schedule(mode: mode, days: days, startTime: startTime),
    stepIds: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // 2026-08-31 is a Monday; the window below spans a full week from it.
  final monday = DateTime(2026, 8, 31, 6, 0);

  group('occurrences', () {
    test('fires on each selected weekday within the horizon', () {
      final result = ReminderSchedule.occurrences(
        _routine(days: const [DayOfWeek.mon, DayOfWeek.wed, DayOfWeek.fri]),
        now: monday,
      );

      expect(result, [
        DateTime(2026, 8, 31, 7),
        DateTime(2026, 9, 2, 7),
        DateTime(2026, 9, 4, 7),
        DateTime(2026, 9, 7, 7),
      ]);
    });

    test('subtracts the lead time', () {
      final result = ReminderSchedule.occurrences(
        _routine(days: const [DayOfWeek.mon]),
        now: monday,
        lead: const Duration(minutes: 5),
      );

      expect(result.first, DateTime(2026, 8, 31, 6, 55));
    });

    test("skips today's occurrence once it has passed", () {
      // 07:30 on the Monday: this morning's 07:00 is gone, next is a week out.
      final result = ReminderSchedule.occurrences(
        _routine(days: const [DayOfWeek.mon]),
        now: DateTime(2026, 8, 31, 7, 30),
      );

      expect(result.first, DateTime(2026, 9, 7, 7));
    });

    test('a lead that crosses midnight lands on the previous day', () {
      final result = ReminderSchedule.occurrences(
        _routine(days: const [DayOfWeek.tue], startTime: '00:10'),
        now: monday,
        lead: const Duration(minutes: 30),
      );

      // Tuesday 00:10 minus 30 min is Monday 23:40 — still ahead of `now`, so
      // it must survive rather than being dropped for falling out of the day.
      expect(result.first, DateTime(2026, 8, 31, 23, 40));
    });

    test('flexible routines never fire', () {
      expect(
        ReminderSchedule.occurrences(
          _routine(mode: ScheduleMode.flexible),
          now: monday,
        ),
        isEmpty,
      );
    });

    test('no days and no start time never fire', () {
      expect(
        ReminderSchedule.occurrences(_routine(days: const []), now: monday),
        isEmpty,
      );
      expect(
        ReminderSchedule.occurrences(_routine(startTime: null), now: monday),
        isEmpty,
      );
    });

    test('a malformed start time is treated as no time, never a crash', () {
      // An agent editing routines.json by hand is an expected writer here.
      for (final bad in ['7:00pm', '25:00', '07:61', '0700', '', 'x:y']) {
        expect(
          ReminderSchedule.occurrences(_routine(startTime: bad), now: monday),
          isEmpty,
          reason: 'start time "$bad" should yield no reminders',
        );
      }
    });

    test('resolves wall-clock time across a DST transition', () {
      // Europe/Madrid springs forward on 2026-03-29. Whatever the host zone,
      // building from date parts must give the wall-clock hour the user typed
      // on every day in the window — that is the property that a repeating
      // UTC-anchored alarm would break.
      final result = ReminderSchedule.occurrences(
        _routine(
          days: DayOfWeek.values,
          startTime: '07:00',
        ),
        now: DateTime(2026, 3, 27, 6),
      );

      expect(result, isNotEmpty);
      for (final at in result) {
        expect(at.hour, 7, reason: '$at should be 07:00 local');
        expect(at.minute, 0);
      }
    });
  });

  group('build', () {
    test('assigns ids from the reserved range without gaps', () {
      final requests = ReminderSchedule.build(
        routines: [
          _routine(id: 'a', days: const [DayOfWeek.mon]),
          _routine(id: 'b', days: const [DayOfWeek.tue]),
        ],
        now: monday,
        lead: Duration.zero,
        title: (r) => r.name,
        body: (r, lead) => 'body',
      );

      expect(requests.map((r) => r.notificationId), [
        ReminderSchedule.idBase,
        ReminderSchedule.idBase + 1,
        ReminderSchedule.idBase + 2,
      ]);
    });

    test('orders soonest first and drops the furthest out at the cap', () {
      final requests = ReminderSchedule.build(
        routines: [
          for (var i = 0; i < 20; i++)
            _routine(id: 'r$i', days: DayOfWeek.values),
        ],
        now: monday,
        lead: Duration.zero,
        title: (r) => r.name,
        body: (r, lead) => 'body',
      );

      expect(requests.length, ReminderSchedule.maxReminders);
      for (var i = 1; i < requests.length; i++) {
        expect(
          requests[i].at.isBefore(requests[i - 1].at),
          isFalse,
          reason: 'reminders must come out in ascending time order',
        );
      }
    });

    test('stays clear of the timer\'s own notification id', () {
      final requests = ReminderSchedule.build(
        routines: [_routine(days: DayOfWeek.values)],
        now: monday,
        lead: Duration.zero,
        title: (r) => r.name,
        body: (r, lead) => 'body',
      );

      expect(requests.first.notificationId, greaterThan(1));
      expect(ReminderSchedule.idBase, greaterThan(1));
    });

    test('carries the routine id so a tap can open the right routine', () {
      final requests = ReminderSchedule.build(
        routines: [_routine(id: 'abc', days: const [DayOfWeek.mon])],
        now: monday,
        lead: Duration.zero,
        title: (r) => r.name,
        body: (r, lead) => 'body',
      );

      expect(requests.every((r) => r.routineId == 'abc'), isTrue);
    });
  });
}
