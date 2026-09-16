import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/routines/today_progress.dart';

RunRecord _run({
  required DateTime startedAt,
  bool completed = false,
  int stepsDone = 0,
}) => (startedAt: startedAt, completed: completed, stepsDone: stepsDone);

void main() {
  final now = DateTime(2026, 9, 12, 12);

  test('no runs today means no progress', () {
    expect(todayProgress(const [], now: now, stepCount: 3), isNull);
  });

  test('a run finished today is done', () {
    final progress = todayProgress(
      [
        _run(
          startedAt: DateTime(2026, 9, 12, 7),
          completed: true,
          stepsDone: 3,
        ),
      ],
      now: now,
      stepCount: 3,
    );
    expect(progress, isA<DoneToday>());
  });

  test('a run stopped partway today reports the steps it got through', () {
    final progress = todayProgress(
      [_run(startedAt: DateTime(2026, 9, 12, 7), stepsDone: 2)],
      now: now,
      stepCount: 3,
    );
    expect(progress, isA<PartwayToday>());
    expect((progress! as PartwayToday).done, 2);
    expect((progress as PartwayToday).total, 3);
  });

  test('the latest stopped run wins', () {
    final progress = todayProgress(
      [
        _run(startedAt: DateTime(2026, 9, 12, 9), stepsDone: 1),
        _run(startedAt: DateTime(2026, 9, 12, 7), stepsDone: 2),
      ],
      now: now,
      stepCount: 3,
    );
    expect((progress! as PartwayToday).done, 1);
  });

  test('a finished run outranks a later stopped one', () {
    final progress = todayProgress(
      [
        _run(startedAt: DateTime(2026, 9, 12, 7), completed: true),
        _run(startedAt: DateTime(2026, 9, 12, 9), stepsDone: 1),
      ],
      now: now,
      stepCount: 3,
    );
    expect(progress, isA<DoneToday>());
  });

  test('a stopped run that got through no steps shows no progress', () {
    final progress = todayProgress(
      [_run(startedAt: DateTime(2026, 9, 12, 7))],
      now: now,
      stepCount: 3,
    );
    expect(progress, isNull);
  });

  test("yesterday's runs don't count", () {
    final progress = todayProgress(
      [_run(startedAt: DateTime(2026, 9, 11, 7), completed: true)],
      now: now,
      stepCount: 3,
    );
    expect(progress, isNull);
  });

  test('progress never claims more steps than the routine has', () {
    final progress = todayProgress(
      [_run(startedAt: DateTime(2026, 9, 12, 7), stepsDone: 5)],
      now: now,
      stepCount: 3,
    );
    expect((progress! as PartwayToday).done, 3);
  });
}
