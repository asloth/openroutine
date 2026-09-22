import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:share_plus/share_plus.dart';

import '../../models/export_bundle.dart';
import '../storage/storage_adapter.dart';

/// One function for both "Share this routine" (routine detail) and
/// "Export all" (Settings) — docs/SPEC.md §10: single/full exports use the
/// same top-level shape, so one code path produces both.
class ExportService {
  ExportService(this._storage);

  final StorageAdapter _storage;

  Future<ShareResult> exportRoutine(
    String routineId, {
    required String routineName,
  }) async {
    final bundle = await _storage.exportRoutine(routineId);
    return _share(
      bundle,
      fileName: 'routine-${fileNameFor(routineName)}-${_dateStamp()}.json',
    );
  }

  Future<ShareResult> exportAll() async {
    final bundle = await _storage.exportAll();
    return _share(bundle, fileName: 'openroutine-export-${_dateStamp()}.json');
  }

  Future<ShareResult> _share(ExportBundle bundle, {required String fileName}) {
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(bundle.toJson());
    return SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(jsonString)),
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }

  /// Keeps the part of a routine name a file name can carry, and drops the
  /// rest. Sharing builds a temp path from this, so a name is data here, not
  /// a path — and a name that leaves nothing behind still has to produce a
  /// file someone can find.
  @visibleForTesting
  static String fileNameFor(String routineName) {
    final kept = routineName
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]+'), '-')
        .replaceAll(RegExp(r'[-\s]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return kept.isEmpty ? 'export' : kept;
  }

  String _dateStamp() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${pad(now.month)}-${pad(now.day)}';
  }
}
