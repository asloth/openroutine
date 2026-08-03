import 'package:flutter/material.dart';

import 'colors.dart';
import 'neumorphic.dart';
import 'spacing.dart';
import 'typography.dart';

export 'colors.dart';
export 'neumorphic.dart';
export 'spacing.dart';
export 'typography.dart';

/// Assembles the app's themes from the tokens in this directory
/// (docs/SPEC.md §7: "Design tokens: define once in `app/lib/theme/`").
///
/// Component themes are configured here rather than in screens so that a stock
/// `FilledButton` or `ListTile` already looks right. Any screen that has to
/// override an appearance locally is a sign a component theme is missing.
abstract final class AppTheme {
  static ThemeData get light => _build(
    AppColors.light,
    NeumorphicTheme.light,
    Brightness.light,
  );

  static ThemeData get dark => _build(
    AppColors.dark,
    NeumorphicTheme.dark,
    Brightness.dark,
  );

  static ThemeData _build(
    ColorScheme scheme,
    NeumorphicTheme neumorphic,
    Brightness brightness,
  ) {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [neumorphic],

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

      // Material's default Card is elevation + surface tint, which reads as a
      // different material from the neumorphic surfaces. Stripped back so the
      // rare stock Card doesn't stand out; prefer NeumorphicCard.
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
        ),
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
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
        ),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        iconColor: scheme.onSurfaceVariant,
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
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pillBorder,
        ),
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

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card * 1.5)),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.secondary,
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
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
        ),
      ),
    );
  }
}
