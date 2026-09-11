import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/routines/next_up.dart';

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
  required String id,
  String name = 'Routine',
  ScheduleMode mode = ScheduleMode.scheduled,
  List<DayOfWeek>? days,
  String? startTime = '08:00',
}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  return Routine(
    id: id,
    name: name,
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
  group('nextUpRoutine', () {
    // A fixed Monday so every test can schedule a routine on "today" without
    // depending on the day the suite happens to run.
    final today = DateTime(2026, 6, 15, 8);
    final scheduledToday = [_dayOfWeek(today)];

    Duration Function(Routine) estimateOf([
      Duration value = _defaultEstimate,
    ]) =>
        (_) => value;
    bool Function(Routine) neverCompleted() =>
        (_) => false;

    test('the earliest remaining routine wins', () {
      final earlier = _routine(
        id: 'earlier',
        days: scheduledToday,
        startTime: '08:00',
      );
      final later = _routine(
        id: 'later',
        days: scheduledToday,
        startTime: '09:00',
      );
      final now = DateTime(2026, 6, 15, 7);

      final winner = nextUpRoutine(
        [later, earlier],
        now: now,
        estimateFor: estimateOf(),
        completedTodayFor: neverCompleted(),
      );

      expect(winner?.id, 'earlier');
    });

    test('a routine whose window already ended is skipped', () {
      final ended = _routine(
        id: 'ended',
        days: scheduledToday,
        startTime: '06:00',
      );
      final now = DateTime(2026, 6, 15, 8);

      final winner = nextUpRoutine(
        [ended],
        now: now,
        estimateFor: estimateOf(const Duration(minutes: 20)),
        completedTodayFor: neverCompleted(),
      );

      expect(winner, isNull);
    });

    test('a routine completed today is skipped', () {
      final completed = _routine(id: 'completed', days: scheduledToday);
      final now = today;

      final winner = nextUpRoutine(
        [completed],
        now: now,
        estimateFor: estimateOf(),
        completedTodayFor: (_) => true,
      );

      expect(winner, isNull);
    });

    test("a routine not scheduled today is skipped", () {
      final otherDay = today.weekday == DateTime.monday
          ? DayOfWeek.tue
          : DayOfWeek.mon;
      final routine = _routine(id: 'other-day', days: [otherDay]);

      final winner = nextUpRoutine(
        [routine],
        now: today,
        estimateFor: estimateOf(),
        completedTodayFor: neverCompleted(),
      );

      expect(winner, isNull);
    });

    test('a flexible routine is skipped', () {
      final routine = _routine(
        id: 'flexible',
        mode: ScheduleMode.flexible,
        days: scheduledToday,
      );

      final winner = nextUpRoutine(
        [routine],
        now: today,
        estimateFor: estimateOf(),
        completedTodayFor: neverCompleted(),
      );

      expect(winner, isNull);
    });

    test('a missing or malformed start time is skipped', () {
      final missing = _routine(
        id: 'missing',
        days: scheduledToday,
        startTime: null,
      );
      final malformed = _routine(
        id: 'malformed',
        days: scheduledToday,
        startTime: 'noon',
      );

      final winner = nextUpRoutine(
        [missing, malformed],
        now: today,
        estimateFor: estimateOf(),
        completedTodayFor: neverCompleted(),
      );

      expect(winner, isNull);
    });

    test('nothing qualifies returns null', () {
      final flexible = _routine(
        id: 'flexible',
        mode: ScheduleMode.flexible,
        days: scheduledToday,
      );
      final otherDay = today.weekday == DateTime.monday
          ? DayOfWeek.tue
          : DayOfWeek.mon;
      final wrongDay = _routine(id: 'wrong-day', days: [otherDay]);
      final ended = _routine(
        id: 'ended',
        days: scheduledToday,
        startTime: '06:00',
      );
      final completed = _routine(
        id: 'completed',
        days: scheduledToday,
        startTime: '09:00',
      );

      final winner = nextUpRoutine(
        [flexible, wrongDay, ended, completed],
        now: today,
        estimateFor: estimateOf(const Duration(minutes: 20)),
        completedTodayFor: (routine) => routine.id == 'completed',
      );

      expect(winner, isNull);
    });

    test('an in-progress routine outranks a later one', () {
      final inProgress = _routine(
        id: 'in-progress',
        days: scheduledToday,
        startTime: '07:50',
      );
      final later = _routine(
        id: 'later',
        days: scheduledToday,
        startTime: '09:00',
      );
      final now = today; // 08:00 — 10 minutes into inProgress's estimate.

      final winner = nextUpRoutine(
        [later, inProgress],
        now: now,
        estimateFor: estimateOf(const Duration(minutes: 20)),
        completedTodayFor: neverCompleted(),
      );

      expect(winner?.id, 'in-progress');
    });
  });
}
