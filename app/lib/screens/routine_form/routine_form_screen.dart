import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/trigger.dart';
import '../../services/id_generator.dart';
import '../../services/storage/storage_adapter.dart';
import '../../state/routines_provider.dart';
import '../../state/storage_provider.dart';

/// docs/SPEC.md §7 screen 4. Only routine-level fields — steps are added
/// afterward from Routine Detail, since this screen's field list (name,
/// trigger, days, mode, start time) never mentions steps.
class RoutineFormScreen extends ConsumerStatefulWidget {
  const RoutineFormScreen({super.key, this.routineId});

  /// Null means create; non-null means edit that routine.
  final String? routineId;

  @override
  ConsumerState<RoutineFormScreen> createState() => _RoutineFormScreenState();
}

class _RoutineFormScreenState extends ConsumerState<RoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _triggerId;
  ScheduleMode _mode = ScheduleMode.flexible;
  final Set<DayOfWeek> _days = {};
  String? _startTime;
  bool _loaded = false;
  bool _saving = false;

  bool get _isEditing => widget.routineId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadFrom(Routine routine) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = routine.name;
    _triggerId = routine.triggerId;
    _mode = routine.schedule.mode;
    _days
      ..clear()
      ..addAll(routine.schedule.days);
    _startTime = routine.schedule.startTime;
  }

  Future<void> _addTrigger(StorageAdapter storage) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.routineFormNewTriggerTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.routineFormTriggerName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final now = nowUtc();
    final trigger = Trigger(
      id: newId(),
      name: name,
      kind: TriggerKind.manual,
      createdAt: now,
      updatedAt: now,
    );
    await storage.saveTrigger(trigger);
    ref.invalidate(triggersProvider);
    setState(() => _triggerId = trigger.id);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      _startTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final storage = ref.read(storageAdapterProvider);
    final now = nowUtc();
    final schedule = Schedule(
      mode: _mode,
      days: _mode == ScheduleMode.scheduled ? _days.toList() : const [],
      startTime: _mode == ScheduleMode.scheduled ? _startTime : null,
    );

    if (_isEditing) {
      final existing = await ref.read(
        routineProvider(widget.routineId!).future,
      );
      final updated = existing!.copyWith(
        name: _nameController.text.trim(),
        triggerId: _triggerId,
        schedule: schedule,
        updatedAt: now,
      );
      await storage.saveRoutine(updated);
      ref.invalidate(routineProvider(widget.routineId!));
    } else {
      final routine = Routine(
        id: newId(),
        name: _nameController.text.trim(),
        triggerId: _triggerId,
        schedule: schedule,
        stepIds: const [],
        createdAt: now,
        updatedAt: now,
      );
      await storage.saveRoutine(routine);
    }
    ref.invalidate(routinesProvider);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = ref.watch(storageAdapterProvider);
    final triggersAsync = ref.watch(triggersProvider);

    final routineAsync = _isEditing
        ? ref.watch(routineProvider(widget.routineId!))
        : null;
    if (routineAsync != null) {
      final routine = routineAsync.value;
      if (routine != null) _loadFrom(routine);
      if (routineAsync.isLoading && !_loaded) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.routineFormEditTitle : l10n.routineFormCreateTitle,
        ),
        actions: [
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
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.routineFormNameLabel),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.routineFormNameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: triggersAsync.when(
                    data: (triggers) => DropdownButtonFormField<String?>(
                      initialValue: _triggerId,
                      decoration: InputDecoration(
                        labelText: l10n.routineFormTriggerLabel,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(l10n.routinesNoTrigger),
                        ),
                        for (final trigger in triggers)
                          DropdownMenuItem(
                            value: trigger.id,
                            child: Text(trigger.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _triggerId = value),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => Text(l10n.routinesLoadError),
                  ),
                ),
                IconButton(
                  onPressed: () => _addTrigger(storage),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.routineFormNewTriggerTitle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<ScheduleMode>(
              segments: [
                ButtonSegment(
                  value: ScheduleMode.scheduled,
                  label: Text(l10n.routinesTabScheduled),
                ),
                ButtonSegment(
                  value: ScheduleMode.flexible,
                  label: Text(l10n.routinesTabFlexible),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            if (_mode == ScheduleMode.scheduled) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final day in DayOfWeek.values)
                    FilterChip(
                      label: Text(_dayLabel(l10n, day)),
                      selected: _days.contains(day),
                      onSelected: (selected) => setState(
                        () => selected ? _days.add(day) : _days.remove(day),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.routineFormStartTimeLabel),
                subtitle: Text(_startTime ?? l10n.routineFormStartTimeUnset),
                trailing: const Icon(Icons.access_time),
                onTap: _pickStartTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dayLabel(AppLocalizations l10n, DayOfWeek day) {
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
}
