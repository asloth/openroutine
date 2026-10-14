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
import '../routines_list/home/home_ink.dart';
import '../../theme/theme.dart';
import '../../widgets/form_save_button.dart';
import '../../widgets/tinted/page_header.dart';
import '../../widgets/tinted/soft_back_button.dart';
import '../../widgets/tinted/soft_circle_button.dart';

/// What a draft-mode [StepFormScreen] hands back when it closes.
sealed class StepDraftResult {
  const StepDraftResult();
}

/// The step as you left it, ready for the routine form to hold.
final class StepDraftSaved extends StepDraftResult {
  const StepDraftSaved(this.step);

  final RoutineStep step;
}

/// You deleted the drafted step.
final class StepDraftRemoved extends StepDraftResult {
  const StepDraftRemoved();
}

/// docs/SPEC.md §7 screens 5 (Add step) and 6 (Edit step), combined into one
/// screen: the same form serves both, with a template picker shown only
/// when creating.
class StepFormScreen extends ConsumerStatefulWidget {
  const StepFormScreen({super.key, required this.routineId, this.stepId})
    : isDraft = false,
      initial = null;

  /// Draft mode: the routine form owns the steps until you save the routine,
  /// so this never touches storage. Save pops a [StepDraftSaved], Delete pops
  /// a [StepDraftRemoved], and backing out pops nothing.
  const StepFormScreen.draft({super.key, required this.routineId, this.initial})
    : isDraft = true,
      stepId = null;

  final String routineId;

  /// Null means create; non-null means edit that stored step.
  final String? stepId;

  final bool isDraft;

  /// The drafted step being edited. Null means a new one.
  final RoutineStep? initial;

  @override
  ConsumerState<StepFormScreen> createState() => _StepFormScreenState();
}

