import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/screen/screen_wake.dart';

part 'screen_wake_provider.g.dart';

@Riverpod(keepAlive: true)
ScreenWake screenWake(Ref ref) => const WakelockScreenWake();
