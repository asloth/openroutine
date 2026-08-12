import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/step.dart';
import '../../models/completion_log.dart';
import '../../models/trigger.dart';
import '../../services/storage/storage_adapter.dart';
import '../../state/import_export_provider.dart';
import '../../state/routines_provider.dart';
import '../../state/storage_provider.dart';
import '../../state/timer_provider.dart';
import '../../theme/theme.dart';

/// docs/SPEC.md §7 screen 3. The last-7-day dots read the CompletionLogs that
/// Timer Mode writes (M3); a routine that has never been run still falls back
/// to the "no history yet" text rather than a row of empty dots, which would
/// read as seven missed days.
class RoutineDetailScreen extends ConsumerStatefulWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  List<RoutineStep>? _displaySteps;
  bool _savingOrder = false;

  String get routineId => widget.routineId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routineAsync = ref.watch(routineProvider(routineId));
    final stepsAsync = ref.watch(routineStepsProvider(routineId));
    final triggersAsync = ref.watch(triggersProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.routineDetailShare,
            onPressed: () async {
              final routine = routineAsync.value;
              if (routine == null) return;
              await ref
                  .read(exportServiceProvider)
                  .exportRoutine(routineId, routineName: routine.name);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
            onPressed: () => context.push('/routines/$routineId/edit'),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) async {
              if (action == _MenuAction.delete) {
                final confirmed = await _confirmDelete(context, l10n);
                if (confirmed && context.mounted) {
                  await ref
                      .read(storageAdapterProvider)
                      .deleteRoutine(routineId);
                  ref.invalidate(routinesProvider);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.delete,
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ],
      ),
      body: routineAsync.when(
        data: (routine) {
          if (routine == null) {
            return Center(child: Text(l10n.commonItemUnavailable));
          }
          if (stepsAsync.isLoading && _displaySteps == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (stepsAsync.hasError && _displaySteps == null) {
            return Center(child: Text(l10n.commonLoadError));
          }
          final trigger = triggersAsync.value
              ?.where((t) => t.id == routine.triggerId)
              .cast<Trigger?>()
              .firstOrNull;
          final steps = _displaySteps ?? stepsAsync.requireValue;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                routine.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                trigger?.name ?? l10n.routinesNoTrigger,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.element),
              NeumorphicCard(
                padding: const EdgeInsets.all(AppSpacing.element),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.routineDetailEstimatedFinish,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          _estimatedDuration(l10n, steps),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.routineDetailHistory,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        _HistoryDots(routineId: routineId),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.container),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: steps.isEmpty
                      ? null
                      : () => context.push('/routines/$routineId/timer'),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.routineDetailStartTimer),
                ),
              ),
              if (steps.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.routineDetailNeedsStepsToStart,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.routineDetailSteps,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/routines/$routineId/steps/new'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.routineDetailAddStep),
                  ),
                ],
              ),
              if (steps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(l10n.routineDetailNoSteps),
                )
              else if (steps.length == 1)
                _StepCard(
                  key: ValueKey(steps.single.id),
                  step: steps.single,
                  routineId: routineId,
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) =>
                      Material(type: MaterialType.transparency, child: child),
                  onReorder: _savingOrder ? (_, _) {} : _reorder,
                  children: [
                    for (final (index, step) in steps.indexed)
                      _StepCard(
                        key: ValueKey(step.id),
                        step: step,
                        routineId: routineId,
                        handle: ReorderableDragStartListener(
                          index: index,
                          enabled: !_savingOrder,
                          child: Semantics(
                            label: l10n.routineDetailReorderHandle,
                            button: true,
                            enabled: !_savingOrder,
                            child: Tooltip(
                              message: l10n.routineDetailReorderHandle,
                              child: const SizedBox.square(
                                dimension: 48,
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.routinesLoadError)),
      ),
    );
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final reordered = List<RoutineStep>.of(
      _displaySteps ?? ref.read(routineStepsProvider(routineId)).requireValue,
    );
    if (oldIndex < newIndex) newIndex -= 1;
    reordered.insert(newIndex, reordered.removeAt(oldIndex));

    setState(() {
      _displaySteps = reordered;
      _savingOrder = true;
    });

    try {
      await ref
          .read(storageAdapterProvider)
          .reorderSteps(
            routineId,
            reordered.map((step) => step.id).toList(),
            updatedAt: nowUtc(),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displaySteps = null;
        _savingOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.routineDetailReorderError,
          ),
        ),
      );
      return;
    }

    ref.invalidate(routineStepsProvider(routineId));
    try {
      await ref.read(routineStepsProvider(routineId).future);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingOrder = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _displaySteps = null;
      _savingOrder = false;
    });
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.routineDetailDeleteConfirmTitle),
        content: Text(l10n.routineDetailDeleteConfirmBody),
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
    return result ?? false;
  }

  String _estimatedDuration(AppLocalizations l10n, List<RoutineStep> steps) {
    final totalSeconds = steps
        .where((s) => !s.noExplicitTime)
        .fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0));
    if (totalSeconds == 0) return l10n.routineDetailNoEstimate;
    final minutes = (totalSeconds / 60).ceil();
    return l10n.routineDetailEstimateMinutes(minutes);
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    super.key,
    required this.step,
    required this.routineId,
    this.handle,
  });

  final RoutineStep step;
  final String routineId;
  final Widget? handle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = Row(
      children: [
        Text(step.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: AppSpacing.element),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                step.noExplicitTime
                    ? l10n.routineDetailNoExplicitTime
                    : l10n.stepDurationMinutes(
                        ((step.durationSeconds ?? 0) / 60).ceil(),
                      ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );

    return NeumorphicCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.element),
      padding: handle == null
          ? const EdgeInsets.all(AppSpacing.element)
          : EdgeInsets.zero,
      onTap: handle == null
          ? () => context.push('/routines/$routineId/steps/${step.id}/edit')
          : null,
      child: handle == null
          ? content
          : Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: AppRadius.cardBorder,
                    onTap: () => context.push(
                      '/routines/$routineId/steps/${step.id}/edit',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.element),
                      child: content,
                    ),
                  ),
                ),
                handle!,
              ],
            ),
    );
  }
}

