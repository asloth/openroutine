import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/home_widget/home_widget_publisher.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/home_widget_provider.dart';
import 'package:openroutine/state/routines_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSink implements HomeWidgetSink {
  final saved = <String>[];

  @override
  Future<void> save(String key, String value) async => saved.add(value);

  @override
  Future<void> update(String androidProviderName) async {}
}

Routine _routine(String name) {
  final now = DateTime.utc(2026, 9, 6);
  return Routine(
    id: name,
    name: name,
    triggerId: null,
    schedule: const Schedule(mode: ScheduleMode.flexible),
    stepIds: const [],
    createdAt: now,
    updatedAt: now,
  );
}

/// Boots a container already listening to the sync provider.
///
/// The listener is not optional: `routinesProvider` is auto-disposed, so a
/// container that only reads a future lets it dispose before the stream has
/// emitted — which is also what keeps the real app's publisher alive, since
/// the root widget watches it for the whole session.
Future<(ProviderContainer, _FakeSink)> _boot(
  Stream<List<Routine>> routines, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  final sink = _FakeSink();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      routinesProvider.overrideWith((ref) => routines),
      homeWidgetPublisherProvider.overrideWithValue(HomeWidgetPublisher(sink)),
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(homeWidgetSyncProvider, (_, _) {});
  addTearDown(subscription.close);
  return (container, sink);
}

/// Waits for the publisher to catch up, rather than guessing at a delay.
Future<void> _publishes(_FakeSink sink, int count) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (sink.saved.length < count) {
    if (DateTime.now().isAfter(deadline)) {
      fail('expected $count publishes, saw ${sink.saved.length}');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

Map<String, dynamic> _payload(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

List<String> _names(String raw) => (_payload(raw)['routines'] as List)
    .map((r) => (r as Map<String, dynamic>)['name'] as String)
    .toList();

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('publishes the routine list as soon as it resolves', () async {
    final (_, sink) = await _boot(Stream.value([_routine('Morning')]));

    await _publishes(sink, 1);

    expect(_names(sink.saved.single), ['Morning']);
  });

  test('republishes on every change to the routine list', () async {
    final routines = StreamController<List<Routine>>();
    addTearDown(routines.close);
    final (_, sink) = await _boot(routines.stream);

    routines.add([_routine('Morning')]);
    await _publishes(sink, 1);
    routines.add([_routine('Morning'), _routine('Evening')]);
    await _publishes(sink, 2);

    expect(_names(sink.saved.last), ['Evening', 'Morning']);
  });

  test('publishes the copy for the chosen locale', () async {
    final (_, sink) = await _boot(
      Stream.value([_routine('Morning')]),
      prefs: {'locale_override': 'es'},
    );

    await _publishes(sink, 1);

    expect(
      (_payload(sink.saved.single)['strings'] as Map<String, dynamic>)['empty'],
      'Todavía no hay rutinas',
    );
  });
}
