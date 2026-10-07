# Publishing playbook

This is a placeholder. The full App Store and Play Store submission playbook ships in **M6**, per [`SPEC.md`](SPEC.md) §12.

It'll cover the checklist in §15.13, developer account setup (§15.2), privacy manifests (§15.4), and store metadata (§15.9–15.11). Until then, treat §15 of the spec as the source of truth.

## Sign the Android release

Google Play needs every release signed with your upload key. The Gradle config is ready. It reads `app/android/key.properties` when the file exists, and it falls back to the debug key when it doesn't. That way, anyone who clones the repo can still run `flutter build apk --release`. You create the key once, and you keep it safe.

### Create the upload key

1. Run this command. It writes the keystore to a folder outside the repo. Change the path if you like.

   ```bash
   mkdir -p ~/keys
   keytool -genkey -v -keystore ~/keys/openroutine-upload.jks \
     -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. Pick a strong store password when `keytool` asks. Use the same one for the key password, or set a different one if you prefer.
3. Answer the name and organization questions. Google Play doesn't check them.
4. Back up `openroutine-upload.jks` and both passwords in a password manager or an encrypted drive. Keep a second copy somewhere else.

Never put the keystore inside the repo, and never commit it. The `.gitignore` already blocks `key.properties`, `*.jks`, and `*.keystore` as a safety net.

### Point the build at the key

Create `app/android/key.properties` with these four lines. Use your own passwords and the absolute path to the keystore.

```properties
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=upload
storeFile=/home/<you>/keys/openroutine-upload.jks
```

### Build and check

1. From `app/`, build the release:

   ```bash
   /home/sabera/fvm/bin/fvm flutter build appbundle --release --dart-define-from-file=dart_define.json
   ```

   For a quick check on a device, build an APK with `flutter build apk --release` instead.

2. Confirm the signer is your key and not the debug key. `apksigner` lives in `build-tools/` inside your Android SDK. The debug key shows `CN=Android Debug`.

   ```bash
   apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
   ```

### If you lose the key

Losing the upload key doesn't lose the app, but it does slow you down. You'd need to ask Google Play support to reset the upload key, and that takes time and a verification process. Back up the keystore and passwords before your first upload.

Enrolling in Play App Signing is the default for new apps. Google holds the key that signs what users install, and your upload key only proves that the upload came from you.
