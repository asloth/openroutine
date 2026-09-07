import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';

/// Returns the background the theme resolves for a *selected* segment.
///
/// Read from the theme rather than from the widget: the widget's own `style`
/// is null here, because the colouring comes from `segmentedButtonTheme` —
/// which is exactly the entry that was missing.
Future<Color?> _selectedSegmentColour(
  WidgetTester tester,
  Palette palette,
) async {
  late ThemeData theme;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(palette),
      home: Builder(
        builder: (context) {
          theme = Theme.of(context);
          return Scaffold(
            body: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('a')),
                ButtonSegment(value: 1, label: Text('b')),
              ],
              selected: const {0},
              onSelectionChanged: (_) {},
            ),
          );
        },
      ),
    ),
  );

  return theme.segmentedButtonTheme.style?.backgroundColor?.resolve({
    WidgetState.selected,
  });
}

void main() {
  group('segmented button follows the palette', () {
    // The one component the theme never configured. Left unset it falls back
    // to Material's default, which paints the selected segment with
    // secondaryContainer while every chip in the app uses primaryContainer.
    testWidgets('a selected segment uses the same role as a selected chip', (
      tester,
    ) async {
      final palette = Palette.warmPaper;
      final colour = await _selectedSegmentColour(tester, palette);

      expect(colour, palette.light.primaryContainer);
    });

    testWidgets('the same holds in a palette whose secondary diverges', (
      tester,
    ) async {
      // sea_glass is generated, so its secondary sits roughly 120 degrees off
      // the base hue. That divergence is what made the defect visible.
      final palette = Palette.seaGlass;
      final colour = await _selectedSegmentColour(tester, palette);

      expect(colour, palette.light.primaryContainer);
      expect(
        colour,
        isNot(palette.light.secondaryContainer),
        reason: 'falling back to the framework default is the defect',
      );
    });
  });

  group('default palette', () {
    test('a fresh install resolves to the default', () {
      expect(Palette.fromStorageId(null), Palette.defaultPalette);
      expect(Palette.defaultPalette.id, 'sea_glass');
    });

    test('an unrecognised identifier resolves to the default', () {
      expect(Palette.fromStorageId('no_such_palette'), Palette.defaultPalette);
    });

    test('a palette the user chose survives the default changing', () {
      expect(Palette.fromStorageId('warm_paper'), Palette.warmPaper);
    });
  });
}
