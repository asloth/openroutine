import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/models/step.dart';
import 'package:openroutine/services/notifications/notification_service.dart';
import 'package:openroutine/services/sounds/app_sounds.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/sound_provider.dart';
import 'package:openroutine/state/storage_provider.dart';
import 'package:openroutine/state/timer_provider.dart';

class _FakeSounds implements AppSounds {
  final played = <AppSound>[];
  var preloads = 0;

  @override
  Future<void> preload() async => preloads++;

  @override
  Future<void> play(AppSound sound) async => played.add(sound);
}

class _NoopNotifications implements NotificationService {
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
  }) async {}

  @override
  Future<void> cancelPending() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _now = DateTime.utc(2026, 10, 6);

RoutineStep _step(String id, int order) => RoutineStep(
  id: id,
  routineId: 'r1',
  name: 'Step $id',
  emoji: '✅',
  durationSeconds: 60,
  order: order,
  noExplicitTime: false,
  isCore: false,
  remindDuring: false,
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  late _FakeSounds sounds;
  late ProviderContainer container;

  setUp(() async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final adapter = LocalAdapter(database);
    await adapter.saveRoutine(
      Routine(
        id: 'r1',
        name: 'Morning',
        schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
        stepIds: const ['s1', 's2'],
        createdAt: _now,
        updatedAt: _now,
      ),
    );
    sounds = _FakeSounds();
    container = ProviderContainer(
      overrides: [
        storageAdapterProvider.overrideWithValue(adapter),
        notificationServiceProvider.overrideWithValue(_NoopNotifications()),
        appSoundsProvider.overrideWithValue(sounds),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<RoutineTimer> started() async {
    final timer = container.read(routineTimerProvider('r1').notifier);
    // Keep the auto-dispose provider alive for the whole test.
    container.listen(routineTimerProvider('r1'), (_, _) {});
    timer.load([_step('s1', 0), _step('s2', 1)]);
    await timer.start(
      notificationBody: '',
      notificationChannelName: '',
      notificationChannelDescription: '',
      nudgeHalfwayBody: '',
      nudgeNearEndBody: '',
      nudgeChannelName: '',
      nudgeChannelDescription: '',
    );
    return timer;
  }

  test('finishing a step pops, finishing the routine celebrates', () async {
    final timer = await started();

    timer.completeStep();
    expect(sounds.played, [AppSound.stepDone]);

    timer.completeStep();
    expect(sounds.played, [
      AppSound.stepDone,
      AppSound.routineFinished,
    ], reason: 'the last step gets the party, not a second pop');
    // Let the run's log finish saving before the container goes away.
    await pumpEventQueue();
  });

  test('starting a run loads the sounds before the first one plays', () async {
    await started();

    expect(sounds.preloads, 1);
    expect(sounds.played, isEmpty);
  });

  test('skipping a step pops, like finishing one', () async {
    final timer = await started();

    timer.skip();
    expect(sounds.played, [AppSound.stepDone]);
  });

  test('stopping early makes no sound', () async {
    final timer = await started();

    timer.abandon();
    expect(sounds.played, isEmpty);
    await pumpEventQueue();
  });
}
