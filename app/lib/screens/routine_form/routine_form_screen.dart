import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/step.dart';
import '../../services/id_generator.dart';
import '../../services/routines/estimate.dart';
import '../../services/storage/storage_adapter.dart';
import '../../state/routines_provider.dart';
import '../../state/storage_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/form_save_button.dart';
import '../../widgets/step_list.dart';
import '../../widgets/tinted/soft_back_button.dart';
import '../routines_list/home/home_ink.dart';
import '../step_form/step_form_screen.dart';

/// docs/SPEC.md §7 screen 4, which also owns the routine's steps: they're
/// held in memory and written with the routine on Save, so backing out
/// leaves nothing behind and a routine can't be saved without a step.
class RoutineFormScreen extends ConsumerStatefulWidget {
  const RoutineFormScreen({super.key, this.routineId, this.initialMode});

  /// Null means create; non-null means edit that routine.
  final String? routineId;

  /// The schedule a new routine starts on. Onboarding passes the kind the
  /// user picked. Editing ignores it and loads the routine's own schedule.
  final ScheduleMode? initialMode;

  @override
  ConsumerState<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends ConsumerState<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late ScheduleMode _mode = widget.initialMode ?? ScheduleMode.flexible;
  final Set<DayOfWeek> _days = {};
  String? _startTime;
  bool _loaded = false;
  bool _saving = false;
  String? _daysError;
  String? _startTimeError;

  /// Assigned up front, so draft steps carry it before the routine exists.
  late final String _routineId = widget.routineId ?? newId();
  final List<RoutineStep> _steps = [];

  /// What's in storage, for working out what Save has to write.
  List<RoutineStep> _storedSteps = const [];

  /// The form as it opened, for telling whether backing out loses anything.
  late _Snapshot _opened;

  bool get _isEditing => widget.routineId != null;

  _Snapshot _snapshot() => (
    name: _nameController.text.trim(),
    mode: _mode,
    days: Set.of(_days),
    startTime: _startTime,
    steps: List.of(_steps),
  );

  bool get _isDirty {
    final now = _snapshot();
    return now.name != _opened.name ||
        now.mode != _opened.mode ||
        now.startTime != _opened.startTime ||
        !setEquals(now.days, _opened.days) ||
        !listEquals(now.steps, _opened.steps);
  }

  @override
  void initState() {
    super.initState();
    // Take the untouched snapshot now, before any edit can change the fields.
    _opened = _snapshot();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadFrom(Routine routine, List<RoutineStep> steps) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = routine.name;
    _mode = routine.schedule.mode;
    _days
      ..clear()
      ..addAll(routine.schedule.days);
    _startTime = routine.schedule.startTime;
    _storedSteps = steps;
    _steps
      ..clear()
      ..addAll(steps);
    _opened = _snapshot();
  }

