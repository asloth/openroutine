import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'feedback_provider.g.dart';

/// Opens a link in another app and says whether anything could.
typedef UrlOpener = Future<bool> Function(Uri uri);

/// `launchUrl` in external-app mode. A provider so widget tests can stand in
/// for a phone with, or without, an email app.
@Riverpod(keepAlive: true)
UrlOpener urlOpener(Ref ref) => (uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
};
