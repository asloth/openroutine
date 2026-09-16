import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/typography.dart';
import '../../../widgets/tinted/tinted.dart';
import 'home_ink.dart';

/// The date, a greeting for the time of day, the streak, and Settings.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.now, required this.streakDays});

  final DateTime now;
  final int streakDays;

  static const _greetingStyle = TextStyle(
    fontFamily: AppTypography.display,
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.7,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = HomeInk.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final greeting = switch (now.hour) {
      < 12 => l10n.homeGreetingMorning,
      < 18 => l10n.homeGreetingAfternoon,
      _ => l10n.homeGreetingEvening,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.MMMMEEEEd(locale).format(now).toUpperCase(),
                style: HomeInk.label.copyWith(
                  letterSpacing: 0.9,
                  color: ink.muted(0.42),
                ),
              ),
              const SizedBox(height: 6),
              Text(greeting, style: _greetingStyle.copyWith(color: ink.ink)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StreakPill(days: streakDays),
        const SizedBox(width: 8),
        SoftCircleButton(
          icon: Icons.settings_outlined,
          tooltip: l10n.settingsTitle,
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    const shape = StadiumBorder();
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.homeStreakPill(days),
      excludeSemantics: true,
      child: Material(
        key: const Key('streakPill'),
        color: ink.card,
        shape: shape.copyWith(side: BorderSide(color: ink.hairline)),
        child: InkWell(
          customBorder: shape,
          onTap: () => context.go('/stats'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: ink.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$days',
                    style: HomeInk.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ink.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