  /// Opens the step form in draft mode: [index] edits that step, null adds
  /// one. Nothing is written until the routine is saved.
  Future<void> _openStep([int? index]) async {
    final result = await context.push<StepDraftResult>(
      '/routines/$_routineId/steps/draft',
      extra: index == null ? null : _steps[index],
    );
    if (!mounted || result == null) return;
    setState(() {
      switch (result) {
        case StepDraftSaved(:final step):
          index == null ? _steps.add(step) : _steps[index] = step;
        case StepDraftRemoved():
          if (index != null) _steps.removeAt(index);
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _steps.insert(newIndex, _steps.removeAt(oldIndex));
    });
  }

  Future<void> _confirmLeave() async {
    if (_isDirty) {
      final l10n = AppLocalizations.of(context)!;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            _isEditing
                ? l10n.routineFormDiscardEditTitle
                : l10n.routineFormDiscardNewTitle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.routineFormKeepEditing),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.routineFormDiscard),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) context.pop();
  }

  String _saveLabel(AppLocalizations l10n) {
    if (_steps.isEmpty) return l10n.commonSave;
    final seconds = routineEstimate(_steps).inSeconds;
    final summary = seconds == 0
        ? l10n.routinesStepCount(_steps.length)
        : l10n.routineFormStepsSummary(_steps.length, (seconds / 60).ceil());
    return l10n.routineFormSaveWith(l10n.commonSave, summary);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseStartTime(_startTime) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      _startTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _startTimeError = null;
    });
  }

  /// "HH:MM" per schemas/routine.schema.json — matches `_StartTime._parse` in
  /// routines_list_screen.dart. Anything malformed is treated as "no time"
  /// rather than crashing the picker it seeds.
  static TimeOfDay? _parseStartTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Moves the start time by [minutes], wrapping around midnight.
  ///
  /// A nudge, not a replacement for the picker: the steppers are for "make it
  /// a quarter of an hour later", and tapping the time itself is still how
  /// you jump somewhere else entirely.
  void _nudgeStartTime(int minutes) {
    final current =
        _parseStartTime(_startTime) ?? const TimeOfDay(hour: 7, minute: 0);
    final total = (current.hour * 60 + current.minute + minutes) % (24 * 60);
    final wrapped = total < 0 ? total + 24 * 60 : total;
    setState(() {
      _startTime =
          '${(wrapped ~/ 60).toString().padLeft(2, '0')}:'
          '${(wrapped % 60).toString().padLeft(2, '0')}';
      _startTimeError = null;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    // Days are required in both modes — a flexible routine still runs on
    // specific days, it just has no fixed start time. Only the scheduled
    // mode needs that time.
    final daysError = _days.isEmpty ? l10n.routineFormDaysRequired : null;
    final startTimeError = _mode == ScheduleMode.scheduled && _startTime == null
        ? l10n.routineFormStartTimeRequired
        : null;
    if (daysError != null || startTimeError != null) {
      setState(() {
        _daysError = daysError;
        _startTimeError = startTimeError;
      });
      return;
    }

    setState(() => _saving = true);

    final storage = ref.read(storageAdapterProvider);
    final now = nowUtc();
    final schedule = Schedule(
      mode: _mode,
      days: _days.toList(),
      startTime: _mode == ScheduleMode.scheduled ? _startTime : null,
    );
    final stepIds = [for (final step in _steps) step.id];

    final Routine routine;
    if (_isEditing) {
      final existing = await ref.read(routineProvider(_routineId).future);
      routine = existing!.copyWith(
        name: _nameController.text.trim(),
        schedule: schedule,
        stepIds: stepIds,
        updatedAt: now,
      );
    } else {
      routine = Routine(
        id: _routineId,
        name: _nameController.text.trim(),
        schedule: schedule,
        stepIds: stepIds,
        createdAt: now,
        updatedAt: now,
      );
    }

    // Only what changed gets a new `updatedAt`: bumping an untouched step
    // would let it win sync merges it has no business winning.
    final stored = {for (final step in _storedSteps) step.id: step};
    final changed = <RoutineStep>[];
    for (final (index, step) in _steps.indexed) {
      final placed = step.copyWith(order: index);
      final before = stored[step.id];
      if (placed == before) continue;
      changed.add(
        placed.copyWith(
          createdAt: before == null ? now : placed.createdAt,
          updatedAt: now,
        ),
      );
    }
    final removed = stored.keys.toSet().difference(stepIds.toSet());

    await storage.saveRoutineWithSteps(
      routine,
      changed,
      removedStepIds: removed,
    );
    ref.invalidate(routinesProvider);
    ref.invalidate(routineProvider(_routineId));
    ref.invalidate(routineStepsProvider(_routineId));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final routineAsync = _isEditing
        ? ref.watch(routineProvider(_routineId))
        : null;
    final stepsAsync = _isEditing
        ? ref.watch(routineStepsProvider(_routineId))
        : null;
    if (routineAsync != null && stepsAsync != null) {
      final routine = routineAsync.value;
      final steps = stepsAsync.value;
      if (routine != null && steps != null) _loadFrom(routine, steps);
      if ((routineAsync.isLoading || stepsAsync.isLoading) && !_loaded) {
        return Scaffold(
          appBar: AppBar(
            leading: SoftBackButton.asAppBarLeading(),
            leadingWidth: SoftBackButton.appBarLeadingWidth,
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (routineAsync.hasError || stepsAsync.hasError) {
        return Scaffold(
          appBar: AppBar(
            leading: SoftBackButton.asAppBarLeading(),
            leadingWidth: SoftBackButton.appBarLeadingWidth,
          ),
          body: Center(child: Text(l10n.commonLoadError)),
        );
      }
      if (!routineAsync.isLoading && routine == null) {
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

    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: SoftBackButton.asAppBarLeading(),
          leadingWidth: SoftBackButton.appBarLeadingWidth,
          title: Text(
            _isEditing
                ? l10n.routineFormEditTitle
                : l10n.routineFormCreateTitle,
          ),
        ),
        // The button is the point of the screen, so it sits under the content
        // at full width rather than hiding as a checkmark in the bar.
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FormSaveButton(
            key: const Key('routine-form-save'),
            label: _saveLabel(l10n),
            saving: _saving,
            onPressed: _saving || _steps.isEmpty ? null : _save,
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(
                  fontFamily: AppTypography.display,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: ink.ink,
                ),
                decoration: InputDecoration(
                  hintText: l10n.routineFormNameHint,
                  hintStyle: TextStyle(
                    fontFamily: AppTypography.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: ink.muted(0.4),
                  ),
                  // Nothing but a rule under it: the name is the title of the
                  // screen once it is filled in, not a field among fields.
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 10),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ink.muted(0.18)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ink.accent, width: 2),
                  ),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.routineFormNameRequired
                    : null,
              ),
              const SizedBox(height: 22),
              _ScheduleCard(
                mode: _mode,
                onModeChanged: (mode) => setState(() => _mode = mode),
                startTimeText: _startTimeText(context),
                onEarlier: () => _nudgeStartTime(-15),
                onLater: () => _nudgeStartTime(15),
                onPickTime: _pickStartTime,
                startTimeError: _startTimeError,
                days: _days,
                dayLabel: (day) => _dayLabel(l10n, day),
                dayName: (day) => _dayName(l10n, day),
                onDayToggled: (day, selected) => setState(() {
                  selected ? _days.add(day) : _days.remove(day);
                  if (_days.isNotEmpty) _daysError = null;
                }),
                daysError: _daysError,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      l10n.routineDetailSteps,
                      style: const TextStyle(
                        fontFamily: AppTypography.display,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openStep,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.routineDetailAddStep),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_steps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    l10n.routineFormStepsEmpty,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                StepListShell(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) =>
                        Material(type: MaterialType.transparency, child: child),
                    onReorder: _reorder,
                    children: [
                      for (final (index, step) in _steps.indexed)
                        StepRow(
                          key: ValueKey(step.id),
                          step: step,
                          onTap: () => _openStep(index),
                          isLast: index == _steps.length - 1,
                          handle: _steps.length < 2
                              ? null
                              : ReorderableDragStartListener(
                                  index: index,
                                  child: Tooltip(
                                    message: l10n.routineDetailReorderHandle,
                                    child: const SizedBox.square(
                                      dimension: 48,
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  ),
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

  /// Follows the phone's 12/24-hour setting, matching `_StartTime` on the
  /// routines list — the stored "HH:MM" is display-only here; the field
  /// itself never changes format.
  String _startTimeText(BuildContext context) {
    final time = _parseStartTime(_startTime);
    if (time == null) {
      return AppLocalizations.of(context)!.routineFormStartTimeUnset;
    }
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  String _dayName(AppLocalizations l10n, DayOfWeek day) {
    return switch (day) {
      DayOfWeek.mon => l10n.dayMon,
      DayOfWeek.tue => l10n.dayTue,
      DayOfWeek.wed => l10n.dayWed,
      DayOfWeek.thu => l10n.dayThu,
      DayOfWeek.fri => l10n.dayFri,
      DayOfWeek.sat => l10n.daySat,
      DayOfWeek.sun => l10n.daySun,
    };
  }

  String _dayLabel(AppLocalizations l10n, DayOfWeek day) {
    return switch (day) {
      DayOfWeek.mon => l10n.dayMonShort,
      DayOfWeek.tue => l10n.dayTueShort,
      DayOfWeek.wed => l10n.dayWedShort,
      DayOfWeek.thu => l10n.dayThuShort,
      DayOfWeek.fri => l10n.dayFriShort,
      DayOfWeek.sat => l10n.daySatShort,
      DayOfWeek.sun => l10n.daySunShort,
    };
  }
}

/// The schedule, its start time and its days, grouped on one card.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.mode,
    required this.onModeChanged,
    required this.startTimeText,
    required this.onEarlier,
    required this.onLater,
    required this.onPickTime,
    required this.startTimeError,
    required this.days,
    required this.dayLabel,
    required this.dayName,
    required this.onDayToggled,
    required this.daysError,
  });

  final ScheduleMode mode;
  final ValueChanged<ScheduleMode> onModeChanged;
  final String startTimeText;
  final VoidCallback onEarlier;
  final VoidCallback onLater;
  final VoidCallback onPickTime;
  final String? startTimeError;
  final Set<DayOfWeek> days;
  final String Function(DayOfWeek) dayLabel;
  final String Function(DayOfWeek) dayName;
  final void Function(DayOfWeek day, bool selected) onDayToggled;
  final String? daysError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);

    return Material(
      color: ink.card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: ink.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: l10n.routineFormAtASetTime,
                    selected: mode == ScheduleMode.scheduled,
                    onTap: () => onModeChanged(ScheduleMode.scheduled),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeTab(
                    label: l10n.routinesTabFlexible,
                    selected: mode == ScheduleMode.flexible,
                    onTap: () => onModeChanged(ScheduleMode.flexible),
                  ),
                ),
              ],
            ),
            if (mode == ScheduleMode.scheduled) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.routineFormStartsAt,
                      style: HomeInk.detail.copyWith(
                        fontSize: 14,
                        color: ink.muted(0.7),
                      ),
                    ),
                  ),
                  _Stepper(
                    icon: Icons.remove,
                    tooltip: l10n.routineFormEarlier,
                    onPressed: onEarlier,
                  ),
                  // The time is a button of its own: the steppers nudge, this
                  // jumps.
                  InkWell(
                    key: const Key('startTime'),
                    onTap: onPickTime,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        startTimeText,
                        style: TextStyle(
                          fontFamily: AppTypography.display,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: ink.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  _Stepper(
                    icon: Icons.add,
                    tooltip: l10n.routineFormLater,
                    onPressed: onLater,
                  ),
                ],
              ),
              if (startTimeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    startTimeError!,
                    style: HomeInk.detail.copyWith(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            Text(
              l10n.routineFormRepeat.toUpperCase(),
              style: HomeInk.label.copyWith(
                fontSize: 11,
                letterSpacing: 0.9,
                color: ink.muted(0.5),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final day in DayOfWeek.values) ...[
                  if (day != DayOfWeek.values.first) const SizedBox(width: 6),
                  Expanded(
                    child: _DayToggle(
                      key: Key('day-${day.name}'),
                      label: dayLabel(day),
                      name: dayName(day),
                      selected: days.contains(day),
                      onTap: () => onDayToggled(day, !days.contains(day)),
                    ),
                  ),
                ],
              ],
            ),
            if (daysError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  daysError!,
                  style: HomeInk.detail.copyWith(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One half of the scheduled/flexible pair.
class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? ink.accent : ink.muted(0.06),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: HomeInk.label.copyWith(
                    fontSize: 13,
                    color: selected ? ink.onAction : ink.muted(0.7),
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

/// One day of the week, on or off.
class _DayToggle extends StatelessWidget {
  const _DayToggle({
    super.key,
    required this.label,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// The day's full name, so a screen reader says "Monday" rather than "M".
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Material(
        color: selected ? ink.accent : ink.muted(0.06),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                label,
                style: HomeInk.label.copyWith(
                  fontSize: 13,
                  color: selected ? ink.onAction : ink.muted(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round nudge button beside the start time.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: ink.muted(0.6)),
        ),
      ),
    );
  }
}

typedef _Snapshot = ({
  String name,
  ScheduleMode mode,
  Set<DayOfWeek> days,
  String? startTime,
  List<RoutineStep> steps,
});
