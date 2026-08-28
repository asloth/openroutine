import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/l10n/app_localizations.dart';
import 'package:openroutine/models/export_bundle.dart';
import 'package:openroutine/models/import_preview.dart';
import 'package:openroutine/models/routine.dart';
import 'package:openroutine/models/schedule.dart';
import 'package:openroutine/screens/import/import_screen.dart';
import 'package:openroutine/services/import_export/import_service.dart';
import 'package:openroutine/services/storage/drift/app_database.dart'
    show AppDatabase;
import 'package:openroutine/services/storage/local_adapter.dart';
import 'package:openroutine/state/import_export_provider.dart';
import 'package:openroutine/state/storage_provider.dart';

final _now = DateTime.utc(2026, 8, 27);

Routine _routine(String name) => Routine(
  id: 'r1',
  name: name,
  triggerId: null,
  schedule: const Schedule(mode: ScheduleMode.flexible, days: []),
  stepIds: const [],
  createdAt: _now,
  updatedAt: _now,
);

class _NewerBundleImportService implements ImportService {
  _NewerBundleImportService(this.adapter);

  final LocalAdapter adapter;

  ExportBundle get bundle => ExportBundle(
    schemaVersion: '1.2.0',
    exportedAt: _now,
    routines: [_routine('Imported routine')],
    steps: const [],
    triggers: const [],
  );

  @override
  Future<ExportBundle?> pickAndValidate() async => bundle;

  @override
  Future<ImportPreview> preview(ExportBundle bundle) =>
      adapter.previewImport(bundle);

  @override
  Future<void> confirm(ExportBundle bundle) => adapter.confirmImport(bundle);

  @override
  ExportBundle validateJsonString(String contents) =>
      throw UnimplementedError();
}

Widget _wrap(LocalAdapter adapter, Locale locale) => ProviderScope(
  overrides: [
    storageAdapterProvider.overrideWithValue(adapter),
    importServiceProvider.overrideWith(
      (ref) async => _NewerBundleImportService(adapter),
    ),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const ImportScreen(),
  ),
);

void main() {
  for (final entry in {
    'en':
        'This file was created by a newer OpenRoutine version. Nothing was imported. Update OpenRoutine before using this file.',
    'es':
        'Este archivo se creó con una versión más reciente de OpenRoutine. No se importó nada. Actualiza OpenRoutine antes de usar este archivo.',
  }.entries) {
    testWidgets(
      'newer bundle refusal preserves local data and is accessible in ${entry.key}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final adapter = LocalAdapter(AppDatabase(NativeDatabase.memory()));
        await adapter.saveRoutine(_routine('Local routine'));
        await tester.pumpWidget(_wrap(adapter, Locale(entry.key)));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        )!;
        await tester.tap(find.text(l10n.importChooseFile));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.bySemanticsLabel(entry.value), findsOneWidget);
        expect((await adapter.getRoutine('r1'))!.name, 'Local routine');
        semantics.dispose();
      },
    );
  }
}
