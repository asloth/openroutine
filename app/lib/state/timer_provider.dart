import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/completion_log.dart';
import '../models/step.dart';
import '../services/id_generator.dart';
import '../services/notifications/notification_service.dart';
import '../services/timer/timer_machine.dart';
import 'storage_provider.dart';

part 'timer_provider.g.dart';

@riverpod
NotificationService notificationService(Ref ref) => NotificationService();

/// Drives one routine's Timer Mode run (docs/SPEC.md §8).
///
/// The rules live in [TimerState]; this notifier owns only the things a pure
/// value can't: the repaint ticker, the notification scheduling, and writing
/// the CompletionLog when the run ends.
///
/// Note this uses a codegen `Notifier`, where SPEC §8 says `StateNotifier` —
/// that package is legacy in Riverpod 3 and appears nowhere in this codebase.
/// The SPEC has been updated to match.
@riverpod
class RoutineTimer extends _$RoutineTimer {
  Timer? _ticker;

  /// Purely to force a repaint. It deliberately does not advance any counter:
  /// elapsed time is recomputed from wall-clock timestamps on every read, so a
  /// dropped or delayed tick costs a frame of smoothness, never correctness.
  static const _tickInterval = Duration(seconds: 1);

  @override
  TimerState build(String routineId) {
    // Resolved here rather than inside the callback: Riverpod forbids touching
    // Ref from within a lifecycle callback, and by disposal time the container
    // may already be tearing down.
    final notifications = ref.read(notificationServiceProvider);
    ref.onDispose(() {
      _ticker?.cancel();
      // Fire-and-forget: onDispose can't await, and a stale step notification
      // firing after the screen is gone would be worse than an unhandled
      // rejection here.
      unawaited(notifications.cancelPending());
    });
    return TimerState.idle(routineId: routineId, steps: const []);
  }

  /// Steps are loaded by the screen and handed in, so this notifier stays
  /// synchronous and the machine keeps its pure-value shape.
  void load(List<RoutineStep> steps) {
    if (state.phase != TimerPhase.idle) return;
    state = TimerState.idle(routineId: routineId, steps: steps);
  }

  Future<void> start() async {
    if (state.phase != TimerPhase.idle) return;
    // Asked for here rather than at launch so the prompt has visible context.
    // A refusal doesn't block the run — it only costs background alerts.
    await ref.read(notificationServiceProvider).requestPermission();
    _apply(state.start(DateTime.now()));
  }

  void pause() => _apply(state.pause(DateTime.now()));
  void resume() => _apply(state.resume(DateTime.now()));
  void completeStep() => _apply(state.completeStep(DateTime.now()));
  void skip() => _apply(state.skip(DateTime.now()));
  void back() => _apply(state.back(DateTime.now()));
  void resetStep() => _apply(state.resetStep(DateTime.now()));
  void abandon() => _apply(state.abandon(DateTime.now()));

  void _apply(TimerState next) {
    if (identical(next, state)) return;
    final wasActive = state.isActive;
    state = next;

    _syncTicker();
    unawaited(_syncNotification());

    // Terminal edge, entered exactly once: persist the run's log.
    if (wasActive && next.phase == TimerPhase.complete) {
      unawaited(_persist(next));
    }
  }

  void _syncTicker() {
    final shouldTick = state.phase == TimerPhase.running;
    if (shouldTick && _ticker == null) {
      _ticker = Timer.periodic(_tickInterval, (_) {
        // Reassigning the same value would be a no-op for Riverpod's equality
        // check, so nudge a field that genuinely changes with the clock.
        ref.notifyListeners();
      });
    } else if (!shouldTick) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _syncNotification() async {
    final notifications = ref.read(notificationServiceProvider);
    final endsAt = state.currentStepEndsAt(DateTime.now());
    final step = state.currentStep;
    if (endsAt == null || step == null) {
      await notifications.cancelPending();
      return;
    }
    await notifications.scheduleStepEnd(
      endsAt: endsAt,
      title: step.name,
      body: '${step.emoji} ${_bodyFor(step)}',
    );
  }

  // Kept deliberately short and locale-free: this string is built off the UI
  // thread with no BuildContext to hand. Localizing it means passing the
  // strings down from the screen, which is a follow-up if it matters.
  String _bodyFor(RoutineStep step) => 'Time is up';

  Future<void> _persist(TimerState finished) async {
    final log = finished.toLog(newId());
    if (log == null || log.steps.isEmpty) return;
    await ref.read(storageAdapterProvider).appendCompletion(log);
    ref.invalidate(routineCompletionsProvider(finished.routineId));
  }
}

/// Completion history for the routine detail screen's last-7-day dots
/// (docs/SPEC.md §7 screen 3).
@riverpod
Future<List<CompletionLogView>> routineCompletions(
  Ref ref,
  String routineId,
) async {
  // Midnight-anchored rather than "now minus 7 days" so the dots line up with
  // calendar days, which is what a row of day dots implies.
  final now = DateTime.now();
  final since = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 6))
      .toUtc();
  final logs = await ref
      .watch(storageAdapterProvider)
      .getCompletions(routineId, since: since);
  return logs
      .map(
        (log) => CompletionLogView(
          localDay: DateTime(
            log.startedAt.toLocal().year,
            log.startedAt.toLocal().month,
            log.startedAt.toLocal().day,
          ),
          completed: log.outcome == CompletionOutcome.completed,
        ),
      )
      .toList();
}

/// A completion reduced to what the dots actually need: which local calendar
/// day it happened on, and whether it finished.
class CompletionLogView {
  const CompletionLogView({required this.localDay, required this.completed});

  final DateTime localDay;
  final bool completed;
}
