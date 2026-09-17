import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/theme/theme.dart';
import 'package:openroutine/widgets/mascot_slot.dart';
import 'package:rive/rive.dart' show File, RiveFailed, RiveLoading;

/// The pet itself is a Rive file, and `rive_native` is not loaded in a widget
/// test, so these cover the contract around it: the slot fills its space, it
/// comes to rest, and it stays out of the semantics tree unless asked.
void main() {
  Widget host(Widget child, {Palette? palette}) => MaterialApp(
    theme: AppTheme.light(palette ?? Palette.inkIris),
    home: Scaffold(body: Center(child: child)),
  );

  tearDown(() {
    // Every test shares the same static, once-per-run file future, so a
    // loader substituted in one test must not bleed into the next.
    MascotSlot.debugFileLoader = null;
  });

  group('mascotLoadVisual (what the shared file future says to show)', () {
    test('still in flight stays empty, not the old placeholder', () {
      expect(
        mascotLoadVisual<int>(const AsyncSnapshot.waiting()),
        MascotSlotVisual.empty,
      );
      expect(
        mascotLoadVisual<int>(const AsyncSnapshot.nothing()),
        MascotSlotVisual.empty,
      );
    });

    test('resolved with no file falls back to the placeholder', () {
      expect(
        mascotLoadVisual<int>(
          const AsyncSnapshot.withData(ConnectionState.done, null),
        ),
        MascotSlotVisual.placeholder,
      );
    });

    test('resolved with a file moves on to Rive', () {
      expect(
        mascotLoadVisual<int>(
          const AsyncSnapshot.withData(ConnectionState.done, 1),
        ),
        MascotSlotVisual.rive,
      );
    });
  });

  group('mascotRiveVisual (what the state machine says to show)', () {
    test('still loading stays empty', () {
      expect(mascotRiveVisual(RiveLoading()), MascotSlotVisual.empty);
    });

    test('failed falls back to the placeholder', () {
      expect(
        mascotRiveVisual(RiveFailed(Exception('nope'))),
        MascotSlotVisual.placeholder,
      );
    });
  });

  testWidgets('stays empty, not the old placeholder, while the shared file '
      'is still loading', (tester) async {
    final neverCompletes = Completer<File?>();
    MascotSlot.debugFileLoader = () => neverCompletes.future;

    await tester.pumpWidget(host(const MascotSlot(size: 96)));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(MascotSlot),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.getSize(find.byType(MascotSlot)), const Size(96, 96));
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to the placeholder once loading finishes with no '
      'file', (tester) async {
    MascotSlot.debugFileLoader = () async => null;

    await tester.pumpWidget(host(const MascotSlot(size: 96)));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(MascotSlot),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('two slots share the same load: the loader runs once', (
    tester,
  ) async {
    var loadCount = 0;
    final neverCompletes = Completer<File?>();
    MascotSlot.debugFileLoader = () {
      loadCount++;
      return neverCompletes.future;
    };

    await tester.pumpWidget(
      host(const Row(children: [MascotSlot(size: 48), MascotSlot(size: 48)])),
    );
    await tester.pump();

    expect(find.byType(MascotSlot), findsNWidgets(2));
    expect(loadCount, 1);
  });

  testWidgets('fills the size it is given and settles', (tester) async {
    await tester.pumpWidget(host(const MascotSlot(size: 96)));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(MascotSlot)), const Size(96, 96));
  });

  testWidgets('draws something for every mood', (tester) async {
    for (final mood in MascotMood.values) {
      await tester.pumpWidget(host(MascotSlot(mood: mood, size: 72)));
      await tester.pumpAndSettle();

      expect(find.byType(MascotSlot), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('is decorative unless it is given a label', (tester) async {
    await tester.pumpWidget(host(const MascotSlot(size: 64)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Pet'), findsNothing);

    await tester.pumpWidget(
      host(const MascotSlot(size: 64, semanticLabel: 'Pet')),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Pet'), findsOneWidget);
  });

  testWidgets('holds still when the system asks for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(const MascotSlot(size: 80)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
