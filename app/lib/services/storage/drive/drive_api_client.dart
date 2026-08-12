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

class DriveAmbiguousDiscovery implements Exception {
  const DriveAmbiguousDiscovery(this.name);
  final String name;
}

class DriveRevisionConflict implements Exception {
  const DriveRevisionConflict(this.fileId);
  final String fileId;
}

class DriveFileRevision {
  const DriveFileRevision({required this.id, required this.version, this.etag});
  final String id;
  final int version;
  final String? etag;
}

class DriveAuthoritySnapshot {
  const DriveAuthoritySnapshot({
    required this.file,
    required this.content,
    required this.schemaAuthority,
  });
  final DriveFileRevision file;
  final String content;
  final String? schemaAuthority;
}

/// The four Drive operations this app needs, and nothing else.
///
/// Kept as an interface so the sync worker can be tested end to end against an
/// in-memory fake — see test/services/storage/drive/fake_drive_api_client.dart.
abstract class DriveApiClient {
  Future<String?> discoverFolder(String name, {String? parentId});

  Future<DriveAuthoritySnapshot?> readTextFile({
    required String parentId,
    required String name,
  });

  /// Returns the folder's file ID, creating it if it does not exist. Omit
  /// [parentId] for a folder at the root of My Drive.
  ///
  /// Folders cannot go through [uploadText]: Drive creates them with a
  /// metadata-only POST, and sending `application/vnd.google-apps.folder` as
  /// the media type of an upload is rejected with
  /// `400 invalidContentType`.
  Future<String> ensureFolder(String name, {String? parentId});

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
    DriveFileRevision? expectedRevision,
    bool expectAbsent = false,
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
  Future<String?> discoverFolder(String name, {String? parentId}) async {
    final parentClause = parentId == null
        ? ''
        : " and '${_escape(parentId)}' in parents";
    final matches = await _searchAll(
      "name = '${_escape(name)}' and mimeType = '$_folderMime' "
      'and trashed = false$parentClause',
    );
    if (matches.length > 1) throw DriveAmbiguousDiscovery(name);
    return matches.isEmpty ? null : matches.single;
  }

  @override
  Future<String> ensureFolder(String name, {String? parentId}) async {
    final existing = await discoverFolder(name, parentId: parentId);
    if (existing != null) return existing;

    final response = await _send(
      (h) => _http.post(
        _files,
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'mimeType': _folderMime,
          if (parentId != null) 'parents': [parentId],
        }),
      ),
    );
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  @override
  Future<String?> findFile({required String parentId, required String name}) {
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
          _files.replace(
            path: '${_files.path}/$fileId',
            queryParameters: {'alt': 'media'},
          ),
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
  Future<DriveAuthoritySnapshot?> readTextFile({
    required String parentId,
    required String name,
  }) async {
    final id = await findFile(parentId: parentId, name: name);
    if (id == null) return null;
    final metadata = await _send(
      (h) => _http.get(
        _files.replace(
          path: '${_files.path}/$id',
          queryParameters: {'fields': 'id,version'},
        ),
        headers: h,
      ),
      allow404: true,
    );
    if (metadata.statusCode == 404) return null;
    final content = await downloadText(id);
    if (content == null) return null;
    final json = jsonDecode(metadata.body) as Map<String, dynamic>;
    String? schemaAuthority;
    try {
      schemaAuthority =
          (jsonDecode(content) as Map<String, dynamic>)['schema_version']
              as String?;
    } on Object {
      schemaAuthority = null;
    }
    return DriveAuthoritySnapshot(
      file: DriveFileRevision(
        id: json['id'] as String,
        version: int.parse(json['version'].toString()),
        etag: metadata.headers['etag'],
      ),
      content: content,
      schemaAuthority: schemaAuthority,
    );
  }

  @override
  Future<String> uploadText({
    required String parentId,
    required String name,
    required String content,
    String? fileId,
    DriveFileRevision? expectedRevision,
    bool expectAbsent = false,
    String mimeType = 'application/json',
  }) async {
    if (fileId != null) {
      if (expectedRevision != null && expectedRevision.etag == null) {
        final current = await _revision(fileId);
        if (current == null || current.version != expectedRevision.version) {
          throw DriveRevisionConflict(fileId);
        }
      }
      // Updating contents only — metadata (name, parent) is already right, so
      // a simple media upload is enough.
      final http.Response response;
      try {
        response = await _send(
          (h) => _http.patch(
            Uri.parse('$_uploadBase/$fileId?uploadType=media'),
            headers: {
              ...h,
              'Content-Type': mimeType,
              if (expectedRevision?.etag != null)
                'If-Match': expectedRevision!.etag!,
            },
            body: utf8.encode(content),
          ),
        );
      } on DriveApiException catch (e) {
        if (e.statusCode == 412) throw DriveRevisionConflict(fileId);
        rethrow;
      }
      return (jsonDecode(response.body) as Map<String, dynamic>)['id']
          as String;
    }

    if (expectAbsent &&
        await findFile(parentId: parentId, name: name) != null) {
      throw const DriveRevisionConflict('expected-absent');
    }

    // Creating: metadata and bytes have to travel together, so multipart.
    const boundary = 'openroutine-boundary';
    final metadata = jsonEncode({
      'name': name,
      'parents': [parentId],
    });
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
        headers: {
          ...h,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      ),
    );
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<String?> _search(String query) async {
    final files = await _searchAll(query);
    return files.isEmpty ? null : files.first;
  }

  Future<List<String>> _searchAll(String query) async {
    final response = await _send(
      (h) => _http.get(
        _files.replace(
          queryParameters: {
            'q': query,
            'spaces': 'drive',
            'fields': 'files(id)',
            'pageSize': '2',
          },
        ),
        headers: h,
      ),
    );
    final files =
        (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List;
    return files
        .map((file) => (file as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Future<DriveFileRevision?> _revision(String fileId) async {
    final response = await _send(
      (h) => _http.get(
        _files.replace(
          path: '${_files.path}/$fileId',
          queryParameters: {'fields': 'id,version'},
        ),
        headers: h,
      ),
      allow404: true,
    );
    if (response.statusCode == 404) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DriveFileRevision(
      id: json['id'] as String,
      version: int.parse(json['version'].toString()),
      etag: response.headers['etag'],
    );
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
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
