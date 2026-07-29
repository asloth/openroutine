import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// Matches schemas/routine.schema.json's `schedule` object.
enum ScheduleMode { scheduled, flexible }

/// Matches schemas/routine.schema.json's `schedule.days` enum values.
enum DayOfWeek { mon, tue, wed, thu, fri, sat, sun }

@freezed
abstract class Schedule with _$Schedule {
  const factory Schedule({
    required ScheduleMode mode,
    @Default(<DayOfWeek>[]) List<DayOfWeek> days,
    // "HH:MM", 24-hour local time — see schemas/routine.schema.json.
    String? startTime,
  }) = _Schedule;

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
}
