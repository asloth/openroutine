import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';

/// The pet is the accent's colour, like every button and dot around it. A
/// background palette only sets the paper; if the pet took the background's
/// colour instead, a red-pink background with a blue accent would put a coral
/// pet among blue controls.
void main() {
  final backgrounds = [
    ...Palette.builtIns,
    Palette.fromStorageId('custom:351'),
  ];

  for (final base in backgrounds) {
    for (final accent in Palette.builtIns) {
      test('${base.storageId} background with ${accent.id} accent', () {
        for (final theme in [
          AppTheme.light(base, accent),
          AppTheme.dark(base, accent),
        ]) {
          final mascot = theme.extension<MascotPalette>()!;
          expect(mascot.body, accent.mascot.body);
          expect(mascot.ink, accent.mascot.ink);
        }

        // It still stands out on this background's dark paper.
        final ratio = contrastRatio(accent.mascot.body, base.dark.surface);
        expect(
          ratio,
          greaterThanOrEqualTo(3),
          reason: 'body is ${ratio.toStringAsFixed(2)}:1 on dark paper',
        );
      });
    }
  }
}
