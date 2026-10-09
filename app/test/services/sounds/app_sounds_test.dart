import 'package:flutter_test/flutter_test.dart';
import 'package:openroutine/services/sounds/app_sounds.dart';

void main() {
  test('the audio context is one the audio package accepts', () {
    // A context the package rejects throws on first use, and play() swallows
    // the error, so every sound goes quiet without a crash to point at it.
    expect(() => AudioplayersAppSounds.context, returnsNormally);
  });
}
