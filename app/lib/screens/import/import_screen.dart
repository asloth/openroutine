import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/export_bundle.dart';
import '../../models/import_preview.dart';
import '../../services/import_export/import_service.dart';
import '../../state/import_export_provider.dart';
import '../../state/routines_provider.dart';

/// docs/SPEC.md §7 screen 8 / §10: file picker → validate against
/// schemas/*.json → preview (X to add / Y to update) → confirm. §10 only
/// defines a single last-writer-wins merge strategy — no separate
/// "replace" mode exists in the adapter, so this screen offers only merge.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ExportBundle? _bundle;
  ImportPreview? _preview;
  String? _errorMessage;
  bool _busy = false;
  bool _done = false;

  Future<void> _choose() async {
    setState(() {
      _errorMessage = null;
      _bundle = null;
      _preview = null;
      _busy = true;
    });
    try {
      final importService = await ref.read(importServiceProvider.future);
      final bundle = await importService.pickAndValidate();
      if (bundle == null) {
        setState(() => _busy = false);
        return;
      }
      final preview = await importService.preview(bundle);
      setState(() {
        _bundle = bundle;
        _preview = preview;
        _busy = false;
      });
    } on ImportException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _busy = false;
        _errorMessage = e.reason == ImportFailureReason.invalidJson
            ? l10n.importErrorInvalidJson
            : l10n.importErrorSchemaViolation;
      });
    }
  }

  Future<void> _confirm() async {
    final bundle = _bundle;
    if (bundle == null) return;
    setState(() => _busy = true);
    final importService = await ref.read(importServiceProvider.future);
    await importService.confirm(bundle);
    ref.invalidate(routinesProvider);
    ref.invalidate(triggersProvider);
    setState(() {
      _busy = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.importIntro),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _choose,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l10n.importChooseFile),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            if (_done)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  l10n.importSuccess,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else if (_preview != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.importPreviewTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_preview!.isEmpty)
                        Text(l10n.importPreviewEmpty)
                      else ...[
                        Text(
                          l10n.importPreviewRoutines(
                            _preview!.newRoutines,
                            _preview!.updatedRoutines,
                          ),
                        ),
                        Text(
                          l10n.importPreviewSteps(
                            _preview!.newSteps,
                            _preview!.updatedSteps,
                          ),
                        ),
                        Text(
                          l10n.importPreviewTriggers(
                            _preview!.newTriggers,
                            _preview!.updatedTriggers,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (_busy || _preview!.isEmpty) ? null : _confirm,
                child: Text(l10n.importConfirm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
