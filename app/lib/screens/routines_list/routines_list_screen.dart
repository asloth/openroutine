import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/routine.dart';
import '../../models/schedule.dart';
import '../../models/trigger.dart';
import '../../state/routines_provider.dart';

/// docs/SPEC.md §7 screen 2: tabs Scheduled/Flexible, sections by trigger,
/// FAB for new routine, overflow menu with Import/Settings.
class RoutinesListScreen extends ConsumerWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final routinesAsync = ref.watch(routinesProvider);
    final triggersAsync = ref.watch(triggersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.routinesTabScheduled),
              Tab(text: l10n.routinesTabFlexible),
            ],
          ),
          actions: [
            PopupMenuButton<_OverflowAction>(
              onSelected: (action) {
                switch (action) {
                  case _OverflowAction.import:
                    context.push('/import');
                  case _OverflowAction.settings:
                    context.push('/settings');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _OverflowAction.import,
                  child: Text(l10n.routinesMenuImport),
                ),
                PopupMenuItem(
                  value: _OverflowAction.settings,
                  child: Text(l10n.routinesMenuSettings),
                ),
              ],
            ),
          ],
        ),
        body: routinesAsync.when(
          data: (routines) {
            final triggersById = {
              for (final t in triggersAsync.value ?? const <Trigger>[]) t.id: t,
            };
            return TabBarView(
              children: [
                _RoutineSectionList(
                  routines: routines
                      .where((r) => r.schedule.mode == ScheduleMode.scheduled)
                      .toList(),
                  triggersById: triggersById,
                  emptyMessage: l10n.routinesEmptyScheduled,
                ),
                _RoutineSectionList(
                  routines: routines
                      .where((r) => r.schedule.mode == ScheduleMode.flexible)
                      .toList(),
                  triggersById: triggersById,
                  emptyMessage: l10n.routinesEmptyFlexible,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(l10n.routinesLoadError)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/routines/new'),
          tooltip: l10n.routinesNewRoutine,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

enum _OverflowAction { import, settings }

class _RoutineSectionList extends StatelessWidget {
  const _RoutineSectionList({
    required this.routines,
    required this.triggersById,
    required this.emptyMessage,
  });

  final List<Routine> routines;
  final Map<String, Trigger> triggersById;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final byTrigger = <String?, List<Routine>>{};
    for (final routine in routines) {
      byTrigger.putIfAbsent(routine.triggerId, () => []).add(routine);
    }
    final sectionKeys = byTrigger.keys.toList()
      ..sort(
        (a, b) => (triggersById[a]?.name ?? '').compareTo(
          triggersById[b]?.name ?? '',
        ),
      );

    return ListView(
      children: [
        for (final triggerId in sectionKeys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              triggersById[triggerId]?.name ?? l10n.routinesNoTrigger,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final routine in byTrigger[triggerId]!)
            ListTile(
              title: Text(routine.name),
              subtitle: Text(l10n.routinesStepCount(routine.stepIds.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/routines/${routine.id}'),
            ),
        ],
      ],
    );
  }
}
