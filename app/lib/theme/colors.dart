import 'package:flutter/material.dart';

/// Colour tokens for OpenRoutine's "warm paper" palette.
///
/// The original tokens came from a Stitch pass ("FocusFlow Routine Timer")
/// built on a corporate blue over a cool blue-grey. That reads competent and
/// cold — the wrong register for an app whose whole job is to lower the
/// activation energy of getting out of bed. This palette keeps the same
/// Material 3 role structure and the same neumorphic idiom, and only changes
/// the temperature: an oat-paper ground, terracotta for actions, moss for
/// progress, honey for accents. Warm, low-arousal, and easy to sit with for
/// the twenty minutes a routine actually takes.
///
/// Every foreground/background pair below is checked against WCAG AA
/// (4.5:1 for body text, 3:1 for large text and UI edges).
///
/// Do not hand-pick colours in screens. If a screen needs a colour that isn't
/// here, the design system is missing a role and this file is where it goes.
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Light — "warm paper"
  // ---------------------------------------------------------------------

  /// Terracotta. Carries every primary action. Warm enough to feel inviting
  /// rather than institutional, dark enough to clear AA on the oat ground.
  static const primary = Color(0xFFA9502F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFF6DCCF);
  static const onPrimaryContainer = Color(0xFF4E1F0E);

  /// Moss. The timer ring's green — "in progress", not "success", which is
  /// why the ring wears it while a step is still running.
  static const secondary = Color(0xFF44694F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFD3E8D6);
  static const onSecondaryContainer = Color(0xFF1B3623);

  /// Honey. Accents and the "a little longer" end of the estimate zones.
  static const tertiary = Color(0xFF8A5A18);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFF7E4BF);
  static const onTertiaryContainer = Color(0xFF432B06);

  /// Warmed slightly off Material's default red so it belongs to the same
  /// family. Errors here are things like a failed import, never a missed
  /// routine — nothing in this app should scold.
  static const error = Color(0xFFB3261E);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFF9DEDC);
  static const onErrorContainer = Color(0xFF5F1412);

  static const surface = Color(0xFFF6F1E9);
  static const onSurface = Color(0xFF2E2822);
  static const onSurfaceVariant = Color(0xFF574E44);
  static const surfaceContainerLowest = Color(0xFFFFFCF6);
  static const surfaceContainerLow = Color(0xFFF2EBE1);
  static const surfaceContainer = Color(0xFFEDE5D9);
  static const surfaceContainerHigh = Color(0xFFE7DED0);
  static const surfaceContainerHighest = Color(0xFFE1D6C6);
  static const surfaceDim = Color(0xFFDCCFBD);
  static const surfaceBright = Color(0xFFFFFCF6);

  static const outline = Color(0xFF7C7063);
  static const outlineVariant = Color(0xFFD5C9B9);

  static const inverseSurface = Color(0xFF3A332C);
  static const inverseOnSurface = Color(0xFFF4EEE6);
  static const inversePrimary = Color(0xFFFFB59A);

  /// The two halves of every neumorphic shadow: a warm sand where light falls
  /// away and a near-white cream where it catches. They only read as depth
  /// against a surface sitting between them, which is exactly what [surface]
  /// is. Both are tinted rather than neutral grey — a grey shadow on a warm
  /// ground is what makes most neumorphism look like moulded plastic.
  static const neumorphicShadow = Color(0xFFDFD3C3);
  static const neumorphicHighlight = Color(0xFFFFFDF8);

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

  // ---------------------------------------------------------------------
  // Dark — "warm night"
  // ---------------------------------------------------------------------

  /// Hand-built rather than `ColorScheme.fromSeed`, which is what this used to
  /// be. A seeded dark scheme lands on a blue-black ground and undoes the whole
  /// point of the palette; evening routines are the ones most likely to run in
  /// dark mode, so this is the scheme that most needs to feel cozy. Warm ink
  /// ground, lifted terracotta and moss so both clear AA against it.
  static const darkPrimary = Color(0xFFF0A484);
  static const darkSecondary = Color(0xFF9CC5A2);
  static const darkTertiary = Color(0xFFE7BE7C);
  static const darkSurface = Color(0xFF1C1815);
  static const darkOnSurface = Color(0xFFEDE4D9);

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: Color(0xFF4A1C08),
    primaryContainer: Color(0xFF6B3016),
    onPrimaryContainer: Color(0xFFFFDBCC),
    secondary: darkSecondary,
    onSecondary: Color(0xFF12301B),
    secondaryContainer: Color(0xFF2C4A34),
    onSecondaryContainer: Color(0xFFD3E8D6),
    tertiary: darkTertiary,
    onTertiary: Color(0xFF412A05),
    tertiaryContainer: Color(0xFF5D3F0D),
    onTertiaryContainer: Color(0xFFF7E4BF),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: darkSurface,
    onSurface: darkOnSurface,
    onSurfaceVariant: Color(0xFFCFC2B4),
    surfaceContainerLowest: Color(0xFF14100E),
    surfaceContainerLow: Color(0xFF241F1B),
    surfaceContainer: Color(0xFF29231F),
    surfaceContainerHigh: Color(0xFF342D28),
    surfaceContainerHighest: Color(0xFF3F3833),
    surfaceDim: Color(0xFF1C1815),
    surfaceBright: Color(0xFF423A34),
    outline: Color(0xFF998C7E),
    outlineVariant: Color(0xFF4D453D),
    inverseSurface: Color(0xFFEDE4D9),
    onInverseSurface: Color(0xFF332C26),
    inversePrimary: primary,
  );

  /// Dark-mode counterparts of the neumorphic pair: a warm near-black for the
  /// shadow and a lifted brown-grey for the highlight, since a white highlight
  /// would blow out.
  static const neumorphicShadowDark = Color(0xFF100D0B);
  static const neumorphicHighlightDark = Color(0xFF2E2823);

  // ---------------------------------------------------------------------
  // The mascot's own palette
  // ---------------------------------------------------------------------

  /// The pet keeps these colours in **both** themes. It is a creature, not a
  /// UI surface: a pet that recolours with the system theme reads as two
  /// different pets, and the app's own container roles are the wrong tool
  /// anyway — `primaryContainer` is pale enough to vanish on the light paper
  /// ground and dark enough to sink into the night one.
  ///
  /// Clay body against oat paper (2.4:1) and against warm ink (6.6:1), so it
  /// reads in both without ever shouting.
  static const mascotBody = Color(0xFFD08F66);

  /// Always the warm dark ink, never `onSurface`: the eyes and mouth sit on
  /// the pet's body, so they have to contrast with *that*, not with whatever
  /// the app is painted on behind it (5.4:1 on [mascotBody]).
  static const mascotInk = Color(0xFF3A2A1E);

  /// Cheeks. Deeper than the body so it reads at low alpha.
  static const mascotBlush = Color(0xFFB4553A);

  // ---------------------------------------------------------------------
  // Fixed tokens — outside every palette and every accent
  // ---------------------------------------------------------------------

  /// "A routine is coming up soon." Fixed across every background palette and
  /// every accent, in both themes: green already carries this one meaning
  /// everywhere else in the app, so it can't also be something a palette or
  /// accent choice recolors out from under it.
  static const upcoming = Color(0xFFD3E8D6);
  static const onUpcoming = Color(0xFF1B3623);
  static const upcomingDark = Color(0xFF2C4A34);
  static const onUpcomingDark = Color(0xFFD3E8D6);

  /// The timer's resting ground in light mode. Dark mode reads the scheme's
  /// own `surface` instead — there's no separate dark literal here.
  static const timerGround = Color(0xFFEBEAE8);
}
