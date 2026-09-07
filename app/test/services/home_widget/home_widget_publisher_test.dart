import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/services/home_widget/home_widget_publisher.dart';

/// Captures what the publisher would hand to the plugin, so these tests never
/// touch a platform channel.
class _FakeSink implements HomeWidgetSink {
  final saved = <String, String>{};
  final updated = <String>[];
  Object? throwOnSave;

  @override
  Future<void> save(String key, String value) async {
    if (throwOnSave != null) throw throwOnSave!;
    saved[key] = value;
  }

  @override
  Future<void> update(String androidProviderName) async {
    updated.add(androidProviderName);
  }
}

const _copy = WidgetCopy(
  title: 'OpenRoutine',
  empty: 'No routines yet',
  openApp: 'Open OpenRoutine',
);

Routine _routine({
  required String id,
  required String name,
  ScheduleMode mode = ScheduleMode.scheduled,
  String? startTime,
  int stepCount = 0,
}) {
  final now = DateTime.utc(2026, 9, 6);
  return Routine(
    id: id,
    name: name,
    triggerId: null,
    schedule: Schedule(mode: mode, startTime: startTime),
    stepIds: List.generate(stepCount, (i) => '$id-step-$i'),
    createdAt: now,
    updatedAt: now,
  );
}

Map<String, dynamic> _published(_FakeSink sink) =>
    jsonDecode(sink.saved[HomeWidgetPublisher.dataKey]!)
        as Map<String, dynamic>;

List<Map<String, dynamic>> _routines(_FakeSink sink) =>
    (_published(sink)['routines'] as List).cast<Map<String, dynamic>>();

void main() {
  late _FakeSink sink;
  late HomeWidgetPublisher publisher;

  setUp(() {
    sink = _FakeSink();
    publisher = HomeWidgetPublisher(sink);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('publishes a versioned document under one key and redraws', () async {
    await publisher.publish(routines: const [], copy: _copy);

    expect(sink.saved.keys, [HomeWidgetPublisher.dataKey]);
    expect(_published(sink)['v'], HomeWidgetPublisher.payloadVersion);
    expect(sink.updated, [HomeWidgetPublisher.androidProviderName]);
  });

  test('carries the name, step count and start time of each routine', () async {
    await publisher.publish(
      routines: [
        _routine(id: 'r1', name: 'Morning', startTime: '07:30', stepCount: 7),
      ],
      copy: _copy,
    );

    expect(_routines(sink), [
      {'id': 'r1', 'name': 'Morning', 'startTime': '07:30', 'stepCount': 7},
    ]);
  });

  test('omits the start time of a routine that has none', () async {
    await publisher.publish(
      routines: [
        _routine(id: 'r1', name: 'Stretch', mode: ScheduleMode.flexible),
      ],
      copy: _copy,
    );

    expect(_routines(sink).single.containsKey('startTime'), isFalse);
  });

  test(
    'orders scheduled routines by start time, then flexible by name',
    () async {
      await publisher.publish(
        routines: [
          _routine(id: 'f2', name: 'Zen', mode: ScheduleMode.flexible),
          _routine(id: 's2', name: 'Evening', startTime: '21:00'),
          _routine(id: 'f1', name: 'Apnea', mode: ScheduleMode.flexible),
          _routine(id: 's1', name: 'Morning', startTime: '07:30'),
        ],
        copy: _copy,
      );

      expect(_routines(sink).map((r) => r['id']), ['s1', 's2', 'f1', 'f2']);
    },
  );

  test(
    'sorts a scheduled routine with no start time after the timed ones',
    () async {
      await publisher.publish(
        routines: [
          _routine(id: 'untimed', name: 'Anytime'),
          _routine(id: 'timed', name: 'Evening', startTime: '21:00'),
        ],
        copy: _copy,
      );

      expect(_routines(sink).map((r) => r['id']), ['timed', 'untimed']);
    },
  );

  test('orders flexible routines case-insensitively', () async {
    await publisher.publish(
      routines: [
        _routine(id: 'b', name: 'banana', mode: ScheduleMode.flexible),
        _routine(id: 'a', name: 'Apple', mode: ScheduleMode.flexible),
      ],
      copy: _copy,
    );

    expect(_routines(sink).map((r) => r['id']), ['a', 'b']);
  });

  test('carries the localized copy the widget renders', () async {
    await publisher.publish(routines: const [], copy: _copy);

    expect(_published(sink)['strings'], {
      'title': 'OpenRoutine',
      'empty': 'No routines yet',
      'openApp': 'Open OpenRoutine',
    });
  });

  test('publishes an empty list as a well-formed document', () async {
    await publisher.publish(routines: const [], copy: _copy);

    expect(_routines(sink), isEmpty);
    expect(sink.updated, isNotEmpty);
  });

  test('swallows a platform failure instead of propagating it', () async {
    sink.throwOnSave = Exception('no widget host');

    await expectLater(
      publisher.publish(routines: const [], copy: _copy),
      completes,
    );
    expect(sink.updated, isEmpty);
  });

  test('does nothing off Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await publisher.publish(
      routines: [_routine(id: 'r1', name: 'Morning')],
      copy: _copy,
    );

    expect(sink.saved, isEmpty);
    expect(sink.updated, isEmpty);
  });
}
