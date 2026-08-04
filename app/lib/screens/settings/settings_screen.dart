import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_prefs.dart';
import '../../state/app_prefs_provider.dart';
import '../../state/import_export_provider.dart';
import '../../state/package_info_provider.dart';
import '../../state/sync_provider.dart';

const _repoUrl = 'https://github.com/asloth/openroutine';
const _agentDocsUrl =
    'https://github.com/asloth/openroutine/blob/main/docs/for-agents.md';

/// docs/SPEC.md §7 screen 9: storage backend, sync status, connect and
/// disconnect Drive, language, Export all, About.
///
/// The Drive row is worded as "Connect Google Drive", never "Sign in with
/// Google" — the app has no account concept and works fully without one, and
/// §14 makes that framing part of how it is presented for App Store review.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final storageMode = ref.watch(storageModeSettingProvider);
    final localeOverride = ref.watch(localeOverrideSettingProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final driveAvailable = ref.watch(driveAvailableProvider);
    final sync = ref.watch(syncControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routinesMenuSettings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsStorageSection),
          RadioGroup<StorageMode>(
            groupValue: storageMode,
            onChanged: (value) {
              if (value == null) return;
              ref.read(storageModeSettingProvider.notifier).setMode(value);
              // Choosing Drive is the consent moment, so the grant prompt
              // belongs here rather than behind a second tap.
              if (value == StorageMode.drive) {
                ref.read(syncControllerProvider.notifier).connect();
              } else {
                ref.read(syncControllerProvider.notifier).disconnect();
              }
            },
            child: Column(
              children: [
                RadioListTile<StorageMode>(
                  value: StorageMode.local,
                  title: Text(l10n.storageModeLocalOnly),
                ),
                RadioListTile<StorageMode>(
                  value: StorageMode.drive,
                  // A build without OAuth client IDs — a fresh clone of the
                  // public repo — keeps the M2 treatment rather than offering
                  // an option that cannot work.
                  enabled: driveAvailable,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.storageModeGoogleDrive),
                      if (!driveAvailable) ...[
                        const SizedBox(width: 8),
                        _ComingSoonBadge(l10n.comingSoon),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    driveAvailable ? l10n.driveExplainer : l10n.driveUnavailable,
                  ),
                ),
              ],
            ),
          ),
          if (driveAvailable && storageMode == StorageMode.drive)
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              // The title has to match what tapping does, and in needsReauth
              // tapping reconnects — showing "Disconnect" there read as an
              // offer to undo something that had already come undone.
              title: Text(
                switch (sync.status) {
                  SyncStatus.disconnected ||
                  SyncStatus.needsReauth => l10n.driveConnect,
                  _ => l10n.driveDisconnect,
                },
              ),
              subtitle: Text(_syncLabel(l10n, sync)),
              onTap: () {
                final controller = ref.read(syncControllerProvider.notifier);
                switch (sync.status) {
                  case SyncStatus.disconnected:
                  case SyncStatus.needsReauth:
                    controller.connect();
                  default:
                    controller.disconnect();
                }
              },
            ),
          const Divider(),
          _SectionHeader(l10n.settingsLanguageSection),
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_localeLabel(l10n, localeOverride)),
            onTap: () => _pickLocale(context, ref, l10n, localeOverride),
          ),
          const Divider(),
          _SectionHeader(l10n.settingsDataSection),
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: Text(l10n.settingsExportAll),
            onTap: () => ref.read(exportServiceProvider).exportAll(),
          ),
          const Divider(),
          _SectionHeader(l10n.settingsAboutSection),
          ListTile(
            title: Text(l10n.appTitle),
            subtitle: packageInfoAsync.when(
              data: (info) =>
                  Text(l10n.settingsVersion(info.version, info.buildNumber)),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: Text(l10n.settingsViewOnGitHub),
            onTap: () => launchUrl(
              Uri.parse(_repoUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.settingsAgentDocs),
            onTap: () => launchUrl(
              Uri.parse(_agentDocsUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }

  /// Pending changes are worth surfacing over a bare "up to date", but only
  /// when nothing more urgent is happening — a lapsed grant or a failure is
  /// the more useful thing to read.
  String _syncLabel(AppLocalizations l10n, SyncSnapshot sync) {
    return switch (sync.status) {
      SyncStatus.disconnected => l10n.syncStatusDisconnected,
      SyncStatus.syncing => l10n.syncStatusSyncing,
      SyncStatus.offline => l10n.syncStatusOffline,
      SyncStatus.needsReauth => l10n.syncStatusNeedsReauth,
      SyncStatus.error => l10n.syncStatusError,
      SyncStatus.idle when sync.pendingChanges => l10n.syncStatusPending,
      SyncStatus.idle when sync.lastSyncAt != null => l10n.syncLastSynced(
        DateFormat.yMMMd().add_jm().format(sync.lastSyncAt!.toLocal()),
      ),
      SyncStatus.idle => l10n.syncStatusIdle,
    };
  }

  String _localeLabel(AppLocalizations l10n, String? override) {
    return switch (override) {
      'en' => l10n.settingsLanguageEnglish,
      'es' => l10n.settingsLanguageSpanish,
      _ => l10n.settingsLanguageSystem,
    };
  }

  Future<void> _pickLocale(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String? current,
  ) async {
    // showDialog<T> resolves with `null` both when the user explicitly
    // dismisses without choosing (tap outside / back button) AND when they
    // pick "System default" (which is itself represented by a null locale
    // code). Wrapping every real choice in _LocaleChoice keeps those two
    // cases distinguishable — a bare `null` result means "no choice made,
    // leave the setting alone."
    final selected = await showDialog<_LocaleChoice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          RadioGroup<String?>(
            groupValue: current,
            onChanged: (value) =>
                Navigator.of(context).pop(_LocaleChoice(value)),
            child: Column(
              children: [
                RadioListTile<String?>(
                  value: null,
                  title: Text(l10n.settingsLanguageSystem),
                ),
                RadioListTile<String?>(
                  value: 'en',
                  title: Text(l10n.settingsLanguageEnglish),
                ),
                RadioListTile<String?>(
                  value: 'es',
                  title: Text(l10n.settingsLanguageSpanish),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await ref
        .read(localeOverrideSettingProvider.notifier)
        .setLocale(selected.code);
  }
}

class _LocaleChoice {
  const _LocaleChoice(this.code);

  final String? code;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
