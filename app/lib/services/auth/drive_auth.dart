import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// OAuth client IDs, supplied at build time via
/// `--dart-define-from-file=dart_define.json` (see dart_define.example.json).
/// They are not secrets — they ship inside the app binary — but they point at
/// a specific Google Cloud project, and docs/SPEC.md §13 keeps this repo free
/// of anything project-specific.
///
/// When they are absent the app is still fully functional: [isConfigured] is
/// false, Drive is offered as unavailable, and everything runs Local-only.
/// That is the state anyone cloning the public repo starts in.
class DriveConfig {
  const DriveConfig._();

  static const webClientId = String.fromEnvironment('DRIVE_WEB_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('DRIVE_IOS_CLIENT_ID');

  /// Android needs the *Web* client ID: since google_sign_in v7 it goes
  /// through Credential Manager, which issues tokens to a Web-type audience.
  /// The Android OAuth client exists only so Google can check the APK
  /// signature, and is never referenced from code.
  static bool get isConfigured => webClientId.isNotEmpty;
}

/// Raised when Drive needs the user to grant access again, rather than when
/// something went wrong. This is a routine state, not a failure: while the
/// Cloud project is in Testing, Google expires refresh tokens after seven
/// days. The sync queue treats it as "stop and wait for the user" instead of
/// retrying with backoff — see drive/sync_queue.dart.
class DriveAuthExpired implements Exception {
  const DriveAuthExpired([this.detail]);

  final String? detail;

  @override
  String toString() =>
      'DriveAuthExpired${detail == null ? '' : ': $detail'}';
}

/// Thrown when Drive is used in a build that carries no client IDs.
class DriveNotConfigured implements Exception {
  const DriveNotConfigured();

  @override
  String toString() =>
      'DriveNotConfigured: build with --dart-define-from-file=dart_define.json';
}

/// The only place that talks to `google_sign_in`.
///
/// docs/SPEC.md §6 frames this as **"Connect Google Drive"**, never "Sign in
/// with Google": the app has no account concept and is fully usable without
/// one. That framing is load-bearing for App Store review (§14), so this class
/// deliberately exposes `connect`/`disconnect` rather than `signIn`/`signOut`.
class DriveAuth {
  DriveAuth({GoogleSignIn? signIn}) : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;

  /// Grants access only to files this app creates — the user's other Drive
  /// files are never visible to us (docs/SPEC.md §6). Google classifies it as
  /// non-sensitive, so it needs no verification review.
  static const scopes = <String>['https://www.googleapis.com/auth/drive.file'];

  final _connected = StreamController<bool>.broadcast();
  GoogleSignInAccount? _user;
  bool _initialized = false;

  /// Emits whenever the connection is established or lost, so the sync
  /// provider can react without polling.
  Stream<bool> get connectionChanges => _connected.stream;

  bool get isConnected => _user != null;

  /// Safe to call more than once; only the first call reaches the plugin.
  Future<void> initialize() async {
    if (_initialized) return;
    if (!DriveConfig.isConfigured) throw const DriveNotConfigured();

    await _signIn.initialize(
      // Only Apple platforms take a client ID here; Android derives its
      // identity from the APK signature plus the serverClientId below.
      clientId: _isApple ? DriveConfig.iosClientId : null,
      serverClientId: DriveConfig.webClientId,
    );
    _signIn.authenticationEvents.listen(_onAuthEvent, onError: (_) {
      _setUser(null);
    });
    _initialized = true;
  }

  /// Restores a previous connection without showing any UI. Returns false when
  /// there is nothing to restore, which is not an error — it is what a fresh
  /// install and an expired grant both look like.
  Future<bool> restore() async {
    await initialize();
    try {
      await _signIn.attemptLightweightAuthentication();
    } on GoogleSignInException {
      return false;
    }
    return _user != null;
  }

  /// Interactive. Must be called from a user gesture.
  Future<void> connect() async {
    await initialize();
    if (_signIn.supportsAuthenticate()) {
      await _signIn.authenticate();
    }
    final user = _user;
    if (user == null) throw const DriveAuthExpired('authentication produced no account');
    await user.authorizationClient.authorizeScopes(scopes);
  }

  /// Revokes the grant. Local data is untouched — disconnecting stops syncing,
  /// it does not delete anything here or in Drive.
  Future<void> disconnect() async {
    if (!_initialized) return;
    await _signIn.disconnect();
    _setUser(null);
  }

  /// Authorization headers for a Drive REST call, obtained silently.
  ///
  /// Throws [DriveAuthExpired] rather than returning null so that every caller
  /// funnels into the same "needs reconnect" path — a null here and a 401 from
  /// Drive mean the same thing to the queue.
  Future<Map<String, String>> headers() async {
    final user = _user;
    if (user == null) throw const DriveAuthExpired('not connected');
    final headers = await user.authorizationClient.authorizationHeaders(scopes);
    if (headers == null) throw const DriveAuthExpired('scopes no longer granted');
    return headers;
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    _setUser(switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    });
  }

  void _setUser(GoogleSignInAccount? user) {
    final was = _user != null;
    _user = user;
    if (was != (user != null)) _connected.add(user != null);
  }

  static bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void dispose() => _connected.close();
}
