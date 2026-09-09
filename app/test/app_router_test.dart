import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/main.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(binding.platformDispatcher.clearDefaultRouteNameTestValue);

  String initialLocation() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container
        .read(goRouterProvider)
        .routeInformationProvider
        .value
        .uri
        .toString();
  }

  test('starts on the routine list when the platform offers no route', () {
    binding.platformDispatcher.defaultRouteNameTestValue = '/';

    expect(initialLocation(), '/routines');
  });

  test('starts on the routine list when a widget tap launches the app', () {
    // Android hands the widget's tap URI to Flutter as the default route.
    // go_router would otherwise try to match it and land on Page Not Found;
    // the widget tap is replayed by HomeWidget once the app is up, so the
    // router's job here is to stay out of the way.
    binding.platformDispatcher.defaultRouteNameTestValue =
        'openroutine://timer?routineId=01a07d35-537a-7630-865e-2f8dd939794c';

    expect(initialLocation(), '/routines');
  });
}
