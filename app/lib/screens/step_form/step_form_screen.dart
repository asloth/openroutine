import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/emoji_category.dart';
import '../../models/step.dart';
import '../../models/step_template.dart';
import '../../services/id_generator.dart';
import '../../services/storage/storage_adapter.dart';
import '../../state/reference_data_provider.dart';
import '../../state/routines_provider.dart';
import '../../state/storage_provider.dart';

/// docs/SPEC.md §7 screens 5 (Add step) and 6 (Edit step), combined into one
/// screen: the same form serves both, with a template picker shown only
/// when creating.
class StepFormScreen extends ConsumerStatefulWidget {
  const StepFormScreen({super.key, required this.routineId, this.stepId});

  final String routineId;

  /// Null means create; non-null means edit that step.
  final String? stepId;

  @override
  ConsumerState<StepFormScreen> createState() => _StepFormScreenState();
}

class _StepFormScreenState extends ConsumerState<StepFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _emoji;
  int _minutes = 5;
  bool _noExplicitTime = false;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEditing => widget.stepId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadFrom(RoutineStep step) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = step.name;
    _emoji = step.emoji;
    _noExplicitTime = step.noExplicitTime;
    if (step.durationSeconds != null) {
      _minutes = (step.durationSeconds! / 60).ceil().clamp(1, 999);
    }
  }

  void _applyTemplate(AppLocalizations l10n, StepTemplate template) {
    setState(() {
      _nameController.text = templateStepName(l10n, template.id);
      _emoji = template.emoji;
      _noExplicitTime = template.noExplicitTime;
      if (template.durationSeconds != null) {
        _minutes = (template.durationSeconds! / 60).ceil().clamp(1, 999);
      }
    });
  }

  Future<void> _pickEmoji(List<EmojiCategory> categories) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                for (final category in categories)
                  _EmojiCategorySection(
                    label: emojiCategoryLabel(l10n, category.id),
                    emojis: category.emojis,
                    onSelected: (emoji) => Navigator.of(context).pop(emoji),
                  ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) setState(() => _emoji = selected);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_emoji == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.stepFormEmojiRequired),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final storage = ref.read(storageAdapterProvider);
    final now = nowUtc();
    final durationSeconds = _noExplicitTime ? null : _minutes * 60;

    if (_isEditing) {
      final existing = await ref.read(
        stepProvider(widget.routineId, widget.stepId!).future,
      );
      final updated = existing!.copyWith(
        name: _nameController.text.trim(),
        emoji: _emoji!,
        durationSeconds: durationSeconds,
        noExplicitTime: _noExplicitTime,
        updatedAt: now,
      );
      await storage.saveStep(updated);
      ref.invalidate(stepProvider(widget.routineId, widget.stepId!));
    } else {
      final existingSteps = await ref.read(
        routineStepsProvider(widget.routineId).future,
      );
      final step = RoutineStep(
        id: newId(),
        routineId: widget.routineId,
        name: _nameController.text.trim(),
        emoji: _emoji!,
        durationSeconds: durationSeconds,
        order: existingSteps.length,
        noExplicitTime: _noExplicitTime,
        createdAt: now,
        updatedAt: now,
      );
      await storage.saveStep(step);
    }
    ref.invalidate(routineStepsProvider(widget.routineId));
    ref.invalidate(routineProvider(widget.routineId));

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.stepFormDeleteConfirmTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(storageAdapterProvider).deleteStep(widget.stepId!);
    ref.invalidate(routineStepsProvider(widget.routineId));
    ref.invalidate(routineProvider(widget.routineId));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = _isEditing
        ? null
        : ref.watch(stepTemplateCategoriesProvider);
    final emojiCategoriesAsync = ref.watch(emojiCategoriesProvider);

    final stepAsync = _isEditing
        ? ref.watch(stepProvider(widget.routineId, widget.stepId!))
        : null;
    if (stepAsync != null) {
      final step = stepAsync.value;
      if (step != null) _loadFrom(step);
      if (stepAsync.isLoading && !_loaded) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.stepFormEditTitle : l10n.stepFormAddTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.commonDelete,
              onPressed: _delete,
            ),
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: l10n.commonSave,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (templatesAsync != null) ...[
              Text(
                l10n.stepFormTemplatesLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              templatesAsync.when(
                data: (categories) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final category in categories) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          stepTemplateCategoryLabel(l10n, category.id),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final template in category.steps)
                            ActionChip(
                              avatar: Text(template.emoji),
                              label: Text(templateStepName(l10n, template.id)),
                              onPressed: () => _applyTemplate(l10n, template),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const Divider(height: 32),
            ],
            Row(
              children: [
                InkWell(
                  onTap: () => emojiCategoriesAsync.value != null
                      ? _pickEmoji(emojiCategoriesAsync.value!)
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  child: CircleAvatar(
                    radius: 28,
                    child: Text(
                      _emoji ?? '➕',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: l10n.stepFormNameLabel,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? l10n.stepFormNameRequired
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.stepFormNoExplicitTime),
              value: _noExplicitTime,
              onChanged: (value) => setState(() => _noExplicitTime = value),
            ),
            if (!_noExplicitTime) ...[
              const SizedBox(height: 8),
              Text(
                l10n.stepFormDurationLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final minutes in {
                    (_minutes - 1).clamp(1, 999),
                    _minutes,
                    _minutes + 1,
                  })
                    ChoiceChip(
                      label: Text(l10n.stepDurationMinutes(minutes)),
                      selected: minutes == _minutes,
                      onSelected: (_) => setState(() => _minutes = minutes),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmojiCategorySection extends StatelessWidget {
  const _EmojiCategorySection({
    required this.label,
    required this.emojis,
    required this.onSelected,
  });

  final String label;
  final List<String> emojis;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Wrap(
          spacing: 4,
          children: [
            for (final emoji in emojis)
              InkWell(
                onTap: () => onSelected(emoji),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Maps assets/step_templates.json's category `id` to its ARB label —
/// mirrors emojiCategoryLabel below.
String stepTemplateCategoryLabel(AppLocalizations l10n, String id) {
  return switch (id) {
    'morning' => l10n.stepTemplateCategoryMorning,
    'evening' => l10n.stepTemplateCategoryEvening,
    'study' => l10n.stepTemplateCategoryStudy,
    'selfcare' => l10n.stepTemplateCategorySelfcare,
    _ => id,
  };
}

/// Maps a template step's `id` to its ARB display name.
String templateStepName(AppLocalizations l10n, String id) {
  return switch (id) {
    'brushTeeth' => l10n.stepTemplateBrushTeeth,
    'shower' => l10n.stepTemplateShower,
    'makeBed' => l10n.stepTemplateMakeBed,
    'breakfast' => l10n.stepTemplateBreakfast,
    'skincare' => l10n.stepTemplateSkincare,
    'read' => l10n.stepTemplateRead,
    'windDown' => l10n.stepTemplateWindDown,
    'focusBlock' => l10n.stepTemplateFocusBlock,
    'reviewNotes' => l10n.stepTemplateReviewNotes,
    'setGoals' => l10n.stepTemplateSetGoals,
    'meditate' => l10n.stepTemplateMeditate,
    'bath' => l10n.stepTemplateBath,
    'nails' => l10n.stepTemplateNails,
    _ => id,
  };
}

/// Maps assets/emojis.json's category `id` to its ARB label. Duplicated
/// from wherever the emoji picker widget lives (M2's only emoji picker
/// entry point is this screen) rather than shared, since there's exactly
/// one caller.
String emojiCategoryLabel(AppLocalizations l10n, String id) {
  return switch (id) {
    'activities' => l10n.emojiCategoryActivities,
    'food' => l10n.emojiCategoryFood,
    'self_care' => l10n.emojiCategorySelfCare,
    'work' => l10n.emojiCategoryWork,
    'home' => l10n.emojiCategoryHome,
    _ => id,
  };
}
