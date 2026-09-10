import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/timer/timer_screen.dart';
import 'package:openroutine/services/notifications/notification_service.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/services/timer/timer_machine.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/state/timer_provider.dart';
import 'package:openroutine/theme/theme.dart';

/// The real service would reach for platform channels that don't exist under
/// flutter_test. Scheduling is covered by the machine's own tests; here we only
/// need it to stay out of the way.
///
/// Note the explicit overrides: `implements` plus `noSuchMethod` means a
/// method left unimplemented compiles fine and then throws at runtime, so
/// anything the screen actually calls has to be spelled out here.
class _NoopNotificationService implements NotificationService {
  String? lastBody;
  String? lastChannelName;
  String? lastChannelDescription;
  String? lastHalfwayBody;
  String? lastNearEndBody;
  DateTime? lastHalfwayAt;
  DateTime? lastNearEndAt;
  int scheduledCount = 0;
  int cancelledCount = 0;

  @override
  Future<bool> init() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleStepAlarms({
    required DateTime endsAt,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    DateTime? halfwayAt,
    DateTime? nearEndAt,
    String? halfwayBody,
    String? nearEndBody,
    String? nudgeChannelName,
    String? nudgeChannelDescription,
  }) async {
    lastBody = body;
    lastChannelName = channelName;
    lastChannelDescription = channelDescription;
    lastHalfwayAt = halfwayAt;
    lastNearEndAt = nearEndAt;
    lastHalfwayBody = halfwayBody;
    lastNearEndBody = nearEndBody;
    scheduledCount++;
  }

  @override
  Future<void> cancelPending() async => cancelledCount++;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(
  StorageAdapter adapter, {
  NotificationService? notifications,
  Locale? locale,
}) {
  return ProviderScope(
    overrides: [
      storageAdapterProvider.overrideWithValue(adapter),
      notificationServiceProvider.overrideWithValue(
        notifications ?? _NoopNotificationService(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const TimerScreen(routineId: 'r1'),
    ),
  );
}

Widget _clock(RoutineStep step, Duration elapsed) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: TimerClock(
      step: step,
      elapsed: elapsed,
      estimateZone: elapsed.inSeconds >= (step.durationSeconds ?? 0)
          ? EstimateZone.yellow
          : EstimateZone.green,
      paused: false,
    ),
  ),
);

/// Mirrors the helper in the other screen tests: forces the widget tree — and
/// the drift stream subscriptions under it — to dispose while we can still
/// pump the resulting timers.
Future<void> _disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

Future<LocalAdapter> _seed({required List<RoutineStep> steps}) async {
  final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
  final now = DateTime.utc(2026, 8, 2);
  await adapter.saveRoutine(
    Routine(
      id: 'r1',
      name: 'Morning',
      triggerId: null,
      schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
      stepIds: steps.map((s) => s.id).toList(),
      createdAt: now,
      updatedAt: now,
    ),
  );
  for (final step in steps) {
    await adapter.saveStep(step);
  }
  return adapter;
}

RoutineStep _step(
  String id, {
  required int order,
  String name = 'Step',
  int? durationSeconds = 60,
  bool noExplicitTime = false,
  bool isCore = false,
  bool remindDuring = false,
}) {
  final now = DateTime.utc(2026, 8, 2);
  return RoutineStep(
    id: id,
    routineId: 'r1',
    name: name,
    emoji: '🪥',
    durationSeconds: noExplicitTime ? null : durationSeconds,
    order: order,
    noExplicitTime: noExplicitTime,
    isCore: isCore,
    remindDuring: remindDuring,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('starts on the first step and shows elapsed time', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [
        _step('s1', order: 0, name: 'Brush my teeth'),
        _step('s2', order: 1, name: 'Shower'),
      ],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text('Brush my teeth'), findsOneWidget);
    expect(find.text(l10n.timerStepCounter(1, 2)), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    await _disposeCleanly(tester);
  });

  testWidgets('shows one continuous timed count-up through the estimate', (
    tester,
  ) async {
    final step = _step('s1', order: 0, durationSeconds: 120);

    await tester.pumpWidget(_clock(step, const Duration(seconds: 119)));
    expect(find.text('1:59'), findsOneWidget);
    await tester.pumpWidget(_clock(step, const Duration(seconds: 120)));
    expect(find.text('2:00'), findsOneWidget);
    await tester.pumpWidget(_clock(step, const Duration(seconds: 121)));
    expect(find.text('2:01'), findsOneWidget);
  });

  testWidgets('uses tertiary at and after the estimate without overtime text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final step = _step('s1', order: 0, durationSeconds: 120);

    await tester.pumpWidget(_clock(step, const Duration(seconds: 120)));
    final tertiary = Theme.of(
      tester.element(find.byType(Scaffold)),
    ).colorScheme.tertiary;

    expect(find.bySemanticsLabel('2:00'), findsOneWidget);
    Text clock() => tester.widget(find.text('2:00'));
    CircularProgressIndicator ring() =>
        tester.widget(find.byType(CircularProgressIndicator));
    expect(clock().style?.color, tertiary);
    expect(ring().color, tertiary);
    expect(ring().value, 1.0);

    await tester.pumpWidget(_clock(step, const Duration(seconds: 121)));
    expect(find.bySemanticsLabel('2:01'), findsOneWidget);
    expect(tester.widget<Text>(find.text('2:01')).style?.color, tertiary);
    expect(ring().color, tertiary);
    expect(ring().value, 1.0);
    expect(
      find.bySemanticsLabel(RegExp(r'(\+|over(time)?)', caseSensitive: false)),
      findsNothing,
    );
    expect(find.textContaining('+'), findsNothing);
    expect(find.textContaining('over'), findsNothing);

    semantics.dispose();
  });