enum _MenuAction { delete }

/// Seven dots, oldest to newest, ending on today. Filled means the routine was
/// completed that day, outlined means it was started but stopped early, and
/// hollow means it wasn't run.
class _HistoryDots extends ConsumerWidget {
  const _HistoryDots({required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final history = ref.watch(routineCompletionsProvider(routineId));
    if (history.hasError) {
      return Text(
        l10n.routineDetailHistoryLoadError,
        style: theme.textTheme.bodyMedium,
      );
    }
    final entries = history.value;

    // Both while loading and before a routine's first run, keep the M2 text
    // rather than showing seven empty dots — that would read as seven days of
    // missed routine rather than "nothing recorded yet".
    if (entries == null || entries.isEmpty) {
      return Text(
        l10n.routineDetailNoHistoryYet,
        style: theme.textTheme.bodyMedium,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var daysAgo = 6; daysAgo >= 0; daysAgo--)
          Builder(
            builder: (context) {
              final day = today.subtract(Duration(days: daysAgo));
              final runs = entries.where((e) => e.localDay == day);
              // A day with any completed run counts as completed, even if the
              // user also abandoned an attempt earlier that day.
              final completed = runs.any((e) => e.completed);
              final attempted = runs.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(right: 4, top: 4),
                child: Tooltip(
                  message: completed
                      ? runs.any((e) => e.mode == RunMode.low)
                            ? l10n.routineDetailHistoryLowModeCompleted
                            : l10n.routineDetailHistoryCompleted
                      : attempted
                      ? l10n.routineDetailHistoryAbandoned
                      : l10n.routineDetailHistoryNothing,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: attempted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
