import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/typography.dart';

void main() {
  test('headings use Bricolage Grotesque and prose uses Plus Jakarta Sans', () {
    expect(AppTypography.display, 'Bricolage Grotesque');
    expect(AppTypography.body, 'Plus Jakarta Sans');
  });

  test('every text role uses one of the two bundled families', () {
    final t = AppTypography.textTheme;
    final roles = [
      t.displayLarge,
      t.displayMedium,
      t.displaySmall,
      t.headlineLarge,
      t.headlineMedium,
      t.headlineSmall,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    ];
    for (final role in roles) {
      expect([
        AppTypography.display,
        AppTypography.body,
      ], contains(role!.fontFamily));
    }
  });
}