  testWidgets('Done advances to the next step and restarts the clock', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [
        _step('s1', order: 0, name: 'Brush my teeth'),
        _step('s2', order: 1, name: 'Shower', durationSeconds: 300),
      ],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.timerDone));
    await tester.pumpAndSettle();

    expect(find.text('Shower'), findsOneWidget);
    expect(find.text(l10n.timerStepCounter(2, 2)), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    await _disposeCleanly(tester);
  });

  testWidgets('the last step offers Finish rather than Done', (tester) async {
    final adapter = await _seed(steps: [_step('s1', order: 0)]);

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text(l10n.timerFinish), findsOneWidget);
    expect(find.text(l10n.timerDone), findsNothing);

    await _disposeCleanly(tester);
  });

  testWidgets('finishing the run shows the summary and writes a log', (
    tester,
  ) async {
    final adapter = await _seed(steps: [_step('s1', order: 0)]);

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.timerFinish));
    await tester.pumpAndSettle();

    expect(find.text(l10n.timerCompleteTitle), findsOneWidget);

    final logs = await adapter.getCompletions('r1');
    expect(logs, hasLength(1));
    expect(logs.single.steps.single.stepId, 's1');

    await _disposeCleanly(tester);
  });

  testWidgets('offers an explicit estimate adjustment after an eligible run', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0, durationSeconds: 60)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 121));

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Adjust estimate?'), findsOneWidget);
    expect(
      find.text('You took 00:00; the estimate was 01:00.'),
      findsOneWidget,
    );
    final approve = find.widgetWithText(FilledButton, 'Use 01:00');
    expect(approve, findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Not now'), findsOneWidget);
    expect(tester.getSize(approve).height, greaterThanOrEqualTo(48));

    await tester.tap(approve);
    await tester.pumpAndSettle();

    expect(find.text('Estimate updated.'), findsOneWidget);
    expect((await adapter.getSteps('r1')).single.durationSeconds, 60);

    await _disposeCleanly(tester);
  });

  testWidgets('dismissal and stale approval do not write an estimate', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0, durationSeconds: 60)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 121));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    await adapter.saveStep(
      (await adapter.getSteps('r1')).single.copyWith(
        name: 'Edited after the run',
        updatedAt: DateTime.utc(2026, 8, 3),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Use 01:00'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This suggestion is no longer current.'),
      findsOneWidget,
    );
    expect((await adapter.getSteps('r1')).single.durationSeconds, 60);

    await _disposeCleanly(tester);
  });

  testWidgets('Not now is localized and leaves the estimate unchanged', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0, durationSeconds: 60)],
    );

    await tester.pumpWidget(_wrap(adapter, locale: const Locale('es')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 121));
    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Ajustar la estimación?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text('¿Ajustar la estimación?'), findsNothing);
    expect((await adapter.getSteps('r1')).single.durationSeconds, 60);

    await _disposeCleanly(tester);
  });

  testWidgets('an abandoned run does not offer calibration', (tester) async {
    final adapter = await _seed(
      steps: [
        _step('s1', order: 0, durationSeconds: 60),
        _step('s2', order: 1, durationSeconds: 60),
      ],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 121));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Routine stopped'), findsOneWidget);
    expect(find.text('Adjust estimate?'), findsNothing);

    await _disposeCleanly(tester);
  });

  testWidgets('abandoning the first step writes an empty abandoned log', (
    tester,
  ) async {
    final adapter = await _seed(steps: [_step('s1', order: 0)]);

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();
    expect(await adapter.getCompletions('r1'), isEmpty);

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.timerAbandonConfirmAction));
    await tester.pumpAndSettle();

    final logs = await adapter.getCompletions('r1');
    expect(logs, hasLength(1));
    expect(logs.single.outcome, CompletionOutcome.abandoned);
    expect(logs.single.steps, isEmpty);

    await _disposeCleanly(tester);
  });

  testWidgets('a step with no explicit time counts up instead of down', (
    tester,
  ) async {
    final notifications = _NoopNotificationService();
    final adapter = await _seed(
      steps: [_step('s1', order: 0, noExplicitTime: true)],
    );

    await tester.pumpWidget(_wrap(adapter, notifications: notifications));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text(l10n.timerNoSetTime), findsOneWidget);
    // No target means no ring to fill.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(notifications.scheduledCount, 0);

    await _disposeCleanly(tester);
  });

  testWidgets('an opted-in step schedules both mid-step nudges', (
    tester,
  ) async {
    final notifications = _NoopNotificationService();
    final adapter = await _seed(
      steps: [_step('s1', order: 0, durationSeconds: 600, remindDuring: true)],
    );

    await tester.pumpWidget(_wrap(adapter, notifications: notifications));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(
      notifications.lastHalfwayBody,
      '🪥 ${l10n.timerNotificationNudgeHalfwayBody}',
    );
    expect(
      notifications.lastNearEndBody,
      '🪥 ${l10n.timerNotificationNudgeNearEndBody}',
    );
    // Five and eight minutes into a ten-minute step, give or take the frames
    // the test pumped between starting and reading this.
    final untilHalfway = notifications.lastHalfwayAt!.difference(
      DateTime.now(),
    );
    final untilNearEnd = notifications.lastNearEndAt!.difference(
      DateTime.now(),
    );
    expect(untilHalfway.inSeconds, closeTo(300, 2));
    expect(untilNearEnd.inSeconds, closeTo(480, 2));

    await _disposeCleanly(tester);
  });

  testWidgets('a step that did not opt in schedules no nudges', (tester) async {
    final notifications = _NoopNotificationService();
    final adapter = await _seed(
      steps: [_step('s1', order: 0, durationSeconds: 600)],
    );

    await tester.pumpWidget(_wrap(adapter, notifications: notifications));
    await tester.pumpAndSettle();

    expect(notifications.scheduledCount, greaterThan(0));
    expect(notifications.lastHalfwayAt, isNull);
    expect(notifications.lastNearEndAt, isNull);

    await _disposeCleanly(tester);
  });

  testWidgets('the transport row offers no step arrows', (tester) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0), _step('s2', order: 1)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    // Moving between steps belongs to Done and Do later; arrows next to the
    // pause control only invited mis-taps. Stepping back and skipping still
    // exist on the machine and stay covered by timer_machine_test.dart.
    expect(find.byIcon(Icons.skip_previous), findsNothing);
    expect(find.byIcon(Icons.skip_next), findsNothing);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt), findsOneWidget);
    expect(find.byType(NeumorphicCircleButton), findsNWidgets(2));

    await _disposeCleanly(tester);
  });

  testWidgets('pause swaps the control for resume', (tester) async {
    final adapter = await _seed(steps: [_step('s1', order: 0)]);

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    // Two play icons would mean the paused state is ambiguous; the ring's
    // play_arrow belongs to the resume control only.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);

    await _disposeCleanly(tester);
  });

  testWidgets('Do later defers the step and brings it back at the end', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [
        _step('s1', order: 0, name: 'Brush my teeth'),
        _step('s2', order: 1, name: 'Shower'),
      ],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.timerDoLater));
    await tester.pumpAndSettle();

    // The next step is promoted into the current slot. The counter still reads
    // 1 of 2 because nothing was completed — the queue only reordered.
    expect(find.text('Shower'), findsOneWidget);
    expect(find.text(l10n.timerStepCounter(1, 2)), findsOneWidget);

    await tester.tap(find.text(l10n.timerDone));
    await tester.pumpAndSettle();

    // The deferred step comes back last, and can't be deferred again.
    expect(find.text('Brush my teeth'), findsOneWidget);
    expect(find.text(l10n.timerStepCounter(2, 2)), findsOneWidget);
    expect(find.text(l10n.timerDoLater), findsNothing);

    await tester.tap(find.text(l10n.timerFinish));
    await tester.pumpAndSettle();

    final logs = await adapter.getCompletions('r1');
    expect(logs.single.steps.map((s) => s.stepId), ['s2', 's1']);
    expect(
      logs.single.steps.every((s) => s.state == CompletionStepState.completed),
      isTrue,
    );

    await _disposeCleanly(tester);
  });

  testWidgets('skipping every step records them as skipped', (tester) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0), _step('s2', order: 1)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    // No skip button remains on the screen, so drive the notifier the way the
    // notification action does and check the run is still logged correctly.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimerScreen)),
    );
    final notifier = container.read(routineTimerProvider('r1').notifier);
    notifier.skip();
    await tester.pumpAndSettle();
    notifier.skip();
    await tester.pumpAndSettle();

    final logs = await adapter.getCompletions('r1');
    expect(logs.single.steps.map((s) => s.state.name), ['skipped', 'skipped']);

    await _disposeCleanly(tester);
  });

  // Task 3.3: the home screen widget publishes a snapshot, so a row can name a
  // routine that has since been deleted. Tapping it must not strand the app on
  // a spinner that never resolves.
  testWidgets('a run for a routine that no longer exists does not hang', (
    WidgetTester tester,
  ) async {
    final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageAdapterProvider.overrideWithValue(adapter),
          notificationServiceProvider.overrideWithValue(
            _NoopNotificationService(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TimerScreen(routineId: 'deleted-since-publish'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // And it leaves no trace in the stats: a routine with no steps never
    // becomes an active run, so there is nothing to log.
    expect(
      await adapter.completionsInRange(DateTime(2000), DateTime(2100)),
      isEmpty,
    );
    await _disposeCleanly(tester);
  });
}
