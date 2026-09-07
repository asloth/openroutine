import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations_en.dart';
import 'package:openroutine/l10n/app_localizations_es.dart';

/// A sync state the user cannot act on is worse than no sync at all, and the
/// only thing that makes "your edits are not leaving this device" actionable
/// is a sentence they can read. CONTRIBUTING requires that sentence in both
/// shipped locales, so a state added to Settings in English only is a bug.
void main() {
  test('the newer-schema block is written in both shipped locales', () {
    final en = AppLocalizationsEn();
    final es = AppLocalizationsEs();

    expect(en.syncStatusNewerSchema, isNotEmpty);
    expect(es.syncStatusNewerSchema, isNotEmpty);
    expect(es.syncStatusNewerSchema, isNot(en.syncStatusNewerSchema));
  });
}
