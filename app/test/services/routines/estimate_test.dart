import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/services/routines/estimate.dart';

RoutineStep _step({
  required int? durationSeconds,
  bool noExplicitTime = false,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return RoutineStep(
    id: 's',
    routineId: 'r',
    name: 'Step',
    emoji: '✅',
    durationSeconds: durationSeconds,
    order: 0,
    noExplicitTime: noExplicitTime,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('routineEstimate', () {
    test('sums durationSeconds across timed steps', () {
      final steps = [_step(durationSeconds: 60), _step(durationSeconds: 90)];

      expect(routineEstimate(steps), const Duration(seconds: 150));
    });

    test('skips steps with noExplicitTime', () {
      final steps = [
        _step(durationSeconds: 60),
        _step(durationSeconds: 300, noExplicitTime: true),
      ];

      expect(routineEstimate(steps), const Duration(seconds: 60));
    });

    test('treats a null duration as zero', () {
      final steps = [_step(durationSeconds: null)];

      expect(routineEstimate(steps), Duration.zero);
    });

    test('an empty step list has a zero estimate', () {
      expect(routineEstimate(const []), Duration.zero);
    });
  });
}
