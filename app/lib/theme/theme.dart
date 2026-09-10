import 'package:flutter/material.dart';

import 'colors.dart';
import 'palette.dart';
import 'spacing.dart';
import 'typography.dart';

export 'colors.dart';
export 'neumorphic.dart';
export 'palette.dart';
export 'spacing.dart';
export 'typography.dart';

/// Assembles the app's themes from the tokens in this directory
/// (docs/SPEC.md §7: "Design tokens: define once in `app/lib/theme/`").
///
/// Component themes are configured here rather than in screens so that a stock
/// `FilledButton` or `ListTile` already looks right. Any screen that has to
/// override an appearance locally is a sign a component theme is missing.
abstract final class AppTheme {
  /// Both take the user's chosen background [Palette] and [accent], and fall
  /// back to [Palette.defaultPalette] and [Palette.inkIris] respectively, so
  /// a call site with no opinion still gets a themed app. Both parameters are
  /// nullable rather than defaulted because neither default is a
  /// compile-time constant.
  static ThemeData light([Palette? palette, Palette? accent]) => _build(
    palette ?? Palette.defaultPalette,
    accent ?? Palette.inkIris,
    Brightness.light,
  );

  static ThemeData dark([Palette? palette, Palette? accent]) => _build(
    palette ?? Palette.defaultPalette,
    accent ?? Palette.inkIris,
    Brightness.dark,
  );

  static ThemeData _build(
    Palette palette,
    Palette accent,
    Brightness brightness,
  ) {
    final scheme = Palette.withAccent(
      palette.scheme(brightness),
      accent.scheme(brightness),
    );
    final neumorphic = palette.neumorphic(brightness);
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final routineCardColors = RoutineCardColors(
      fill: scheme.primaryContainer,
      onFill: scheme.onPrimaryContainer,
      upcomingFill: brightness == Brightness.dark
          ? AppColors.upcomingDark
          : AppColors.upcoming,
      onUpcomingFill: brightness == Brightness.dark
          ? AppColors.onUpcomingDark
          : AppColors.onUpcoming,
      timerGround: brightness == Brightness.dark
          ? scheme.surface
          : AppColors.timerGround,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      // The mascot and the routine card's own colors ride along on the theme,
      // the same way the neumorphic pair does, so neither MascotSlot nor a
      // routine card ever has to import a palette to find them.
      extensions: [neumorphic, palette.mascot, routineCardColors],

      // Flat and transparent: the neumorphic cards below supply the depth, and
      // a tinted elevated bar would fight them for attention.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),

      // Prefer NeumorphicCard. This exists so a stock Card still reads as a
      // card: surfaceContainerLowest is a shade lighter than the background,
      // where scheme.surface would make it exactly the same colour as what it
      // sits on and leave it invisible at elevation 0.
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin + 8),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
          ),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSpacing.touchTargetMin),
        ),
      ),

      // Recessed rather than outlined, matching the design pass's wells.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.element,
          vertical: AppSpacing.element,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.element,
          vertical: AppSpacing.base / 2,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurfaceVariant,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.bodyMedium,
        // A selected ChoiceChip fills with primaryContainer, so its label and
        // tick have to flip to the light on-colour. Without these two the tick
        // renders in the secondary green and the label stays near-black, both
        // on blue — legible only just, and not what the design intends.
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        checkmarkColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.element,
          vertical: AppSpacing.base,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card * 2)),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.titleMedium,
        unselectedLabelStyle: textTheme.titleMedium,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outlineVariant,
      ),

      // Tinted paper: a flat, perfectly round FAB with no drop shadow in any
      // state — depth here comes from color contrast, not elevation.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: const CircleBorder(),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: AppSpacing.element,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
    );
  }
}

/// The colors a routine card (and anything that means the same thing) draws
/// from: the accent's container pair, the fixed "coming up soon" pair, and
/// the timer's resting ground.
///
/// Carried as a [ThemeExtension] rather than read straight off
/// `colorScheme.primaryContainer` so a routine card names the one thing it
/// actually depends on — the accent, specifically — instead of assuming a
/// role that a future change to the merge step could quietly detach from it.
@immutable
class RoutineCardColors extends ThemeExtension<RoutineCardColors> {
  const RoutineCardColors({
    required this.fill,
    required this.onFill,
    required this.upcomingFill,
    required this.onUpcomingFill,
    required this.timerGround,
  });

  /// The accent's `primaryContainer` — a routine card's own fill.
  final Color fill;

  /// The accent's `onPrimaryContainer` — text and icons on [fill].
  final Color onFill;

  /// Fixed "a routine is coming up soon" green. Never derived from the
  /// palette or the accent.
  final Color upcomingFill;

  /// Text and icons on [upcomingFill].
  final Color onUpcomingFill;

  /// The timer's resting ground.
  final Color timerGround;

  @override
  RoutineCardColors copyWith({
    Color? fill,
    Color? onFill,
    Color? upcomingFill,
    Color? onUpcomingFill,
    Color? timerGround,
  }) {
    return RoutineCardColors(
      fill: fill ?? this.fill,
      onFill: onFill ?? this.onFill,
      upcomingFill: upcomingFill ?? this.upcomingFill,
      onUpcomingFill: onUpcomingFill ?? this.onUpcomingFill,
      timerGround: timerGround ?? this.timerGround,
    );
  }

  @override
  RoutineCardColors lerp(RoutineCardColors? other, double t) {
    if (other == null) return this;
    return RoutineCardColors(
      fill: Color.lerp(fill, other.fill, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      upcomingFill: Color.lerp(upcomingFill, other.upcomingFill, t)!,
      onUpcomingFill: Color.lerp(onUpcomingFill, other.onUpcomingFill, t)!,
      timerGround: Color.lerp(timerGround, other.timerGround, t)!,
    );
  }
}

/// Convenience accessor so screens read `context.routineCardColors.fill`
/// rather than spelling out the extension lookup every time, matching
/// [NeumorphicContext].
extension RoutineCardColorsContext on BuildContext {
  RoutineCardColors get routineCardColors =>
      Theme.of(this).extension<RoutineCardColors>() ??
      const RoutineCardColors(
        fill: AppColors.primaryContainer,
        onFill: AppColors.onPrimaryContainer,
        upcomingFill: AppColors.upcoming,
        onUpcomingFill: AppColors.onUpcoming,
        timerGround: AppColors.timerGround,
      );
}
