import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The launcher inflates widget layouts through RemoteViews, which refuses any
// class outside this list. A refused class doesn't fail the build: the widget
// shows "Couldn't add widget" in its place, on the phone only.
// https://developer.android.com/develop/ui/views/appwidgets/overview#layouts
const _allowed = {
  'FrameLayout',
  'LinearLayout',
  'RelativeLayout',
  'GridLayout',
  'AnalogClock',
  'Button',
  'Chronometer',
  'ImageButton',
  'ImageView',
  'ProgressBar',
  'TextClock',
  'TextView',
  'CheckBox',
  'RadioButton',
  'RadioGroup',
  'Switch',
  'AdapterViewFlipper',
  'GridView',
  'ListView',
  'StackView',
  'ViewFlipper',
  'ViewStub',
  'include',
  'merge',
};

void main() {
  final layouts = Directory('android/app/src/main/res/layout')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.split('/').last.startsWith('routine_widget'))
      .toList();

  test('finds the widget layouts', () {
    expect(layouts, isNotEmpty);
  });

  for (final layout in layouts) {
    final name = layout.path.split('/').last;
    test('$name only uses views a home screen widget can draw', () {
      final tags = RegExp(r'<([A-Za-z][\w.]*)')
          .allMatches(layout.readAsStringSync())
          .map((m) => m.group(1)!)
          .where((tag) => tag != 'xml');
      expect(tags.where((tag) => !_allowed.contains(tag)), isEmpty);
    });
  }
}
