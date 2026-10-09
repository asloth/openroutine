import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/settings/settings_screen.dart';
import 'package:openroutine/services/feedback/feedback_email.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
import 'package:openroutine/state/feedback_provider.dart';
import 'package:openroutine/state/package_info_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:openroutine/state/sync_provider.dart';
import 'package:openroutine/widgets/tinted/soft_back_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings › Appearance used to show two pickers: a background palette
/// picker, then the accent picker. There is only one choice now — the
/// accent, which colours the whole app — so this pins that the section
/// renders the accent picker's own title and helper and nothing shaped like
/// the old palette picker (no "Custom" swatch, no second "{name} selected"
/// caption).
class _FixedSync extends SyncController {
  _FixedSync(this._snapshot);

  final SyncSnapshot _snapshot;

  @override
  SyncSnapshot build() => _snapshot;

  int syncAgainCalls = 0;
  int disconnectCalls = 0;

  @override
  Future<void> syncAgain() async => syncAgainCalls++;

  @override
  Future<void> disconnect() async => disconnectCalls++;
}

_FixedSync? _lastSync;

Future<void> _pump(
  WidgetTester tester,
  SharedPreferences prefs, {
  SyncSnapshot? sync,
  UrlOpener? openUrl,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (openUrl != null) urlOpenerProvider.overrideWithValue(openUrl),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'OpenRoutine',
            packageName: 'app.openroutine.mobile',
            version: '1.2.0',
            buildNumber: '7',
          ),
        ),
        if (sync != null) ...[
          // The Drive section only renders when a build has OAuth ids, and a
          // test build never does.
          driveAvailableProvider.overrideWithValue(true),
          syncControllerProvider.overrideWith(
            () => _lastSync = _FixedSync(sync),
          ),
        ],
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('the Sounds switch is on by default and turns sounds off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    final toggle = find.widgetWithText(SwitchListTile, l10n.settingsSounds);
    await tester.scrollUntilVisible(toggle, 200);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(prefs.getBool('sounds_enabled'), isFalse);
  });

  testWidgets('the app bar leads with a SoftBackButton, not the stock arrow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(tester, prefs);

    expect(find.byType(SoftBackButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
  });

  testWidgets(
    'Appearance shows the accent picker and no theme picker or custom swatch',
    (tester) async {
      // The screen's ListView is taller than the default 600px test
      // surface, and a sliver list only builds the children within its
      // viewport — a tall enough surface keeps every section built so it can
      // be found, rather than the assertions depending on scroll position.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pump(tester, prefs);

      final context = tester.element(find.byType(SettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.settingsAccentTitle), findsOneWidget);
      expect(find.text(l10n.settingsAccentHelper), findsOneWidget);
      // The old palette picker's free-hue swatch had no built-in palette
      // behind it and was always labelled "Custom".
      expect(find.bySemanticsLabel('Custom'), findsNothing);
      // Ink iris is the default accent, and — with the palette picker gone —
      // this is the only "{name} selected" caption Appearance renders.
      expect(
        find.text(l10n.settingsThemeCurrent(l10n.accentColorIndigo)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the Theme row defaults to "Match my phone" and picking Light saves and '
    'updates the subtitle',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pump(tester, prefs);

      final context = tester.element(find.byType(SettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(l10n.settingsTheme), findsOneWidget);
      expect(find.text(l10n.settingsThemeSystem), findsOneWidget);

      await tester.tap(find.text(l10n.settingsTheme));
      await tester.pumpAndSettle();

      expect(find.text(l10n.settingsThemeLight), findsOneWidget);
      expect(find.text(l10n.settingsThemeDark), findsOneWidget);

      await tester.tap(find.text(l10n.settingsThemeLight));
      await tester.pumpAndSettle();

      expect(prefs.getString('theme_mode'), 'light');
      expect(find.text(l10n.settingsThemeLight), findsOneWidget);
      expect(find.text(l10n.settingsThemeSystem), findsNothing);
    },
  );

  testWidgets('a duplicate Drive folder is named as the reason sync stopped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The sync row belongs to Drive mode, so the status has somewhere to show.
    SharedPreferences.setMockInitialValues({'storage_mode': 'drive'});
    final prefs = await SharedPreferences.getInstance();
    await _pump(
      tester,
      prefs,
      sync: const SyncSnapshot(status: SyncStatus.ambiguousFolder),
    );

    final context = tester.element(find.byType(SettingsScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.syncStatusAmbiguousFolder), findsOneWidget);
  });

  testWidgets('a folder waiting for approval says so and offers to sync', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'storage_mode': 'drive'});
    final prefs = await SharedPreferences.getInstance();
    await _pump(
      tester,
      prefs,
      sync: const SyncSnapshot(status: SyncStatus.cutoverNeeded),
    );

    final context = tester.element(find.byType(SettingsScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.syncStatusCutoverNeeded), findsOneWidget);

    await tester.tap(find.text(l10n.driveSyncNow));
    expect(_lastSync!.syncAgainCalls, 1);
    expect(_lastSync!.disconnectCalls, 0);
  });

  testWidgets(
    'with a duplicate folder, the row offers to sync, not disconnect',
    (tester) async {
      // The message tells them to remove the extra folder and sync again, so
      // the row has to be the way to do that.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'storage_mode': 'drive'});
      final prefs = await SharedPreferences.getInstance();
      await _pump(
        tester,
        prefs,
        sync: const SyncSnapshot(status: SyncStatus.ambiguousFolder),
      );

      final context = tester.element(find.byType(SettingsScreen));
      final l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.driveDisconnect), findsNothing);

      await tester.tap(find.text(l10n.driveSyncNow));
      expect(_lastSync!.syncAgainCalls, 1);
      expect(_lastSync!.disconnectCalls, 0);
    },
  );

  group('Send feedback', () {
    Future<Finder> feedbackRow(WidgetTester tester) async {
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      final row = find.widgetWithText(ListTile, l10n.settingsSendFeedback);
      await tester.scrollUntilVisible(row, 200);
      return row;
    }

    testWidgets('opens an email draft to the feedback address', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final opened = <Uri>[];
      await _pump(
        tester,
        prefs,
        openUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      );

      await tester.tap(await feedbackRow(tester));
      await tester.pumpAndSettle();

      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'mailto');
      expect(opened.single.path, feedbackAddress);
      expect(opened.single.queryParameters['body'], contains('1.2.0 (7)'));
    });

    testWidgets('with no email app, shows the address with Copy', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pump(tester, prefs, openUrl: (_) async => false);
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

      await tester.tap(await feedbackRow(tester));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.feedbackNoEmailApp(feedbackAddress)),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SnackBarAction, l10n.feedbackCopyAddress),
        findsOneWidget,
      );
    });
  });
}
