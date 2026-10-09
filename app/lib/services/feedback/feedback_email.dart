/// Where Settings › Send feedback addresses its draft. It's public by
/// nature: it shows in the draft's To field and in this repository.
const feedbackAddress = 'openroutine.feedback@example.com';

/// What the draft tells you about the phone it came from. The person
/// sending it sees all of this and can delete any of it.
class FeedbackDetails {
  const FeedbackDetails({
    required this.version,
    required this.buildNumber,
    required this.os,
    required this.language,
  });

  final String version;
  final String buildNumber;
  final String os;
  final String language;
}

/// A `mailto:` draft to [feedbackAddress]: blank lines first, so the cursor
/// lands where you write, then the details under [detailsLabel].
///
/// Built by hand rather than with `Uri(queryParameters: ...)`, which encodes
/// spaces as `+`. Several email apps show those literally.
Uri feedbackEmailUri({
  required String subject,
  required String detailsLabel,
  required FeedbackDetails details,
}) {
  final body = [
    '',
    '',
    '',
    detailsLabel,
    'OpenRoutine ${details.version} (${details.buildNumber})',
    details.os,
    details.language,
  ].join('\n');
  return Uri.parse(
    'mailto:$feedbackAddress'
    '?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );
}
