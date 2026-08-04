import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/drive_auth.dart';

/// Drive said no, and retrying later might work (5xx, rate limits).
class DriveApiException implements Exception {
  const DriveApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'DriveApiException($statusCode): $body';
}

/// The request never reached Drive. Distinct from [DriveApiException] because
/// the queue backs off differently: being offline is the normal state this app
/// is designed around, not a server problem.
class DriveOffline implements Exception {
  const DriveOffline(this.cause);

  final Object cause;

  @override
  String toString() => 'DriveOffline: $cause';
}

/// The four Drive operations this app needs, and nothing else.
///
/// Kept as an interface so the sync worker can be tested end to end against an
/// in-memory fake — see test/services/storage/drive/fake_drive_api_client.dart.
abstract class DriveApiClient {
  /// Returns the folder's file ID, creating it if it does not exist.
  Future<String> ensureFolder(String name);

  /// File ID, or null when the folder holds no such file.
  Future<String?> findFile({required String parentId, required String name});

  /// File contents, or null when [fileId] no longer exists.
  Future<String?> downloadText(String fileId);

  /// Creates the file when [fileId] is null, otherwise replaces its contents.
  /// Returns the file ID either way.
  Future<String> uploadText({
    required String parentId,
    required String name,
    required String content,
    String? fileId,
    String mimeType = 'application/json',
  });
}

/// Drive REST v3 over plain `http`.
///
/// Everything this client touches lives under the `drive.file` scope, which
/// means Drive only ever shows us files this app created (docs/SPEC.md §6).
/// That is also why searches here can be unqualified by owner: there is
/// nothing else in scope to collide with.
class HttpDriveApiClient implements DriveApiClient {
  HttpDriveApiClient({
    required Future<Map<String, String>> Function() headers,
    http.Client? httpClient,
  }) : _headers = headers,
       _http = httpClient ?? http.Client();

  final Future<Map<String, String>> Function() _headers;
  final http.Client _http;

  static const _folderMime = 'application/vnd.google-apps.folder';
  static final _files = Uri.parse('https://www.googleapis.com/drive/v3/files');
  static const _uploadBase = 'https://www.googleapis.com/upload/drive/v3/files';

  @override
  Future<String> ensureFolder(String name) async {
    final existing = await _search(
      "name = '${_escape(name)}' and mimeType = '$_folderMime' and trashed = false",
    );
    if (existing != null) return existing;

    final response = await _send(
      (h) => _http.post(
        _files,
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'mimeType': _folderMime}),
      ),
    );
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  @override
  Future<String?> findFile({
    required String parentId,
    required String name,
  }) {
    return _search(
      "name = '${_escape(name)}' and '${_escape(parentId)}' in parents "
      'and trashed = false',
    );
  }

  @override
  Future<String?> downloadText(String fileId) async {
    try {
      final response = await _send(
        (h) => _http.get(
          _files.replace(path: '${_files.path}/$fileId', queryParameters: {
            'alt': 'media',
          }),
          headers: h,
        ),
        // A file the user deleted from Drive behind our back is a normal
        // outcome, not an error: the caller treats null as "nothing remote
        // yet" and pushes a fresh copy.
        allow404: true,
      );
      if (response.statusCode == 404) return null;
      return utf8.decode(response.bodyBytes);
    } on DriveApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<String> uploadText({
    required String parentId,
    required String name,
    required String content,
    String? fileId,
    String mimeType = 'application/json',
  }) async {
    if (fileId != null) {
      // Updating contents only — metadata (name, parent) is already right, so
      // a simple media upload is enough.
      final response = await _send(
        (h) => _http.patch(
          Uri.parse('$_uploadBase/$fileId?uploadType=media'),
          headers: {...h, 'Content-Type': mimeType},
          body: utf8.encode(content),
        ),
      );
      return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
    }

    // Creating: metadata and bytes have to travel together, so multipart.
    const boundary = 'openroutine-boundary';
    final metadata = jsonEncode({'name': name, 'parents': [parentId]});
    final body = <int>[
      ...utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$boundary\r\n'
        'Content-Type: $mimeType\r\n\r\n',
      ),
      ...utf8.encode(content),
      ...utf8.encode('\r\n--$boundary--\r\n'),
    ];

    final response = await _send(
      (h) => _http.post(
        Uri.parse('$_uploadBase?uploadType=multipart'),
        headers: {...h, 'Content-Type': 'multipart/related; boundary=$boundary'},
        body: body,
      ),
    );
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<String?> _search(String query) async {
    final response = await _send(
      (h) => _http.get(
        _files.replace(queryParameters: {
          'q': query,
          'spaces': 'drive',
          'fields': 'files(id)',
          'pageSize': '1',
        }),
        headers: h,
      ),
    );
    final files =
        (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List;
    if (files.isEmpty) return null;
    return (files.first as Map<String, dynamic>)['id'] as String;
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool allow404 = false,
  }) async {
    final headers = await _headers();
    final http.Response response;
    try {
      response = await request(headers);
    } on SocketException catch (e) {
      throw DriveOffline(e);
    } on http.ClientException catch (e) {
      throw DriveOffline(e);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return response;
    if (allow404 && response.statusCode == 404) return response;

    // 401 always means the grant is gone. 403 is ambiguous — Drive uses it for
    // both "you are not allowed" and "you are going too fast" — so only the
    // permission flavour becomes a reconnect prompt; throttling stays
    // retryable.
    if (response.statusCode == 401 ||
        (response.statusCode == 403 && !_isThrottling(response.body))) {
      throw DriveAuthExpired('Drive returned ${response.statusCode}');
    }
    throw DriveApiException(response.statusCode, response.body);
  }

  static bool _isThrottling(String body) =>
      body.contains('rateLimitExceeded') ||
      body.contains('userRateLimitExceeded') ||
      body.contains('quotaExceeded');

  /// Drive's query language delimits string literals with single quotes and
  /// escapes them with a backslash.
  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}
