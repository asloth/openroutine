import 'dart:convert';
import 'dart:typed_data';

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
      fileName: 'routine-$routineName-${_dateStamp()}.json',
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

  String _dateStamp() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${pad(now.month)}-${pad(now.day)}';
  }
}
