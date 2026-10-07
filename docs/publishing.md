# Publishing playbook

This is a placeholder. The full App Store and Play Store submission playbook ships in **M6**, per [`SPEC.md`](SPEC.md) §12.

It'll cover the checklist in §15.13, developer account setup (§15.2), privacy manifests (§15.4), and store metadata (§15.9–15.11). Until then, treat §15 of the spec as the source of truth.

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
