import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../theme/palette.dart';

/// The localised text the home screen widget renders. Resolved app-side and
/// pushed with the data, the same shape `ReminderCopy` uses — the widget has
/// no access to the ARB files, and forking the copy into a native
/// `values-es/strings.xml` would break the project's rule that user-facing
/// strings live in `app_en.arb` and `app_es.arb` together.
class WidgetCopy {
  const WidgetCopy({
    required this.title,
    required this.empty,
    required this.openApp,
    required this.steps,
  });

  final String title;
  final String empty;
  final String openApp;

  /// The pluralised step-count subtitle. A function rather than a string
  /// because only Dart has the plural rules — the widget would otherwise need
  /// its own native plurals, in every language, kept in step by hand.
  final String Function(int count) steps;

  Map<String, String> toJson() => {
    'title': title,
    'empty': empty,
    'openApp': openApp,
  };
}

/// The colors the widget draws with: your palette in light and in dark, and
/// which of the two your theme setting picks. The widget can't read the app's
/// theme, so the app resolves it and sends the result along with the data.
///
/// Both schemes go every time, rather than only the one showing now, so the
/// widget can follow the system's dark mode while the app is closed.
class WidgetTheme {
  const WidgetTheme({
    required this.mode,
    required this.light,
    required this.dark,
  });

  factory WidgetTheme.of(Palette palette, ThemeMode mode) => WidgetTheme(
    mode: mode,
    light: palette.scheme(Brightness.light),
    dark: palette.scheme(Brightness.dark),
  );

  final ThemeMode mode;
  final ColorScheme light;
  final ColorScheme dark;

  Map<String, Object> toJson() => {
    'mode': mode.name,
    'light': _colors(light),
    'dark': _colors(dark),
  };

  /// ARGB ints, which Kotlin reads straight into a color.
  static Map<String, int> _colors(ColorScheme scheme) => {
    'background': scheme.surface.toARGB32(),
    'onSurface': scheme.onSurface.toARGB32(),
    'onSurfaceVariant': scheme.onSurfaceVariant.toARGB32(),
    'accent': scheme.primary.toARGB32(),
    'divider': scheme.outlineVariant.toARGB32(),
  };
}

/// The plugin calls the publisher makes, behind a seam so tests can watch what
/// would have been written without a platform channel.
abstract class HomeWidgetSink {
  Future<void> save(String key, String value);

  Future<void> update(String androidProviderName);
}

class PluginHomeWidgetSink implements HomeWidgetSink {
  const PluginHomeWidgetSink();

  @override
  Future<void> save(String key, String value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> update(String androidProviderName) =>
      HomeWidget.updateWidget(name: androidProviderName);
}

/// Publishes the routine list to the Android home screen widget.
///
/// The widget never reads the database. Reimplementing drift's schema — soft
/// deletes, the flattened schedule columns, the JSON-encoded step lists — in
/// Kotlin would fork the storage contract into a second language, and would
/// mean a second SQLite connection against a live one. Instead the app pushes
/// a denormalized snapshot every time the routine list changes, and the widget
/// only renders what it is given.
class HomeWidgetPublisher {
  HomeWidgetPublisher([HomeWidgetSink? sink])
    : _sink = sink ?? const PluginHomeWidgetSink();

  final HomeWidgetSink _sink;

  /// One key holds the whole document. Versioned so a future shape change can
  /// be recognised by a widget that has not been redrawn since the upgrade.
  static const dataKey = 'routines_v1';

  static const payloadVersion = 1;

  /// Must match the `AppWidgetProvider` class name in the Android manifest.
  static const androidProviderName = 'RoutineWidgetProvider';

  /// Writes the snapshot and asks Android to redraw. Without a [theme], the
  /// widget keeps the colors built into its resources.
  ///
  /// Never throws. A missing widget host, a platform channel that is not
  /// there, a launcher that has gone away — none of it should surface in an
  /// app whose actual job is running routines, so failures are swallowed the
  /// way `NotificationService.init` swallows its own.
  Future<void> publish({
    required List<Routine> routines,
    required WidgetCopy copy,
    WidgetTheme? theme,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final payload = jsonEncode({
      'v': payloadVersion,
      'routines': _ordered(
        routines,
      ).map((routine) => _encode(routine, copy)).toList(),
      'strings': copy.toJson(),
      'theme': ?theme?.toJson(),
    });

    try {
      await _sink.save(dataKey, payload);
      await _sink.update(androidProviderName);
    } catch (error) {
      debugPrint('Home widget update skipped: $error');
    }
  }

  Map<String, Object> _encode(Routine routine, WidgetCopy copy) => {
    'id': routine.id,
    'name': routine.name,
    // The raw "HH:MM" from the schema, not a formatted string: the widget
    // formats it natively so it follows the phone's 12/24-hour setting, which
    // can change long after this was published.
    if (routine.schedule.startTime != null)
      'startTime': routine.schedule.startTime!,
    'steps': copy.steps(routine.stepIds.length),
  };

  /// The order the in-app list uses: scheduled routines by start time, then
  /// flexible ones by name. A scheduled routine with no start time sorts after
  /// the timed ones rather than jumping to the front on a null comparison.
  List<Routine> _ordered(List<Routine> routines) {
    final scheduled = <Routine>[];
    final flexible = <Routine>[];
    for (final routine in routines) {
      (routine.schedule.mode == ScheduleMode.scheduled ? scheduled : flexible)
          .add(routine);
    }

    scheduled.sort((a, b) {
      final aTime = a.schedule.startTime;
      final bTime = b.schedule.startTime;
      if (aTime == null && bTime == null) return _byName(a, b);
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final byTime = aTime.compareTo(bTime);
      return byTime != 0 ? byTime : _byName(a, b);
    });
    flexible.sort(_byName);

    return [...scheduled, ...flexible];
  }

  int _byName(Routine a, Routine b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
