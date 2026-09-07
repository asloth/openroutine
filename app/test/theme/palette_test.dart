import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/colors.dart';
import 'package:openroutine/theme/palette.dart';

/// The palette recipe rotates a measured HSL structure around the hue wheel,
/// and hue changes perceived brightness at a fixed lightness — yellow at 42%
/// lightness is far brighter than blue at 42%. So "it looked fine in the one
/// screenshot I took" is not evidence. This asserts the contract everywhere:
/// every built-in palette, and the entire wheel in 10° steps, in both themes.
void main() {
  /// AA: 4.5 for body text, 3.0 for large text and non-text UI edges.
  void expectContrast(
    Color foreground,
    Color background,
    double min,
    String label,
  ) {
    final ratio = contrastRatio(foreground, background);
    expect(
      ratio,
      greaterThanOrEqualTo(min),
      reason:
          '$label is ${ratio.toStringAsFixed(2)}:1, needs $min:1 '
          '(fg #${_hex(foreground)} on bg #${_hex(background)})',
    );
  }

  void checkScheme(ColorScheme s, String label) {
    expectContrast(s.onSurface, s.surface, 4.5, '$label onSurface/surface');
    expectContrast(
      s.onSurfaceVariant,
      s.surface,
      4.5,
      '$label onSurfaceVariant/surface',
    );
    expectContrast(
      s.onSurface,
      s.surfaceContainerLowest,
      4.5,
      '$label onSurface/containerLowest',
    );
    expectContrast(
      s.onSurface,
      s.surfaceContainerHighest,
      4.5,
      '$label onSurface/containerHighest',
    );
    expectContrast(
      s.onSurfaceVariant,
      s.surfaceContainerHighest,
      4.5,
      '$label onSurfaceVariant/containerHighest',
    );
    expectContrast(s.primary, s.surface, 4.5, '$label primary/surface');
    expectContrast(s.onPrimary, s.primary, 4.5, '$label onPrimary/primary');
    // The timer ring: a non-text UI edge, so 3.0 rather than 4.5.
    expectContrast(s.secondary, s.surface, 3, '$label secondary/surface');
    expectContrast(
      s.onSecondary,
      s.secondary,
      4.5,
      '$label onSecondary/secondary',
    );
    expectContrast(s.tertiary, s.surface, 4.5, '$label tertiary/surface');
    expectContrast(s.onTertiary, s.tertiary, 4.5, '$label onTertiary/tertiary');
    expectContrast(
      s.onPrimaryContainer,
      s.primaryContainer,
      4.5,
      '$label onPrimaryContainer/primaryContainer',
    );
    expectContrast(
      s.onSecondaryContainer,
      s.secondaryContainer,
      4.5,
      '$label onSecondaryContainer/secondaryContainer',
    );
    expectContrast(
      s.onTertiaryContainer,
      s.tertiaryContainer,
      4.5,
      '$label onTertiaryContainer/tertiaryContainer',
    );
    expectContrast(
      s.onErrorContainer,
      s.errorContainer,
      4.5,
      '$label onErrorContainer/errorContainer',
    );
    expectContrast(s.outline, s.surface, 3, '$label outline/surface');
    expectContrast(
      s.onInverseSurface,
      s.inverseSurface,
      4.5,
      '$label onInverseSurface/inverseSurface',
    );
  }

  void checkPalette(Palette p, String label) {
    checkScheme(p.light, '$label light');
    checkScheme(p.dark, '$label dark');
    // The pet's own local palette: its ink sits on its body, never on the
    // app's ground. The body only has to hold up against the dark scheme —
    // on the light one it is a soft decorative shape by design.
    expectContrast(p.mascot.ink, p.mascot.body, 4.5, '$label mascot ink/body');
    expectContrast(
      p.mascot.body,
      p.dark.surface,
      3,
      '$label mascot body/dark surface',
    );
  }

  group('built-in palettes', () {
    for (final palette in Palette.builtIns) {
      test('${palette.id} meets AA in both themes', () {
        checkPalette(palette, palette.id);
      });
    }

    test('warm paper is still the untouched hand-tuned scheme', () {
      // It is the palette the app was designed against. If the recipe ever
      // starts generating it, this is what notices.
      expect(Palette.warmPaper.light, same(AppColors.light));
      expect(Palette.warmPaper.dark, same(AppColors.dark));
      expect(Palette.warmPaper.mascot.body, AppColors.mascotBody);
    });

    test('ids are unique and stable', () {
      final ids = Palette.builtIns.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, contains('warm_paper'));
    });
  });

  group('custom palettes', () {
    for (var hue = 0; hue < 360; hue += 10) {
      test('hue $hue° meets AA in both themes', () {
        checkPalette(Palette.fromSeed(id: Palette.customId, hue: hue.toDouble()),
            'hue $hue');
      });
    }
  });

  group('persistence', () {
    test('a custom palette round-trips through its storage id', () {
      final original = Palette.fromSeed(id: Palette.customId, hue: 268);
      final restored = Palette.fromStorageId(original.storageId);
      expect(restored.seedHue, 268);
      expect(restored.light.primary, original.light.primary);
      expect(restored.isCustom, isTrue);
    });

    test('built-ins round-trip', () {
      for (final palette in Palette.builtIns) {
        expect(Palette.fromStorageId(palette.storageId).id, palette.id);
      }
    });

    test('unknown and malformed ids fall back to warm paper', () {
      expect(Palette.fromStorageId(null).id, 'warm_paper');
      expect(Palette.fromStorageId('nope').id, 'warm_paper');
      expect(Palette.fromStorageId('custom:banana').id, 'warm_paper');
    });
  });
}

String _hex(Color c) =>
    ((c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round())
        .toRadixString(16)
        .padLeft(6, '0');
