import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations.dart';
import '../services/home_widget/home_widget_publisher.dart';
import 'app_prefs_provider.dart';
import 'routines_provider.dart';

part 'home_widget_provider.g.dart';

@Riverpod(keepAlive: true)
HomeWidgetPublisher homeWidgetPublisher(Ref ref) => HomeWidgetPublisher();

/// Keeps the Android home screen widget in step with the routine list.
///
/// Hung off `routinesProvider` rather than off each mutation, for the same
/// reason the reminders are: create, rename, delete, reorder and a Drive sync
/// pulling another device's change all surface here, so no call site has to
/// remember to refresh the widget. Kept alive and watched from the root widget
/// so it also covers changes that arrive while the routines list is off screen.
@Riverpod(keepAlive: true)
Future<void> homeWidgetSync(Ref ref) async {
  final routines = await ref.watch(routinesProvider.future);
  final l10n = lookupAppLocalizations(
    _localeFor(ref.watch(localeOverrideSettingProvider)),
  );

  await ref
      .read(homeWidgetPublisherProvider)
      .publish(
        routines: routines,
        copy: WidgetCopy(
          title: l10n.widgetTitle,
          empty: l10n.widgetEmpty,
          openApp: l10n.widgetOpenApp,
        ),
      );
}

/// The locale `MaterialApp` will have resolved: the Settings override when
/// there is one, otherwise the device's first supported language. Resolved
/// here rather than read from a `BuildContext` because publishing has to work
/// whatever screen is on top — including none.
///
/// A system-locale change while the app is running therefore reaches the
/// widget on the next publish rather than immediately, which is a refresh the
/// user cannot perceive missing.
Locale _localeFor(String? override) {
  if (override != null) return Locale(override);

  final supported = AppLocalizations.supportedLocales.map(
    (locale) => locale.languageCode,
  );
  for (final locale in PlatformDispatcher.instance.locales) {
    if (supported.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return AppLocalizations.supportedLocales.first;
}
