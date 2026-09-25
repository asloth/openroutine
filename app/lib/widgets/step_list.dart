import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/step.dart';
import '../theme/theme.dart';

/// The bordered, clipped shell every step row renders inside — one container
/// whether there's one step or several, so a divider between rows (owned by
/// each [StepRow]) reads as one continuous list rather than a stack of
/// separate cards.
class StepListShell extends StatelessWidget {
  const StepListShell({super.key, required this.child});

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

/// One step in a [StepListShell]: emoji, name, and duration, with an
/// optional reorder handle.
class StepRow extends StatelessWidget {
  const StepRow({
    super.key,
    required this.step,
    required this.onTap,
    required this.isLast,
    this.handle,
  });

  final RoutineStep step;
  final VoidCallback onTap;

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
              onTap: onTap,
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
