import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_prefs.dart';
import '../../state/app_prefs_provider.dart';
import '../../state/import_export_provider.dart';
import '../../state/package_info_provider.dart';

const _repoUrl = 'https://github.com/asloth/openroutine';
const _agentDocsUrl =
    'https://github.com/asloth/openroutine/blob/main/docs/for-agents.md';

/// docs/SPEC.md §7 screen 9, scoped to what M2 actually has: storage
/// backend (Drive disabled — same "Coming soon" treatment as onboarding),
/// language, Export all, About. Sync status / connect-Drive are M4.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final storageMode = ref.watch(storageModeSettingProvider);
    final localeOverride = ref.watch(localeOverrideSettingProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routinesMenuSettings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsStorageSection),
          RadioGroup<StorageMode>(
            groupValue: storageMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(storageModeSettingProvider.notifier).setMode(value);
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
                  enabled: false,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.storageModeGoogleDrive),
                      const SizedBox(width: 8),
                      _ComingSoonBadge(l10n.comingSoon),
                    ],
                  ),
                ),
              ],
            ),
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
