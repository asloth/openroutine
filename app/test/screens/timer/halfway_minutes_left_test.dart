import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/timer/run/run_parts.dart';

final _now = DateTime.utc(2026, 10, 9);

RoutineStep _step(int durationSeconds) => RoutineStep(
  id: 's1',
  routineId: 'r1',
  name: 'Hot water',
  emoji: '☕',
  durationSeconds: durationSeconds,
  order: 0,
  noExplicitTime: false,
  isCore: false,
  remindDuring: true,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  test('rounds whole minutes up', () {
    expect(halfwayMinutesLeft(_step(600), const Duration(seconds: 300)), 5);
  });

  test('says zero, not one, with under a minute to go', () {
    // 30s left used to read "1 min to go".
    expect(halfwayMinutesLeft(_step(60), const Duration(seconds: 30)), 0);
  });

  test('stays hidden before halfway', () {
    expect(halfwayMinutesLeft(_step(60), const Duration(seconds: 29)), isNull);
  });
}
