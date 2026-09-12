import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';

/// One palette now drives the whole theme — surfaces, every colour role, the
/// neumorphic pair, and the mascot all come from whichever palette the user
/// picked as their accent. There is no separate background palette to merge
/// it into any more.
void main() {
  group('AppTheme with a chosen palette', () {
    test('light carries the palette\'s own mascot and surface', () {
      final theme = AppTheme.light(Palette.moss);

      expect(theme.extension<MascotPalette>(), Palette.moss.mascot);
      expect(theme.colorScheme.surface, Palette.moss.light.surface);
    });

    test('dark carries the palette\'s own mascot and surface', () {
      final theme = AppTheme.dark(Palette.moss);

      expect(theme.extension<MascotPalette>(), Palette.moss.mascot);
      expect(theme.colorScheme.surface, Palette.moss.dark.surface);
    });
  });

  group('AppTheme with no palette given', () {
    test('light is Ink & Iris throughout', () {
      final theme = AppTheme.light();

      expect(theme.colorScheme, Palette.inkIris.light);
      expect(theme.extension<MascotPalette>(), Palette.inkIris.mascot);
    });

    test('dark is Ink & Iris throughout', () {
      final theme = AppTheme.dark();

      expect(theme.colorScheme, Palette.inkIris.dark);
      expect(theme.extension<MascotPalette>(), Palette.inkIris.mascot);
    });
  });
}
