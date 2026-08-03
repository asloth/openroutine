import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/services/timer/timer_machine.dart';

/// Fixed epoch for every test, so elapsed times below read as plain arithmetic.
final _t0 = DateTime.utc(2026, 8, 2, 9);

DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

RoutineStep _step(
  String id, {
  int? durationSeconds = 60,
  bool noExplicitTime = false,
}) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: id,
  emoji: '🪥',
  durationSeconds: noExplicitTime ? null : durationSeconds,
  order: 0,
  noExplicitTime: noExplicitTime,
  createdAt: _t0,
  updatedAt: _t0,
);

TimerState _machine({List<RoutineStep>? steps}) => TimerState.idle(
  routineId: 'r1',
  steps: steps ?? [_step('a'), _step('b'), _step('c')],
);

void main() {
  group('start', () {
    test('moves from idle to running on the first step', () {
      final state = _machine().start(_t0);

      expect(state.phase, TimerPhase.running);
      expect(state.currentIndex, 0);
      expect(state.currentStep?.id, 'a');
      expect(state.startedAt, _t0);
    });

    test('is a no-op once already running', () {
      final started = _machine().start(_t0);
      expect(started.start(_at(30)), started);
    });

    test('a routine with no steps lands directly in complete', () {
      final state = _machine(steps: []).start(_t0);

      expect(state.phase, TimerPhase.complete);
      expect(state.outcome, CompletionOutcome.completed);
      expect(state.outcomes, isEmpty);
    });
  });

  group('elapsed and remaining', () {
    test('elapsed tracks wall clock, not tick count', () {
      final state = _machine().start(_t0);

      // The gap matters: a tick-counting implementation would report 0 here,
      // because no ticks were delivered while the process was suspended.
      expect(state.elapsed(_at(45)), const Duration(seconds: 45));
      expect(state.remaining(_at(45)), const Duration(seconds: 15));
    });

    test('remaining goes negative on overrun rather than clamping', () {
      final state = _machine().start(_t0);
      expect(state.remaining(_at(90)), const Duration(seconds: -30));
    });

    test('a no-explicit-time step counts up with no target', () {
      final state = _machine(
        steps: [_step('a', noExplicitTime: true)],
      ).start(_t0);

      expect(state.elapsed(_at(120)), const Duration(seconds: 120));
      expect(state.remaining(_at(120)), isNull);
    });
  });

  group('pause and resume', () {
    test('paused time does not count toward elapsed', () {
      final state = _machine()
          .start(_t0)
          .pause(_at(10))
          .resume(_at(40));

      // 10s ran, 30s paused: at t=50 only 20s of the step has actually elapsed.
      expect(state.elapsed(_at(50)), const Duration(seconds: 20));
    });

    test('the display holds still while paused', () {
      final state = _machine().start(_t0).pause(_at(10));

      expect(state.elapsed(_at(10)), const Duration(seconds: 10));
      expect(state.elapsed(_at(999)), const Duration(seconds: 10));
    });

    test('repeated pause and resume accumulates', () {
      final state = _machine()
          .start(_t0)
          .pause(_at(10))
          .resume(_at(20))
          .pause(_at(30))
          .resume(_at(60));

      // Paused 10s then 30s; at t=70 that leaves 30s of real elapsed time.
      expect(state.elapsed(_at(70)), const Duration(seconds: 30));
    });

    test('resume on a running machine is a no-op', () {
      final running = _machine().start(_t0);
      expect(running.resume(_at(5)), running);
    });
  });

  group('completeStep', () {
    test('records a step finished within its target as completed', () {
      final state = _machine().start(_t0).completeStep(_at(30));

      expect(state.outcomes.single.stepId, 'a');
      expect(state.outcomes.single.state, CompletionStepState.completed);
      expect(state.outcomes.single.actualDurationSeconds, 30);
      expect(state.currentIndex, 1);
    });

    test('records a step finished past its target as overrun', () {
      final state = _machine().start(_t0).completeStep(_at(75));

      expect(state.outcomes.single.state, CompletionStepState.overrun);
      expect(state.outcomes.single.actualDurationSeconds, 75);
    });

    test('a no-explicit-time step is never overrun', () {
      final state = _machine(
        steps: [_step('a', noExplicitTime: true), _step('b')],
      ).start(_t0).completeStep(_at(9999));

      expect(state.outcomes.single.state, CompletionStepState.completed);
    });

    test('the clock restarts for the next step', () {
      final state = _machine().start(_t0).completeStep(_at(30));

      expect(state.elapsed(_at(30)), Duration.zero);
      expect(state.elapsed(_at(45)), const Duration(seconds: 15));
    });

    test('finishing the last step completes the run', () {
      final state = _machine()
          .start(_t0)
          .completeStep(_at(10))
          .completeStep(_at(20))
          .completeStep(_at(30));

      expect(state.phase, TimerPhase.complete);
      expect(state.outcome, CompletionOutcome.completed);
      expect(state.endedAt, _at(30));
      expect(state.outcomes, hasLength(3));
    });

    test('paused time is excluded from the recorded duration', () {
      final state = _machine()
          .start(_t0)
          .pause(_at(10))
          .resume(_at(70))
          .completeStep(_at(80));

      expect(state.outcomes.single.actualDurationSeconds, 20);
      // 20s against a 60s target is not an overrun, even though 80s of wall
      // time passed.
      expect(state.outcomes.single.state, CompletionStepState.completed);
    });
  });

  group('skip', () {
    test('records the step as skipped, keeping the time spent', () {
      final state = _machine().start(_t0).skip(_at(12));

      expect(state.outcomes.single.state, CompletionStepState.skipped);
      expect(state.outcomes.single.actualDurationSeconds, 12);
      expect(state.currentIndex, 1);
    });

    test('skipping the last step still completes the run', () {
      final state = _machine(steps: [_step('a')]).start(_t0).skip(_at(5));

      expect(state.phase, TimerPhase.complete);
      expect(state.outcome, CompletionOutcome.completed);
    });
  });

  group('back', () {
    test('returns to the previous step and drops its recorded outcome', () {
      final state = _machine()
          .start(_t0)
          .completeStep(_at(30))
          .back(_at(40));

      expect(state.currentIndex, 0);
      expect(state.currentStep?.id, 'a');
      expect(state.outcomes, isEmpty);
    });

    test('the retried step is what ends up in the log', () {
      final state = _machine()
          .start(_t0)
          .completeStep(_at(30))
          .back(_at(40))
          .completeStep(_at(50));

      expect(state.outcomes.single.stepId, 'a');
      expect(state.outcomes.single.actualDurationSeconds, 10);
    });

    test('is a no-op on the first step', () {
      final started = _machine().start(_t0);
      expect(started.back(_at(10)), started);
    });

    test('stays paused when the run was paused', () {
      final state = _machine()
          .start(_t0)
          .completeStep(_at(30))
          .pause(_at(35))
          .back(_at(40));

      expect(state.phase, TimerPhase.paused);
      // The step the user came back to must not be silently counting down.
      expect(state.elapsed(_at(300)), Duration.zero);
    });
  });

  group('resetStep', () {
    test('restarts the current step clock without moving position', () {
      final state = _machine().start(_t0).resetStep(_at(45));

      expect(state.currentIndex, 0);
      expect(state.elapsed(_at(45)), Duration.zero);
      expect(state.elapsed(_at(60)), const Duration(seconds: 15));
    });

    test('clears previously accumulated pause time', () {
      final state = _machine()
          .start(_t0)
          .pause(_at(10))
          .resume(_at(40))
          .resetStep(_at(50));

      expect(state.elapsed(_at(80)), const Duration(seconds: 30));
    });
  });

  group('abandon', () {
    test('ends the run and keeps only the steps already finished', () {
      final state = _machine()
          .start(_t0)
          .completeStep(_at(30))
          .abandon(_at(45));

      expect(state.phase, TimerPhase.complete);
      expect(state.outcome, CompletionOutcome.abandoned);
      expect(state.endedAt, _at(45));
      // The step in progress is not recorded — the schema has no state for it.
      expect(state.outcomes, hasLength(1));
      expect(state.outcomes.single.stepId, 'a');
    });

    test('is a no-op once the run is complete', () {
      final finished = _machine(steps: [_step('a')])
          .start(_t0)
          .completeStep(_at(10));
      expect(finished.abandon(_at(20)), finished);
    });
  });

  group('toLog', () {
    test('is null before the run finishes', () {
      expect(_machine().start(_t0).toLog('c1'), isNull);
    });

    test('builds a completed record with UTC timestamps', () {
      final log = _machine(steps: [_step('a'), _step('b')])
          .start(_t0)
          .completeStep(_at(30))
          .completeStep(_at(90))
          .toLog('c1');

      expect(log, isNotNull);
      expect(log!.id, 'c1');
      expect(log.routineId, 'r1');
      expect(log.outcome, CompletionOutcome.completed);
      expect(log.startedAt.isUtc, isTrue);
      expect(log.endedAt.isUtc, isTrue);
      expect(log.steps.map((s) => s.stepId), ['a', 'b']);
      expect(log.steps.last.actualDurationSeconds, 60);
    });

    test('round-trips through JSON in the shape the schema expects', () {
      final log = _machine(steps: [_step('a')])
          .start(_t0)
          .skip(_at(15))
          .toLog('c1')!;

      // Encode and decode rather than inspecting toJson() directly: nested
      // freezed objects are only converted during encoding (explicit_to_json
      // is off project-wide, as ExportBundle already relies on), so this is
      // the shape that actually reaches drift today and
      // completions/YYYY-MM.ndjson in M4.
      final json =
          jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>;

      expect(json['routine_id'], 'r1');
      expect(json['outcome'], 'completed');
      expect(json['started_at'], '2026-08-02T09:00:00.000Z');
      expect((json['steps'] as List).single, {
        'step_id': 'a',
        'state': 'skipped',
        'actual_duration_seconds': 15,
      });
      expect(CompletionLog.fromJson(json), log);
    });
  });
}
