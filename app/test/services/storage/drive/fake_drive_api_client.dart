import 'dart:async';

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
  final List<String> mutations = [];

  String? _gatedUploadName;
  Completer<void>? _uploadStarted;
  Completer<void>? _releaseUpload;

  String _id() => 'id-${_nextId++}';

  void _maybeFail() {
    final failure = failNextWith;
    if (failure == null) return;
    failNextWith = null;
    throw failure;
  }

  @override
  Future<String?> discoverFolder(String name, {String? parentId}) async {
    _maybeFail();
    final matches = _nodes.entries
        .where(
          (e) =>
              e.value.isFolder &&
              e.value.name == name &&
              e.value.parentId == parentId,
        )
        .map((e) => e.key)
        .toList();
    if (matches.length > 1) throw DriveAmbiguousDiscovery(name);
    return matches.isEmpty ? null : matches.single;
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
    mutations.add('ensure:$name');
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
  Future<DriveAuthoritySnapshot?> readTextFile({
    required String parentId,
    required String name,
  }) async {
    final id = await findFile(parentId: parentId, name: name);
    final node = id == null ? null : _nodes[id];
    if (node == null || node.content == null) return null;
    return DriveAuthoritySnapshot(
      file: DriveFileRevision(
        id: id!,
        version: node.version,
        etag: 'etag-${node.version}',
      ),
      content: node.content!,
      schemaAuthority: _schemaAuthority(node.content!),
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
    _maybeFail();
    final current = fileId == null ? null : _nodes[fileId];
    if (expectedRevision != null &&
        (current == null || current.version != expectedRevision.version)) {
      throw DriveRevisionConflict(fileId!);
    }
    if (expectAbsent &&
        await findFile(parentId: parentId, name: name) != null) {
      throw const DriveRevisionConflict('expected-absent');
    }
    if (name == _gatedUploadName) {
      _uploadStarted!.complete();
      await _releaseUpload!.future;
      _gatedUploadName = null;
    }
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
    mutations.add('upload:$name');
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

  void gateNextUpload(String name) {
    _gatedUploadName = name;
    _uploadStarted = Completer<void>();
    _releaseUpload = Completer<void>();
  }

  Future<void> get gatedUploadStarted => _uploadStarted!.future;

  void releaseGatedUpload() => _releaseUpload!.complete();

  /// Content of a file by name, wherever it sits. Names are unique across the
  /// folders this app writes, so this is unambiguous.
  String? contentOf(String name) {
    for (final node in _nodes.values) {
      if (node.name == name) return node.content;
    }
    return null;
  }

  bool exists(String name) => _nodes.values.any((node) => node.name == name);

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

  void seedFolder(String name, {String? parentId}) {
    _nodes[_id()] = _Node(name: name, parentId: parentId, isFolder: true);
  }

  String? _schemaAuthority(String content) {
    return RegExp(
      r'"schema_version"\s*:\s*"([^"]+)"',
    ).firstMatch(content)?.group(1);
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
    this.version = 1,
  });

  final String name;
  final String? parentId;
  final bool isFolder;
  final String? content;
  final int version;

  _Node withContent(String value) => _Node(
    name: name,
    parentId: parentId,
    isFolder: isFolder,
    content: value,
    version: version + 1,
  );
}

/// Convenience for the auth-expiry tests, so they read as what they mean.
const driveAuthExpired = DriveAuthExpired('test');
const driveOffline = DriveOffline('no network');
