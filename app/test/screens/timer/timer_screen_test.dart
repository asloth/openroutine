import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/screens/timer/timer_screen.dart';
import 'package:openroutine/services/notifications/notification_service.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/services/storage/storage_adapter.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/state/timer_provider.dart';

/// The real service would reach for platform channels that don't exist under
/// flutter_test. Scheduling is covered by the machine's own tests; here we only
/// need it to stay out of the way.
class _NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleStepEnd({
    required DateTime endsAt,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelPending() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(StorageAdapter adapter) {
  return ProviderScope(
    overrides: [
      storageAdapterProvider.overrideWithValue(adapter),
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TimerScreen(routineId: 'r1'),
    ),
  );
}

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
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('starts on the first step and shows its countdown', (
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
    expect(find.text('01:00'), findsOneWidget);

    await _disposeCleanly(tester);
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
    expect(find.text('05:00'), findsOneWidget);

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

  testWidgets('a step with no explicit time counts up instead of down', (
    tester,
  ) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0, noExplicitTime: true)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text(l10n.timerNoSetTime), findsOneWidget);
    // No target means no ring to fill.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await _disposeCleanly(tester);
  });

  testWidgets('Back is unavailable on the first step', (tester) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0), _step('s2', order: 1)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    final back = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.skip_previous),
        matching: find.byType(IconButton),
      ),
    );
    expect(back.onPressed, isNull);

    // ...and becomes available once past it.
    await tester.tap(find.text(l10n.timerDone));
    await tester.pumpAndSettle();
    final backLater = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.skip_previous),
        matching: find.byType(IconButton),
      ),
    );
    expect(backLater.onPressed, isNotNull);

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

  testWidgets('skipping every step records them as skipped', (tester) async {
    final adapter = await _seed(
      steps: [_step('s1', order: 0), _step('s2', order: 1)],
    );

    await tester.pumpWidget(_wrap(adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pumpAndSettle();

    final logs = await adapter.getCompletions('r1');
    expect(logs.single.steps.map((s) => s.state.name), [
      'skipped',
      'skipped',
    ]);

    await _disposeCleanly(tester);
  });
}
