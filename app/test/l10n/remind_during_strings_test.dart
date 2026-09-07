import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';

void main() {
  /// Asserts against the localizations directly rather than pumping the step
  /// form: what is under test is the wording of a control that has to explain
  /// an invisible behaviour, and the wording is the contract. It also lets the
  /// Spanish copy be checked, which a single-locale widget test could not.
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.load(locale);

  group('the mid-step reminder toggle explains itself', () {
    test('English names the control and both nudges', () async {
      final en = await load(const Locale('en'));

      expect(en.stepFormRemindDuringLabel, isNotEmpty);
      expect(en.stepFormRemindDuringGuidance, isNotEmpty);
      expect(
        en.stepFormRemindDuringGuidance.toLowerCase(),
        contains('halfway'),
        reason: 'the first nudge lands halfway through the estimate',
      );
      expect(
        en.stepFormRemindDuringGuidance.toLowerCase(),
        contains('end'),
        reason: 'the second nudge lands near the end of the estimate',
      );
    });

    test('English says short steps stay quiet', () async {
      final en = await load(const Locale('en'));

      expect(
        en.stepFormRemindDuringGuidance,
        contains('2'),
        reason:
            'a step under two minutes never nudges, and a toggle that '
            'silently does nothing has to say so',
      );
    });

    test('Spanish names the control and both nudges', () async {
      final es = await load(const Locale('es'));

      expect(es.stepFormRemindDuringLabel, isNotEmpty);
      expect(es.stepFormRemindDuringGuidance, isNotEmpty);
      expect(es.stepFormRemindDuringGuidance.toLowerCase(), contains('mitad'));
      expect(es.stepFormRemindDuringGuidance.toLowerCase(), contains('final'));
      expect(es.stepFormRemindDuringGuidance, contains('2'));
    });

    test('the two locales say different words for the same thing', () async {
      final en = await load(const Locale('en'));
      final es = await load(const Locale('es'));

      expect(
        es.stepFormRemindDuringLabel,
        isNot(en.stepFormRemindDuringLabel),
        reason: 'an untranslated string is a missing translation',
      );
      expect(
        es.stepFormRemindDuringGuidance,
        isNot(en.stepFormRemindDuringGuidance),
      );
    });
  });
}
