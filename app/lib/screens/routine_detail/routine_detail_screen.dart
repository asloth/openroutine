import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/tinted/tinted.dart';

/// docs/SPEC.md §7 screen 3. The last-7-day dots read the CompletionLogs that
/// Timer Mode writes (M3); a routine that has never been run still falls back
/// to the "no history yet" text rather than a row of empty dots, which would
/// read as seven missed days.
///
/// Tinted-paper restyle: no `AppBar` — a 48px row of `SoftCircleButton`s plays
/// its part instead, with `SafeArea`/`AnnotatedRegion` picking up the
/// status-bar contrast the `AppBar` used to supply for free.
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
    final theme = Theme.of(context);

    // The AppBar used to set the status-bar icon contrast for free; without
    // one, the screen sets it directly instead.
    final overlayStyle =
        (theme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      SoftCircleButton(
                        icon: Icons.chevron_left,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      SoftCircleButton(
                        icon: Icons.share_outlined,
                        tooltip: l10n.routineDetailShare,
                        onPressed: () async {
                          final routine = routineAsync.value;
                          if (routine == null) return;
                          await ref
                              .read(exportServiceProvider)
                              .exportRoutine(
                                routineId,
                                routineName: routine.name,
                              );
                        },
                      ),
                      const SizedBox(width: 8),
                      SoftCircleButton(
                        icon: Icons.edit_outlined,
                        tooltip: l10n.commonEdit,
                        onPressed: () =>
                            context.push('/routines/$routineId/edit'),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<_MenuAction>(
                        padding: EdgeInsets.zero,
                        onSelected: (action) async {
                          if (action == _MenuAction.delete) {
                            final confirmed = await _confirmDelete(
                              context,
                              l10n,
                            );
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
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            size: 22,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: routineAsync.when(
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
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            routine.name,
                            style: AppTypography.pageTitle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          key: const Key('routineDetailMomentChip'),
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.routineCardColors.fill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            trigger?.name ?? l10n.routinesNoTrigger,
                            style: TextStyle(
                              fontFamily: AppTypography.display,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.routineCardColors.onFill,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TintedCard(
                          color: context.routineCardColors.fill,
                          foregroundColor: context.routineCardColors.onFill,
                          borderRadius: AppRadius.heroBorder,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SummaryLabel(
                                      l10n.routineDetailEstimatedFinish,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _estimatedDuration(l10n, steps),
                                      style: const TextStyle(
                                        fontFamily: AppTypography.display,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SummaryLabel(l10n.routineDetailHistory),
                                    const SizedBox(height: 4),
                                    _HistoryDots(routineId: routineId),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: steps.isEmpty
                                ? null
                                : () => context.push(
                                    '/routines/$routineId/timer',
                                  ),
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
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
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
                              onPressed: () => context.push(
                                '/routines/$routineId/steps/new',
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.routineDetailAddStep),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (steps.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(l10n.routineDetailNoSteps),
                          )
                        else if (steps.length == 1)
                          _StepListShell(
                            child: _StepRow(
                              key: ValueKey(steps.single.id),
                              step: steps.single,
                              routineId: routineId,
                              isLast: true,
                            ),
                          )
                        else
                          _StepListShell(
                            child: ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              proxyDecorator: (child, index, animation) =>
                                  Material(
                                    type: MaterialType.transparency,
                                    child: child,
                                  ),
                              onReorder: _savingOrder ? (_, _) {} : _reorder,
                              children: [
                                for (final (index, step) in steps.indexed)
                                  _StepRow(
                                    key: ValueKey(step.id),
                                    step: step,
                                    routineId: routineId,
                                    isLast: index == steps.length - 1,
                                    handle: ReorderableDragStartListener(
                                      index: index,
                                      enabled: !_savingOrder,
                                      child: Semantics(
                                        label: l10n.routineDetailReorderHandle,
                                        button: true,
                                        enabled: !_savingOrder,
                                        child: Tooltip(
                                          message:
                                              l10n.routineDetailReorderHandle,
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
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text(l10n.routinesLoadError)),
                ),
              ),
            ],
          ),
        ),
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

enum _MenuAction { delete }

/// The uppercase caption over each half of the summary card. Written locally
/// rather than through `SectionLabel` — that widget hard-codes
/// `onSurfaceVariant`, and this caption needs to read the accent's `onFill`
/// at reduced opacity instead.
class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.sectionLabel.copyWith(
        color: context.routineCardColors.onFill.withValues(alpha: 0.8),
      ),
    );
  }
}

/// The bordered, clipped shell every step row renders inside — one container
/// whether there's one step or several, so a divider between rows (owned by
/// each `_StepRow`) reads as one continuous list rather than a stack of
/// separate cards.
class _StepListShell extends StatelessWidget {
  const _StepListShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: AppRadius.heroBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.step,
    required this.routineId,
    required this.isLast,
    this.handle,
  });

  final RoutineStep step;
  final String routineId;

  /// The last row in the shell draws no divider below it.
  final bool isLast;
  final Widget? handle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Row(
      children: [
        Text(step.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: AppSpacing.element),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.name,
                style: const TextStyle(
                  fontFamily: AppTypography.display,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.noExplicitTime
                    ? l10n.routineDetailNoExplicitTime
                    : l10n.stepDurationMinutes(
                        ((step.durationSeconds ?? 0) / 60).ceil(),
                      ),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ],
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: colorScheme.surfaceContainerHigh),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () =>
                  context.push('/routines/$routineId/steps/${step.id}/edit'),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: handle == null ? 16 : 0,
                ),
                child: content,
              ),
            ),
          ),
          ?handle,
        ],
      ),
    );
  }
}

/// Seven dots, oldest to newest, ending on today. Filled means the routine was
/// completed that day, ringed means it was started but stopped early, and a
/// faint ring means it wasn't run. All three read the accent's `onFill`
/// rather than a fixed `colorScheme` role, so the dots stay visually attached
/// to the card they sit inside.
class _HistoryDots extends ConsumerWidget {
  const _HistoryDots({required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final onFill = context.routineCardColors.onFill;
    final history = ref.watch(routineCompletionsProvider(routineId));
    if (history.hasError) {
      return Text(l10n.routineDetailHistoryLoadError);
    }
    final entries = history.value;

    // Both while loading and before a routine's first run, keep the M2 text
    // rather than showing seven empty dots — that would read as seven days of
    // missed routine rather than "nothing recorded yet".
    if (entries == null || entries.isEmpty) {
      return Text(l10n.routineDetailNoHistoryYet);
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
                padding: EdgeInsets.only(right: daysAgo > 0 ? 7 : 0),
                child: Tooltip(
                  message: completed
                      ? runs.any((e) => e.mode == RunMode.low)
                            ? l10n.routineDetailHistoryLowModeCompleted
                            : l10n.routineDetailHistoryCompleted
                      : attempted
                      ? l10n.routineDetailHistoryAbandoned
                      : l10n.routineDetailHistoryNothing,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? onFill : Colors.transparent,
                      border: completed
                          ? null
                          : Border.all(
                              color: attempted
                                  ? onFill
                                  : onFill.withValues(alpha: 0.3),
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
