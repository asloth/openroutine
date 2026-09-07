import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/app_prefs_provider.dart';
import '../theme/theme.dart';

/// Localised display name for a palette. Lives here rather than on [Palette]
/// so the palette stays a pure colour value with no dependency on l10n.
String paletteName(AppLocalizations l10n, Palette palette) => switch (palette.id) {
  'warm_paper' => l10n.themeWarmPaper,
  'ink_iris' => l10n.themeInkIris,
  'sea_glass' => l10n.themeSeaGlass,
  'plum' => l10n.themePlum,
  'slate' => l10n.themeSlate,
  'moss' => l10n.themeMoss,
  _ => l10n.themeCustom,
};

/// The row of palette swatches for Settings › Appearance.
///
/// Tapping applies immediately and permanently — there is no Apply button and
/// no confirmation. Colour is reversible by definition: the cost of picking
/// the wrong one is one more tap, which is far less than the cost of a
/// confirm step on every single try.
class PalettePicker extends ConsumerWidget {
  const PalettePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selected = ref.watch(paletteSettingProvider);
    final notifier = ref.read(paletteSettingProvider.notifier);
    // Swatches preview the brightness you are actually looking at. Showing a
    // palette's light surface while the app is in dark mode would advertise a
    // theme you would not get by tapping it.
    final brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                _Swatch(
                  label: paletteName(l10n, palette),
                  selected: selected.id == palette.id,
                  surface: palette.scheme(brightness).surface,
                  accent: palette.scheme(brightness).primary,
                  border: palette.scheme(brightness).outlineVariant,
                  onTap: () => notifier.setPalette(palette),
                ),
              _Swatch(
                label: l10n.themeCustom,
                selected: selected.isCustom,
                // A sweep of the whole wheel: the one swatch that cannot show
                // a single colour, because its promise is all of them.
                gradient: SweepGradient(
                  colors: [
                    for (var hue = 0; hue <= 360; hue += 30)
                      HSLColor.fromAHSL(1, hue % 360, 0.6, 0.55).toColor(),
                  ],
                ),
                surface: selected.isCustom
                    ? selected.scheme(brightness).surface
                    : theme.colorScheme.surface,
                accent: theme.colorScheme.primary,
                border: theme.colorScheme.outlineVariant,
                onTap: () => _openCustomSheet(context, ref),
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

  Future<void> _openCustomSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _CustomHueSheet(),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.selected,
    required this.surface,
    required this.accent,
    required this.border,
    required this.onTap,
    this.gradient,
  });

  final String label;
  final bool selected;
  final Color surface;
  final Color accent;
  final Color border;
  final VoidCallback onTap;
  final Gradient? gradient;

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
              // The ring reads in the *current* theme, not the swatch's own —
              // it says "this is the one you are looking at", so it has to
              // belong to the UI around it.
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surface,
                border: Border.all(
                  color: selected ? scheme.primary : border,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Center(
                child: SizedBox.square(
                  dimension: _size * 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gradient == null ? accent : null,
                      gradient: gradient,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: _size * 0.3,
                            // Against the swatch's own accent, not the app's.
                            color: gradient == null
                                ? _readableOn(accent)
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The tick sits on an arbitrary palette's accent, so which of black or
  /// white is legible cannot be assumed — it is measured, same as everywhere
  /// else in the palette code.
  static Color _readableOn(Color background) =>
      contrastRatio(Colors.white, background) >=
          contrastRatio(Colors.black, background)
      ? Colors.white
      : Colors.black;
}

/// Hue slider for a generated palette.
///
/// Dragging repaints the whole app live behind the sheet, which is the actual
/// preview — so the sheet stays small and does not try to mock up a screen of
/// its own. `onChanged` only previews; the write to disk happens once on
/// `onChangeEnd`, so a drag across the wheel is one write rather than sixty.
class _CustomHueSheet extends ConsumerStatefulWidget {
  const _CustomHueSheet();

  @override
  ConsumerState<_CustomHueSheet> createState() => _CustomHueSheetState();
}

class _CustomHueSheetState extends ConsumerState<_CustomHueSheet> {
  double? _hue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final current = ref.watch(paletteSettingProvider);
    final hue = _hue ?? current.seedHue;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.container,
          0,
          AppSpacing.container,
          AppSpacing.container,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.themeCustomTitle, style: theme.textTheme.titleLarge),
            AppSpacing.gapContainer,
            Text(
              l10n.themeCustomHue,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapBase,
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillBorder,
                    gradient: LinearGradient(
                      colors: [
                        for (var h = 0; h <= 360; h += 30)
                          HSLColor.fromAHSL(1, h % 360, 0.6, 0.55).toColor(),
                      ],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // The rainbow behind the thumb *is* the track, so the
                    // stock one is hidden rather than drawn on top of it.
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    trackHeight: 12,
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                  ),
                  child: Slider(
                    value: hue,
                    min: 0,
                    max: 359,
                    label: '${hue.round()}°',
                    semanticFormatterCallback: (value) => '${value.round()}°',
                    onChanged: (value) {
                      setState(() => _hue = value);
                      ref
                          .read(paletteSettingProvider.notifier)
                          .preview(_paletteFor(value));
                    },
                    onChangeEnd: (value) => ref
                        .read(paletteSettingProvider.notifier)
                        .setPalette(_paletteFor(value)),
                  ),
                ),
              ],
            ),
            AppSpacing.gapContainer,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonDone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Palette _paletteFor(double hue) =>
      Palette.fromSeed(id: Palette.customId, hue: hue);
}
