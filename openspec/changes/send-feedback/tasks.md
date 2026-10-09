## 1. The draft

- [x] 1.1 Add unit tests for the `mailto:` link: address, subject, body order, details, and `%20` for spaces, and verify they fail
- [x] 1.2 Add `feedback_email.dart` and verify 1.1 passes

## 2. Settings row

- [x] 2.1 Add widget tests: selecting Send feedback launches a `mailto:` link to the feedback address, and a failed launch shows the address with Copy; verify they fail
- [x] 2.2 Add the launcher provider, the row, and the strings in both ARB files, and verify 2.1 passes

## 3. Verification

- [x] 3.1 Run `flutter analyze --fatal-infos` and `flutter test` from `app/`
- [ ] 3.2 Check on the Pixel that the draft opens in the email app
