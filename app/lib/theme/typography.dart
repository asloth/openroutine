import 'package:flutter/material.dart';

/// Type tokens from the Stitch design pass, mapped onto Material 3's text
/// roles so that stock widgets pick them up without per-screen overrides.
///
/// Two families, with a clear division of labour: **Lexend** carries anything
/// structural or actionable — headings, numbers, button labels — and **Inter**
/// carries prose. Both are bundled (see pubspec.yaml) rather than fetched at
/// runtime, so typography works offline like the rest of the app.
abstract final class AppTypography {
  static const display = 'Lexend';
  static const body = 'Inter';

  /// The timer's countdown and other hero numbers. Tight tracking keeps a
  /// four-digit clock from sprawling.
  static const _displayLarge = TextStyle(
    fontFamily: display,
    fontSize: 40,
    height: 1.2,
    letterSpacing: -0.8, // -0.02em at 40px
    fontWeight: FontWeight.w600,
  );

  static const _headlineLarge = TextStyle(
    fontFamily: display,
    fontSize: 32,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  /// The mobile headline from the design pass — screen titles on a phone.
  static const _headlineSmall = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Small, spaced, uppercase-ish labels: section headers, stat captions.
  static const _labelCaps = TextStyle(
    fontFamily: display,
    fontSize: 14,
    height: 1,
    letterSpacing: 0.7, // 0.05em at 14px
    fontWeight: FontWeight.w600,
  );

  /// Button and other action text.
  static const _action = TextStyle(
    fontFamily: display,
    fontSize: 18,
    height: 1,
    fontWeight: FontWeight.w500,
  );

  static const _bodyLarge = TextStyle(
    fontFamily: body,
    fontSize: 20,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  static const _bodyMedium = TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  static const _bodySmall = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Roles the design pass didn't name are interpolated from the ones it did,
  /// rather than left at Material's Roboto defaults — a single unstyled widget
  /// is enough to break the typographic voice.
  static const textTheme = TextTheme(
    displayLarge: _displayLarge,
    displayMedium: _displayLarge,
    displaySmall: _headlineLarge,
    headlineLarge: _headlineLarge,
    headlineMedium: _headlineSmall,
    headlineSmall: _headlineSmall,
    titleLarge: TextStyle(
      fontFamily: display,
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: display,
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: _labelCaps,
    bodyLarge: _bodyLarge,
    bodyMedium: _bodyMedium,
    bodySmall: _bodySmall,
    labelLarge: _action,
    labelMedium: _labelCaps,
    labelSmall: TextStyle(
      fontFamily: display,
      fontSize: 12,
      height: 1,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w600,
    ),
  );

  /// Monospaced digits for anything that ticks. Without this the countdown
  /// jitters horizontally every time a glyph changes width.
  static const tabularFigures = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
