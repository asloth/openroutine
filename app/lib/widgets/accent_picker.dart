import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/app_prefs_provider.dart';
import '../theme/theme.dart';
import 'palette_picker.dart' show paletteName;

/// Settings › Appearance's second picker: the accent color that tints
/// routine cards and primary actions, chosen independently of the
/// background palette above it.
///
/// Follows [PalettePicker]'s swatch and semantics pattern, with one
/// deliberate omission: there's no custom-hue entry here. The accent only
/// ever names a built-in — see design.md's "Non-Goals".
class AccentPicker extends ConsumerWidget {
  const AccentPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selected = ref.watch(accentSettingProvider);
    final notifier = ref.read(accentSettingProvider.notifier);
    // Swatches always show each palette's *light* primary: the accent is a
    // colour identity, not a brightness-dependent preview like the palette
    // picker's surface swatches are.
    final brightness = Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.element,
            AppSpacing.base,
            AppSpacing.element,
            0,
          ),
          child: Text(
            l10n.settingsAccentTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.element,
            AppSpacing.base / 2,
            AppSpacing.element,
            AppSpacing.base,
          ),
          child: Text(
            l10n.settingsAccentHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.element,
            vertical: AppSpacing.base,
          ),
          child: Wrap(
            spacing: AppSpacing.element,
            runSpacing: AppSpacing.element,
            children: [
              for (final palette in Palette.builtIns)
                _AccentSwatch(
                  label: paletteName(l10n, palette),
                  selected: selected.id == palette.id,
                  accent: palette.scheme(brightness).primary,
                  border: theme.colorScheme.outlineVariant,
                  onTap: () => notifier.setAccent(palette),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.element,
            0,
            AppSpacing.element,
            AppSpacing.element,
          ),
          child: Text(
            l10n.settingsThemeCurrent(paletteName(l10n, selected)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.label,
    required this.selected,
    required this.accent,
    required this.border,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color border;
  final VoidCallback onTap;

  static const _size = AppSpacing.touchTargetMin + 8;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: _size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(
                  color: selected ? scheme.primary : border,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        size: _size * 0.4,
                        color: _readableOn(accent),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// The tick sits on an arbitrary palette's accent colour, same as
  /// [PalettePicker]'s own swatches — measured rather than assumed.
  static Color _readableOn(Color background) =>
      contrastRatio(Colors.white, background) >=
          contrastRatio(Colors.black, background)
      ? Colors.white
      : Colors.black;
}
