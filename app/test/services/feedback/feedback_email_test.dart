import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/feedback/feedback_email.dart';

void main() {
  Uri draft() => feedbackEmailUri(
    subject: 'OpenRoutine feedback',
    detailsLabel: 'Details (you can delete them):',
    details: const FeedbackDetails(
      version: '1.2.0',
      buildNumber: '7',
      os: 'android 16',
      language: 'es',
    ),
  );

  test('goes to the feedback address', () {
    final uri = draft();

    expect(uri.scheme, 'mailto');
    expect(uri.path, feedbackAddress);
  });

  test('encodes spaces as %20, never +', () {
    // Several email apps show a + literally, so "OpenRoutine+feedback"
    // would land in the subject line.
    final link = draft().toString();

    expect(link, contains('subject=OpenRoutine%20feedback'));
    expect(link, isNot(contains('+')));
  });

  test('leaves room to write before the details', () {
    final body = draft().queryParameters['body']!;

    expect(body, startsWith('\n\n\n'));
    expect(
      body.indexOf('Details (you can delete them):'),
      greaterThan(body.indexOf('\n\n\n')),
    );
  });

  test('lists the version, build, system, and language', () {
    final body = draft().queryParameters['body']!;

    expect(body, contains('1.2.0 (7)'));
    expect(body, contains('android 16'));
    expect(body, contains('es'));
  });
}
