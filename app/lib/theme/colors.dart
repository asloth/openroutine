import 'package:flutter/material.dart';

/// Colour tokens, taken verbatim from the Stitch design pass
/// ("FocusFlow Routine Timer", project 11924329853255747415) that docs/SPEC.md
/// §7 anticipated. Stitch exports a full Material 3 role set, so these map onto
/// Flutter's [ColorScheme] one-to-one rather than being approximated from a
/// seed — which is why this is a literal scheme and not `fromSeed`.
///
/// Do not hand-pick colours in screens. If a screen needs a colour that isn't
/// here, the design system is missing a role and this file is where it goes.
abstract final class AppColors {
  static const primary = Color(0xFF0051C0);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2D6ADE);
  static const onPrimaryContainer = Color(0xFFF4F4FF);

  /// The timer ring's green. Reads as "in progress" rather than "success",
  /// which is why the ring uses it while a step is still running.
  static const secondary = Color(0xFF006C47);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF7EFABC);
  static const onSecondaryContainer = Color(0xFF00734B);

  static const tertiary = Color(0xFF854800);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFA85D00);
  static const onTertiaryContainer = Color(0xFFFFF3EB);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const surface = Color(0xFFF7F9FC);
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF424654);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F7);
  static const surfaceContainer = Color(0xFFECEEF1);
  static const surfaceContainerHigh = Color(0xFFE6E8EB);
  static const surfaceContainerHighest = Color(0xFFE0E3E6);
  static const surfaceDim = Color(0xFFD8DADD);
  static const surfaceBright = Color(0xFFF7F9FC);

  static const outline = Color(0xFF737785);
  static const outlineVariant = Color(0xFFC3C6D6);

  static const inverseSurface = Color(0xFF2D3133);
  static const inverseOnSurface = Color(0xFFEFF1F4);
  static const inversePrimary = Color(0xFFB1C5FF);

  /// The two halves of every neumorphic shadow: a cool grey where light falls
  /// away and pure white where it catches. They only read as depth against a
  /// surface sitting between them, which is exactly what [surface] is.
  static const neumorphicShadow = Color(0xFFD1D9E6);
  static const neumorphicHighlight = Color(0xFFFFFFFF);

  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
  );

  /// **Not from Stitch** — the mockups are light-only. Derived from the same
  /// primary so a device in dark mode gets something coherent instead of being
  /// forced into the light theme. Treat it as approximate until there's a dark
  /// design pass; the neumorphic shadows in particular are a light-surface
  /// idiom and only ever suggest depth, never match a designed dark comp.
  static final dark = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
  );

  /// Dark-mode counterparts of the neumorphic pair: a near-black for the
  /// shadow and a lifted grey for the highlight, since white would blow out.
  static const neumorphicShadowDark = Color(0xFF0D0F12);
  static const neumorphicHighlightDark = Color(0xFF2A2F36);
}
