import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/completion_log.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/stats/stats_period.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/stats_provider.dart';
import 'package:openroutine/state/storage_provider.dart';

const _monday = 1;

void main() {
  late ProviderContainer container;
  // The providers read the real clock, so the runs are placed relative to it.
  final now = DateTime.now();
  DateTime daysAgo(int days) => DateTime(now.year, now.month, now.day - days, 12);

  setUp(() async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final adapter = LocalAdapter(database);
    final created = DateTime.utc(2026, 1, 1);
    await adapter.saveRoutine(
      Routine(
        id: 'r1',
        name: 'Morning',
        schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
        stepIds: const [],
        createdAt: created,
        updatedAt: created,
      ),
    );
    // A two-day streak ending today, and one run long enough ago that it's
    // always in a different week and a different month.
    for (final (id, day) in [('c1', 0), ('c2', 1), ('c3', 60)]) {
      final startedAt = daysAgo(day).toUtc();
      await adapter.appendCompletion(
        CompletionLog(
          id: id,
          routineId: 'r1',
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 10)),
          outcome: CompletionOutcome.completed,
          steps: const [],
        ),
      );
    }

    container = ProviderContainer(
      overrides: [storageAdapterProvider.overrideWithValue(adapter)],
    );
    addTearDown(container.dispose);
  });

  Future<T> read<T>(ProviderListenable<AsyncValue<T>> provider) async {
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    while (container.read(provider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return container.read(provider).requireValue;
  }

  test('a past week counts only its own runs', () async {
    final period = StatsPeriod.week(daysAgo(60), firstDayOfWeek: _monday);

    final stats = await read(statisticsProvider(period));

    expect(stats.completion.finished, 1);
  });

  test('a past month counts only its own runs', () async {
    final stats = await read(
      statisticsProvider(StatsPeriod.month(daysAgo(60))),
    );

    expect(stats.completion.finished, 1);
  });

  test('all time counts every run, however old', () async {
    final stats = await read(statisticsProvider(const StatsPeriod.allTime()));

    expect(stats.completion.finished, 3);
  });

  test('the streak counts back from today while a past week is shown', () async {
    final period = StatsPeriod.week(daysAgo(60), firstDayOfWeek: _monday);

    final stats = await read(statisticsProvider(period));

    expect(stats.completion.currentStreakDays, 2);
    expect(await read(streakDaysProvider), 2);
  });
}
