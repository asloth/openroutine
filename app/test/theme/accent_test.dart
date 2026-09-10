import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/palette.dart';

/// `Palette.withAccent` merges an accent's identity into a background
/// palette's scheme. The accent's own `primary` clears 4.5:1 against *its
/// own* surface (palette_test.dart's contract) — that says nothing about
/// whether it clears against a *different* palette's surface, so this checks
/// every background × every accent, not just each palette against itself.
void main() {
  group('withAccent', () {
    for (final base in Palette.builtIns) {
      for (final accent in Palette.builtIns) {
        for (final brightness in Brightness.values) {
          test('${base.id} background with ${accent.id} accent meets AA '
              '(${brightness.name})', () {
            final baseScheme = base.scheme(brightness);
            final accentScheme = accent.scheme(brightness);
            final merged = Palette.withAccent(baseScheme, accentScheme);

            final primaryRatio = _contrast(merged.primary, baseScheme.surface);
            expect(
              primaryRatio,
              greaterThanOrEqualTo(4.5),
              reason:
                  'accented primary is ${primaryRatio.toStringAsFixed(2)}:1 '
                  'on ${base.id} surface, needs 4.5:1',
            );

            final onContainerRatio = _contrast(
              merged.onPrimaryContainer,
              merged.primaryContainer,
            );
            expect(
              onContainerRatio,
              greaterThanOrEqualTo(4.5),
              reason:
                  'onPrimaryContainer is '
                  '${onContainerRatio.toStringAsFixed(2)}:1 on '
                  'primaryContainer, needs 4.5:1',
            );
          });
        }
      }
    }

    test('leaves every non-primary role from the base scheme untouched', () {
      final base = Palette.seaGlass.light;
      final accent = Palette.plum.light;
      final merged = Palette.withAccent(base, accent);

      expect(merged.surface, base.surface);
      expect(merged.surfaceTint, base.surfaceTint);
      expect(merged.secondary, base.secondary);
      expect(merged.secondaryContainer, base.secondaryContainer);
      expect(merged.tertiary, base.tertiary);
      expect(merged.outline, base.outline);
      expect(merged.error, base.error);
    });

    test('takes the accent container pair as-is, unmodified', () {
      final base = Palette.seaGlass.light;
      final accent = Palette.plum.light;
      final merged = Palette.withAccent(base, accent);

      expect(merged.primaryContainer, accent.primaryContainer);
      expect(merged.onPrimaryContainer, accent.onPrimaryContainer);
      expect(merged.inversePrimary, accent.inversePrimary);
    });
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
