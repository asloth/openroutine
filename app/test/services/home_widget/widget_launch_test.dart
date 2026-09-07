import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/home_widget/widget_launch.dart';

void main() {
  test('a routine row opens that routine in Timer Mode', () {
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://timer?routineId=abc123')),
      '/routines/abc123/timer',
    );
  });

  test('the empty state only opens the app', () {
    expect(widgetLaunchRoute(Uri.parse('openroutine://open')), isNull);
  });

  test('ignores a tap that names no routine', () {
    expect(widgetLaunchRoute(Uri.parse('openroutine://timer')), isNull);
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://timer?routineId=')),
      isNull,
    );
  });

  test('ignores a URI from anywhere else', () {
    expect(
      widgetLaunchRoute(Uri.parse('https://example.com/timer?routineId=a')),
      isNull,
    );
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://elsewhere?routineId=a')),
      isNull,
    );
  });

  test('percent-encodes a routine id into the path', () {
    expect(
      widgetLaunchRoute(Uri.parse('openroutine://timer?routineId=a%2Fb')),
      '/routines/a%2Fb/timer',
    );
  });
}
