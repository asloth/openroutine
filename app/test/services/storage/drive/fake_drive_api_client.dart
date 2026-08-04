import 'package:openroutine/services/auth/drive_auth.dart';
import 'package:openroutine/services/storage/drive/drive_api_client.dart';

/// An in-memory stand-in for the user's Drive.
///
/// Deliberately models Drive's shape rather than a flat map: files are
/// identified by an opaque ID and located by (parent, name), because that
/// distinction is where the real client's bugs live — an upload that forgets
/// its `fileId` silently creates a second `routines.json` instead of replacing
/// the first, and only a fake that can hold two same-named files will catch it.
class FakeDriveApiClient implements DriveApiClient {
  final Map<String, _Node> _nodes = {};
  var _nextId = 0;

  /// Thrown by the next call, then cleared. Lets a test make exactly one
  /// request fail — the difference between "sync gave up" and "sync retried".
  Object? failNextWith;

  /// Every uploadText call, for asserting that a clean sync uploads nothing.
  final List<String> uploads = [];

  String _id() => 'id-${_nextId++}';

  void _maybeFail() {
    final failure = failNextWith;
    if (failure == null) return;
    failNextWith = null;
    throw failure;
  }

  @override
  Future<String> ensureFolder(String name, {String? parentId}) async {
    _maybeFail();
    final existing = _nodes.entries
        .where(
          (e) =>
              e.value.isFolder &&
              e.value.name == name &&
              e.value.parentId == parentId,
        )
        .map((e) => e.key)
        .firstOrNull;
    if (existing != null) return existing;

    final id = _id();
    _nodes[id] = _Node(name: name, parentId: parentId, isFolder: true);
    return id;
  }

  @override
  Future<String?> findFile({
    required String parentId,
    required String name,
  }) async {
    _maybeFail();
    for (final entry in _nodes.entries) {
      if (entry.value.parentId == parentId && entry.value.name == name) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<String?> downloadText(String fileId) async {
    _maybeFail();
    return _nodes[fileId]?.content;
  }

  @override
  Future<String> uploadText({
    required String parentId,
    required String name,
    required String content,
    String? fileId,
    String mimeType = 'application/json',
  }) async {
    _maybeFail();
    // Drive rejects this with `400 invalidContentType`: a folder is created by
    // a metadata-only POST, never by an upload. The fake refused nothing here
    // once, and the resulting bug reached the device — a fake that accepts
    // what the real API rejects is worse than no fake at all.
    if (mimeType == 'application/vnd.google-apps.folder') {
      throw const DriveApiException(
        400,
        '{"error":{"code":400,"message":"Invalid MIME type provided for the '
            'uploaded content.","errors":[{"reason":"invalidContentType"}]}}',
      );
    }
    uploads.add(name);
    if (fileId != null && _nodes.containsKey(fileId)) {
      _nodes[fileId] = _nodes[fileId]!.withContent(content);
      return fileId;
    }
    final id = _id();
    _nodes[id] = _Node(
      name: name,
      parentId: parentId,
      isFolder: mimeType == 'application/vnd.google-apps.folder',
      content: content,
    );
    return id;
  }

  // ---- Test-facing helpers ----

  /// Content of a file by name, wherever it sits. Names are unique across the
  /// folders this app writes, so this is unambiguous.
  String? contentOf(String name) {
    for (final node in _nodes.values) {
      if (node.name == name) return node.content;
    }
    return null;
  }

  bool exists(String name) =>
      _nodes.values.any((node) => node.name == name);

  int countNamed(String name) =>
      _nodes.values.where((node) => node.name == name).length;

  /// Writes a file directly, bypassing the adapter — how a test plays "another
  /// device, or an agent, edited this".
  ///
  /// [path] is relative to the OpenRoutine folder, e.g. `routines.json` or
  /// `completions/2026-08.ndjson`. Taking a path rather than a folder name is
  /// not cosmetic: `completions` is a *child* of the OpenRoutine folder, and a
  /// seed that dropped it at the root would sit somewhere the sync never
  /// looks, quietly turning every merge assertion into a no-op.
  void seed({required String path, required String content}) {
    final segments = path.split('/');
    var parentId = _folderIdByPath(const []);
    for (final folder in segments.take(segments.length - 1)) {
      parentId = _folderIdByPath([folder], under: parentId);
    }

    final name = segments.last;
    final existing = _nodes.entries
        .where((e) => e.value.parentId == parentId && e.value.name == name)
        .map((e) => e.key)
        .firstOrNull;
    if (existing != null) {
      _nodes[existing] = _nodes[existing]!.withContent(content);
      return;
    }
    _nodes[_id()] = _Node(name: name, parentId: parentId, content: content);
  }

  /// Resolves (creating as needed) the OpenRoutine root, or a folder inside it.
  String _folderIdByPath(List<String> names, {String? under}) {
    final name = names.isEmpty ? 'OpenRoutine' : names.single;
    final parentId = names.isEmpty ? null : under;
    final existing = _nodes.entries
        .where(
          (e) =>
              e.value.isFolder &&
              e.value.name == name &&
              e.value.parentId == parentId,
        )
        .map((e) => e.key)
        .firstOrNull;
    if (existing != null) return existing;

    final id = _id();
    _nodes[id] = _Node(name: name, parentId: parentId, isFolder: true);
    return id;
  }
}

class _Node {
  const _Node({
    required this.name,
    required this.parentId,
    this.isFolder = false,
    this.content,
  });

  final String name;
  final String? parentId;
  final bool isFolder;
  final String? content;

  _Node withContent(String value) => _Node(
    name: name,
    parentId: parentId,
    isFolder: isFolder,
    content: value,
  );
}

/// Convenience for the auth-expiry tests, so they read as what they mean.
const driveAuthExpired = DriveAuthExpired('test');
const driveOffline = DriveOffline('no network');
