import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';

/// `RoutineCardColors` is the one place routine cards read their color from —
/// see design.md's "RoutineCardColors is a new ThemeExtension" decision.
void main() {
  group('RoutineCardColors', () {
    test('light theme carries the accent container pair and fixed tokens', () {
      final theme = AppTheme.light(Palette.seaGlass, Palette.plum);
      final cardColors = theme.extension<RoutineCardColors>();
      final accentScheme = Palette.plum.light;

      expect(cardColors, isNotNull);
      expect(cardColors!.fill, accentScheme.primaryContainer);
      expect(cardColors.onFill, accentScheme.onPrimaryContainer);
      expect(cardColors.upcomingFill, AppColors.upcoming);
      expect(cardColors.onUpcomingFill, AppColors.onUpcoming);
      expect(cardColors.timerGround, AppColors.timerGround);
    });

    test('dark theme carries the dark fixed tokens and its own surface for '
        'the timer ground', () {
      final theme = AppTheme.dark(Palette.seaGlass, Palette.plum);
      final cardColors = theme.extension<RoutineCardColors>();
      final accentScheme = Palette.plum.dark;

      expect(cardColors, isNotNull);
      expect(cardColors!.fill, accentScheme.primaryContainer);
      expect(cardColors.onFill, accentScheme.onPrimaryContainer);
      expect(cardColors.upcomingFill, AppColors.upcomingDark);
      expect(cardColors.onUpcomingFill, AppColors.onUpcomingDark);
      expect(cardColors.timerGround, theme.colorScheme.surface);
    });

    test('AppTheme defaults the accent to ink iris when none is given', () {
      final theme = AppTheme.light(Palette.seaGlass);
      final cardColors = theme.extension<RoutineCardColors>();
      final inkIris = Palette.inkIris.light;

      expect(cardColors!.fill, inkIris.primaryContainer);
    });

    test('lerp interpolates every field', () {
      const a = RoutineCardColors(
        fill: Colors.red,
        onFill: Colors.white,
        upcomingFill: Colors.green,
        onUpcomingFill: Colors.black,
        timerGround: Colors.grey,
      );
      const b = RoutineCardColors(
        fill: Colors.blue,
        onFill: Colors.black,
        upcomingFill: Colors.yellow,
        onUpcomingFill: Colors.white,
        timerGround: Colors.brown,
      );

      final mid = a.lerp(b, 0.5);
      expect(mid.fill, Color.lerp(Colors.red, Colors.blue, 0.5));
      expect(mid.onFill, Color.lerp(Colors.white, Colors.black, 0.5));
      expect(mid.upcomingFill, Color.lerp(Colors.green, Colors.yellow, 0.5));
      expect(mid.onUpcomingFill, Color.lerp(Colors.black, Colors.white, 0.5));
      expect(mid.timerGround, Color.lerp(Colors.grey, Colors.brown, 0.5));
    });

    test('copyWith overrides only the given fields', () {
      const original = RoutineCardColors(
        fill: Colors.red,
        onFill: Colors.white,
        upcomingFill: Colors.green,
        onUpcomingFill: Colors.black,
        timerGround: Colors.grey,
      );

      final copy = original.copyWith(fill: Colors.blue);

      expect(copy.fill, Colors.blue);
      expect(copy.onFill, Colors.white);
      expect(copy.upcomingFill, Colors.green);
    });
  });
}
