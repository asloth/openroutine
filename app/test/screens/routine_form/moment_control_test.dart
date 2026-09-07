import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';

void main() {
  /// Asserts against the localizations directly rather than pumping the whole
  /// form: what changed is the wording, and the wording is the contract. It
  /// also lets the Spanish requirement be checked, which a single-locale
  /// widget test could not.
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.load(locale);

  group('the control is named for a moment, not a mechanism', () {
    test('English names a moment', () async {
      final l10n = await load(const Locale('en'));

      expect(l10n.routineFormTriggerLabel, 'Moment');
      expect(l10n.routineFormNewTriggerTitle, 'New moment');
      expect(l10n.routineFormTriggerName, 'Moment name');
      expect(l10n.routinesNoTrigger, 'No moment');
    });

    test('English no longer implies automatic activation', () async {
      final l10n = await load(const Locale('en'));

      for (final text in [
        l10n.routineFormTriggerLabel,
        l10n.routineFormNewTriggerTitle,
        l10n.routineFormTriggerName,
        l10n.routinesNoTrigger,
      ]) {
        expect(
          text.toLowerCase(),
          isNot(contains('trigger')),
          reason: 'the app triggers nothing; the name must not claim it does',
        );
      }
    });

    test('Spanish conveys a moment, not a firing mechanism', () async {
      final l10n = await load(const Locale('es'));

      expect(l10n.routineFormTriggerLabel, 'Momento');
      expect(
        l10n.routineFormTriggerLabel.toLowerCase(),
        isNot(contains('disparador')),
        reason: '"disparador" names a firing mechanism',
      );
      expect(l10n.routinesNoTrigger, 'Sin momento');
    });
  });

  group('the control states its effects', () {
    test('the helper names both grouping and reminders', () async {
      final en = await load(const Locale('en'));

      expect(en.routineFormMomentHelper, isNotEmpty);
      expect(en.routineFormMomentHelper.toLowerCase(), contains('group'));
      expect(en.routineFormMomentHelper.toLowerCase(), contains('reminder'));
    });

    test('Spanish states the same two effects', () async {
      final es = await load(const Locale('es'));

      expect(es.routineFormMomentHelper.toLowerCase(), contains('agrupa'));
      expect(
        es.routineFormMomentHelper.toLowerCase(),
        contains('recordatorio'),
      );
    });
  });
}
