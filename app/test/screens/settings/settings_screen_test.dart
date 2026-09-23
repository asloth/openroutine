import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/screens/settings/settings_screen.dart';
import 'package:openroutine/state/app_prefs_provider.dart';
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
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
}
