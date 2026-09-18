## 1. Pin the header

- [x] 1.1 Add a widget test that drags the running screen's scrollable and asserts the back
      button's rect is unchanged and stays a `SoftCircleButton`, and verify it fails against the
      current single-`ListView` layout
- [x] 1.2 Restructure `_Running` into a `Column` with the fixed header above an
      `Expanded(ListView(...))`, moving the spacing so the unscrolled layout doesn't shift, and
      verify 1.1 passes
- [x] 1.3 Check `_Summary` for a circular control that scrolls under the edge; none exists, so leave
      it unchanged

## 2. Verification

- [x] 2.1 Run `/home/sabera/fvm/bin/fvm flutter analyze --fatal-infos` from `app/` and verify no
      issues
- [x] 2.2 Run `/home/sabera/fvm/bin/fvm flutter test` from `app/` and verify the suite passes at or
      above the current 593 baseline
