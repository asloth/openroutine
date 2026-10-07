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

## Play Internal Testing: first release

Your first Play release goes to Internal Testing. It's the quickest way to get a signed build onto real phones and to find out what Play review needs before a public launch. The related documents:

- [`privacy-policy.md`](privacy-policy.md) is the policy to host.
- [`store-listing.md`](store-listing.md) has the English and Spanish listing text, the screenshot shot list, the Data safety answers, and the permission declarations.

### Checklist

- [ ] **Developer account.** Create a Google Play Console account ($25, one time) and finish identity verification. See [`SPEC.md`](SPEC.md) §15.2.
- [ ] **Upload key and signing.** Create an upload keystore, keep a backup somewhere safe, and enroll in Play App Signing so Google manages the app signing key. Never commit the keystore or its passwords.
- [ ] **Privacy policy URL.** Host `docs/privacy-policy.md` at a stable public URL (GitHub Pages works), fill in `[contact email]`, then paste the URL into Play Console.
- [ ] **OAuth consent screen.** In Google Cloud, publish the consent screen to production and complete verification for the `drive.file` scope. Until you do, the app stays in Testing, Google expires refresh tokens after seven days, and only listed test users can connect Drive. Add your Android client ID for the Play signing certificate's SHA-1 too, because Play re-signs the app.
- [ ] **Create the app.** Name, default language (English), free, and the `app.openroutine.mobile` package.
- [ ] **Store listing.** Paste in the English and Spanish text from [`store-listing.md`](store-listing.md), then add the icon, the feature graphic, and at least two phone screenshots per language.
- [ ] **Data safety.** Answer the form with the table in [`store-listing.md`](store-listing.md).
- [ ] **Exact alarm declaration.** Complete Policy > App content > Exact alarm permission for `USE_EXACT_ALARM`. See [`SPEC.md`](SPEC.md) §15.14.
- [ ] **Content rating.** Complete the questionnaire. Expect an Everyone rating.
- [ ] **Target audience.** Choose adults and teens, not children, so the Families policy doesn't apply.
- [ ] **Other App content forms.** Ads (none), government app (no), financial features (none), health features (none).
- [ ] **Build the bundle.** From `app/`, run:

  ```bash
  /home/sabera/fvm/bin/fvm flutter build appbundle --release --dart-define-from-file=dart_define.json
  ```

  Don't leave off `--dart-define-from-file`. Without it, the bundle builds fine but ships with Google Drive disabled, and nothing in the output tells you.
- [ ] **Upload to Internal Testing.** Create a release, upload `build/app/outputs/bundle/release/app-release.aab`, and add release notes.
- [ ] **Add testers.** Create an email list of testers (at least five, per [`SPEC.md`](SPEC.md) §15.13), share the opt-in link, and let them run it for a week.
- [ ] **Check on a real install.** Install from the Play link, then confirm Drive connects, a timer notification fires with the screen locked, and the widget starts a routine.