class _StepFormScreenState extends ConsumerState<StepFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _emoji;
  int _minutes = 5;
  bool _noExplicitTime = false;
  bool _isCore = false;

  /// On by default, deliberately: the stored default is false so that steps
  /// created before this existed stay silent, while a step someone is
  /// creating right now is offered the reminder rather than hiding it behind
  /// a switch nobody finds. `_loadFrom` overwrites this when editing.
  bool _remindDuring = true;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEditing => widget.stepId != null || widget.initial != null;

  /// Fixed one-tap duration choices. The stepper reaches every other value,
  /// so a step whose minutes aren't one of these (an edit, or a template that
  /// seeded an odd number) simply shows no preset selected. Opening the form
  /// never snaps what's stored.
  static const _durationPresets = [2, 5, 10, 20];

  /// The stepper's range, matching what `_loadFrom` clamps stored steps to.
  static const _minMinutes = 1;
  static const _maxMinutes = 999;

  @override
  void initState() {
    super.initState();
    // The save button's label and enabled state follow the name.
    _nameController.addListener(_onNameChanged);
    final initial = widget.initial;
    if (initial != null) _loadFrom(initial);
  }

  void _onNameChanged() => setState(() {});

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
    _isCore = step.isCore;
    _remindDuring = step.remindDuring;
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

  Future<void> _pickTemplate(
    AppLocalizations l10n,
    List<StepTemplateCategory> categories,
  ) async {
    final selected = await showModalBottomSheet<StepTemplate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (final category in categories)
                  _TemplateCategorySection(
                    label: stepTemplateCategoryLabel(l10n, category.id),
                    templates: category.steps,
                    onSelected: (template) =>
                        Navigator.of(context).pop(template),
                  ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) _applyTemplate(l10n, selected);
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
    final now = nowUtc();
    final durationSeconds = _noExplicitTime ? null : _minutes * 60;

    if (widget.isDraft) {
      final name = _nameController.text.trim();
      final remindDuring = _remindDuring && !_noExplicitTime;
      final initial = widget.initial;
      // The routine form assigns `order` and `updatedAt` when it saves, so
      // a new step's values here are placeholders.
      final step = initial == null
          ? RoutineStep(
              id: newId(),
              routineId: widget.routineId,
              name: name,
              emoji: _emoji!,
              durationSeconds: durationSeconds,
              order: 0,
              noExplicitTime: _noExplicitTime,
              isCore: _isCore,
              remindDuring: remindDuring,
              createdAt: now,
              updatedAt: now,
            )
          : initial.copyWith(
              name: name,
              emoji: _emoji!,
              durationSeconds: durationSeconds,
              noExplicitTime: _noExplicitTime,
              isCore: _isCore,
              remindDuring: remindDuring,
            );
      context.pop(StepDraftSaved(step));
      return;
    }

    setState(() => _saving = true);
    final storage = ref.read(storageAdapterProvider);

    if (_isEditing) {
      final existing = await ref.read(
        stepProvider(widget.routineId, widget.stepId!).future,
      );
      final updated = existing!.copyWith(
        name: _nameController.text.trim(),
        emoji: _emoji!,
        durationSeconds: durationSeconds,
        noExplicitTime: _noExplicitTime,
        isCore: _isCore,
        remindDuring: _remindDuring && !_noExplicitTime,
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
        isCore: _isCore,
        remindDuring: _remindDuring && !_noExplicitTime,
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
    if (confirmed != true || !mounted) return;

    if (widget.isDraft) {
      context.pop(const StepDraftRemoved());
      return;
    }

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

    final stepAsync = widget.stepId != null
        ? ref.watch(stepProvider(widget.routineId, widget.stepId!))
        : null;
    if (stepAsync != null) {
      final step = stepAsync.value;
      if (step != null) _loadFrom(step);
      if (stepAsync.isLoading && !_loaded) {
        return Scaffold(
          appBar: AppBar(
            leading: SoftBackButton.asAppBarLeading(),
            leadingWidth: SoftBackButton.appBarLeadingWidth,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (stepAsync.hasError) {
        return Scaffold(
          appBar: AppBar(
            leading: SoftBackButton.asAppBarLeading(),
            leadingWidth: SoftBackButton.appBarLeadingWidth,
          ),
          body: Center(child: Text(l10n.commonLoadError)),
        );
      }
      if (!stepAsync.isLoading && step == null) {
        return Scaffold(
          appBar: AppBar(
            leading: SoftBackButton.asAppBarLeading(),
            leadingWidth: SoftBackButton.appBarLeadingWidth,
          ),
          body: Center(child: Text(l10n.commonItemUnavailable)),
        );
      }
    }

    final ink = HomeInk.of(context);
    final hasName = _nameController.text.trim().isNotEmpty;

    final noTime = _noExplicitTime;

    return Scaffold(
      // Same as the routine form: the button is the point of the screen, and
      // until there's a name it says what's missing instead of failing.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: FormSaveButton(
          key: const Key('step-form-save'),
          label: hasName ? l10n.commonSave : l10n.stepFormNameFirst,
          saving: _saving,
          onPressed: _saving || !hasName ? null : _save,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: PageHeader(
                  leading: const SoftBackButton(),
                  title: _isEditing
                      ? l10n.stepFormEditTitle
                      : l10n.stepFormAddTitle,
                  actions: [
                    if (_isEditing)
                      SoftCircleButton(
                        icon: Icons.delete_outline,
                        tooltip: l10n.commonDelete,
                        onPressed: _delete,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _StepCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _EmojiTile(
                                emoji: _emoji,
                                onTap: () => emojiCategoriesAsync.value != null
                                    ? _pickEmoji(emojiCategoriesAsync.value!)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  maxLength: 50,
                                  style: _nameStyle.copyWith(color: ink.ink),
                                  decoration: InputDecoration(
                                    hintText: l10n.stepFormNameHint,
                                    hintStyle: _nameStyle.copyWith(
                                      color: ink.muted(0.4),
                                    ),
                                    counterText: '',
                                    filled: false,
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                      ? l10n.stepFormNameRequired
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          // The template picker sits *under* the name field,
                          // not above it, and behind a button rather than
                          // shown inline: a full-height wrap of every
                          // category at the top of the form pushed the field
                          // you opened the screen to type into below the
                          // fold. A sheet gets that same room for readable
                          // names without spending it against the form
                          // that's visible by default.
                          if (templatesAsync != null) ...[
                            const SizedBox(height: 16),
                            templatesAsync.when(
                              data: (categories) => _TemplateButton(
                                label: l10n.stepFormChooseTemplate,
                                onPressed: () =>
                                    _pickTemplate(l10n, categories),
                              ),
                              loading: () => const LinearProgressIndicator(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StepCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.stepFormHowLong.toUpperCase(),
                                  style: HomeInk.label.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 0.9,
                                    color: ink.muted(0.5),
                                  ),
                                ),
                              ),
                              _NoSetTimeToggle(
                                key: const Key('step-form-no-time'),
                                label: l10n.stepFormNoExplicitTime,
                                on: noTime,
                                onTap: () => setState(
                                  () => _noExplicitTime = !_noExplicitTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // With no estimate there are no minutes to choose,
                          // so the stepper and presets dim and stop taking
                          // taps, and the mid-step reminder below goes away:
                          // a nudge at half of no estimate is not a moment.
                          Opacity(
                            opacity: noTime ? 0.35 : 1,
                            child: IgnorePointer(
                              ignoring: noTime,
                              child: Column(
                                children: [
                                  _MinutesStepper(
                                    minutes: _minutes,
                                    enabled: !noTime,
                                    onChanged: (value) =>
                                        setState(() => _minutes = value),
                                    min: _minMinutes,
                                    max: _maxMinutes,
                                  ),
                                  const SizedBox(height: 16),
                                  _PresetTrack(
                                    presets: _durationPresets,
                                    selected: _minutes,
                                    onSelected: (value) =>
                                        setState(() => _minutes = value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StepCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (!noTime) ...[
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(l10n.stepFormRemindDuringLabel),
                              subtitle: Text(l10n.stepFormRemindDuringGuidance),
                              value: _remindDuring,
                              onChanged: (value) =>
                                  setState(() => _remindDuring = value),
                            ),
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: ink.hairline,
                            ),
                          ],
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(l10n.stepFormCoreLabel),
                            subtitle: Text(l10n.stepFormCoreGuidance),
                            value: _isCore,
                            onChanged: (value) =>
                                setState(() => _isCore = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _nameStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
}

/// "No set time", on the right of the How long heading. A text toggle rather
/// than a switch, so it reads as an answer to "how long?" instead of a
/// setting of its own.
class _NoSetTimeToggle extends StatelessWidget {
  const _NoSetTimeToggle({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Semantics(
      button: true,
      toggled: on,
      child: Material(
        color: on ? ink.accent : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: HomeInk.label.copyWith(
                    fontSize: 13,
                    color: on ? ink.onAction : ink.muted(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A white card on the paper, the same surface home and stats use.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Material(
      color: ink.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: ink.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The step's emoji on a softly tinted rounded square. Until you pick one it
/// shows a faded sparkle: a hint that the tile is tappable, not a chosen
/// emoji, so saving still asks for one.
class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji, required this.onTap});

  final String? emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(16));
    return Material(
      key: const Key('step-form-emoji'),
      color: ink.accent.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ink.accent.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Opacity(
              opacity: emoji == null ? 0.55 : 1,
              child: Text(emoji ?? '✨', style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Start from a template": a full-width button with a dashed accent outline
/// and a faint accent fill.
class _TemplateButton extends StatelessWidget {
  const _TemplateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(14));
    return CustomPaint(
      foregroundPainter: _DashedRRect(
        color: ink.accent.withValues(alpha: 0.5),
        radius: 14,
      ),
      child: Material(
        color: ink.accent.withValues(alpha: 0.06),
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  size: 18,
                  color: ink.accent,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: HomeInk.label.copyWith(
                      fontSize: 14,
                      color: ink.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Strokes a rounded rectangle as dashes. Flutter's own borders are solid
/// only, so the outline is walked by hand, as on home's anytime pill.
class _DashedRRect extends CustomPainter {
  const _DashedRRect({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.6),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) =>
      old.color != color || old.radius != radius;
}

/// Round minus and plus buttons around the big minutes number.
class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({
    required this.minutes,
    required this.enabled,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final int minutes;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SoftCircleButton(
          key: const Key('step-minutes-minus'),
          icon: Icons.remove,
          tooltip: l10n.stepFormMinutesLess,
          onPressed: enabled && minutes > min
              ? () => onChanged(minutes - 1)
              : null,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$minutes',
              key: const Key('step-minutes-value'),
              style: TextStyle(
                fontFamily: AppTypography.display,
                fontSize: 52,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: ink.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.stepFormMinutesUnit,
              style: HomeInk.label.copyWith(
                fontSize: 14,
                color: ink.muted(0.55),
              ),
            ),
          ],
        ),
        SoftCircleButton(
          key: const Key('step-minutes-plus'),
          icon: Icons.add,
          tooltip: l10n.stepFormMinutesMore,
          onPressed: enabled && minutes < max
              ? () => onChanged(minutes + 1)
              : null,
        ),
      ],
    );
  }
}

/// The preset minutes as a segmented row: the chosen one is a white pill
/// sitting on an accent-tinted track.
class _PresetTrack extends StatelessWidget {
  const _PresetTrack({
    required this.presets,
    required this.selected,
    required this.onSelected,
  });

  final List<int> presets;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    const radius = BorderRadius.all(Radius.circular(12));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.accent.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final value in presets)
              Expanded(
                child: Semantics(
                  key: Key('duration-$value'),
                  button: true,
                  selected: value == selected,
                  label: l10n.stepDurationMinutes(value),
                  excludeSemantics: true,
                  child: Material(
                    color: value == selected ? ink.card : Colors.transparent,
                    borderRadius: radius,
                    child: InkWell(
                      onTap: () => onSelected(value),
                      borderRadius: radius,
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Text(
                            l10n.stepDurationMinutes(value),
                            style: HomeInk.label.copyWith(
                              fontSize: 13,
                              color: value == selected
                                  ? ink.ink
                                  : ink.muted(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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

/// One category's section inside the template picker sheet: a heading,
/// followed by that category's templates as a wrap of chips.
class _TemplateCategorySection extends StatelessWidget {
  const _TemplateCategorySection({
    required this.label,
    required this.templates,
    required this.onSelected,
  });

  final String label;
  final List<StepTemplate> templates;
  final ValueChanged<StepTemplate> onSelected;

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
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final template in templates)
              _TemplateChip(
                template: template,
                onSelected: () => onSelected(template),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// A single template inside the picker sheet, reading as one line of text —
/// its emoji, its full name, and its duration when it has one — with no line
/// limit, so nothing about the name ever truncates or gets clipped.
class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.template, required this.onSelected});

  final StepTemplate template;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = templateStepName(l10n, template.id);
    final minutes = template.durationSeconds == null
        ? null
        : (template.durationSeconds! / 60).ceil();
    final label = minutes == null
        ? l10n.stepFormTemplateChipLabelNoDuration(template.emoji, name)
        : l10n.stepFormTemplateChipLabel(
            template.emoji,
            name,
            l10n.stepDurationMinutes(minutes),
          );

    return ActionChip(
      label: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      onPressed: onSelected,
    );
  }
}
