import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/step.dart';
import '../../models/trigger.dart';
import '../../state/import_export_provider.dart';
import '../../state/routines_provider.dart';
import '../../state/storage_provider.dart';
import '../../state/timer_provider.dart';

/// docs/SPEC.md §7 screen 3. The last-7-day dots read the CompletionLogs that
/// Timer Mode writes (M3); a routine that has never been run still falls back
/// to the "no history yet" text rather than a row of empty dots, which would
/// read as seven missed days.
class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            return Center(child: Text(l10n.routinesLoadError));
          }
          final trigger = triggersAsync.value
              ?.where((t) => t.id == routine.triggerId)
              .cast<Trigger?>()
              .firstOrNull;
          final steps = stepsAsync.value ?? const <RoutineStep>[];

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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
              ),
              const SizedBox(height: 24),
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
              else
                for (final step in steps)
                  ListTile(
                    leading: Text(
                      step.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(step.name),
                    subtitle: Text(
                      step.noExplicitTime
                          ? l10n.routineDetailNoExplicitTime
                          : l10n.stepDurationMinutes(
                              ((step.durationSeconds ?? 0) / 60).ceil(),
                            ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/routines/$routineId/steps/${step.id}/edit',
                    ),
                  ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.routinesLoadError)),
      ),
    );
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
                      ? l10n.routineDetailHistoryCompleted
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
