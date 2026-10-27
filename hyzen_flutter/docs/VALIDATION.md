# Validation — version 1.1.0+2

14 October 2026

- Flutter 3.35.4 / Dart 3.9.2.
- Analyzer: no issues found.
- Normal regression suite: 52 tests passed.
- Both-theme visual capture: 14 fixture screenshots, plus one passing capture
  test. Home, Study and completed Profile inspected. Fixture content and test
  account data only; these are Flutter renders, not device screenshots.
- Web release compilation and Wasm dry-run passed.
- Public read-only integration: retrieved website credits and the founder
  photo; a real public Drive sample downloaded as a PDF 1.7 with four pages.
  This checks a public download endpoint, not native WebView/Drive login.

## Verified Android release package

- Build: `assembleRelease` succeeded with R8/resource shrinking and Dart AOT.
- Gradle 8.13, AGP 8.13.2, Kotlin 2.3.0, JDK 17, API 36,
  NDK 27.0.12077973 and CMake 3.22.1.
- Package: `com.hyzen.pharmd`, version **1.1.0**, version code **2**.
- Label: **PHARM D WITH HYZEN**. Release package is not debuggable.
- ABI coverage: ARM64, ARMv7 and x86_64; AOT `libapp.so` confirmed for each.
- APK signature verification and ZIP CRC checks passed. Development key only.
- File: `PHARM_D_WITH_HYZEN_Android_Release.apk`
- Size: 76,184,504 bytes (72.7 MiB).
- SHA-256: `3da8ff088553e9b86ce2d4f9f5977c5eb700027ff7e620e3d3d710beb46aec8c`

Native toolchain versions were aligned with the pinned plugin sources.
[Android compatibility notes](https://developer.android.com/build/releases/agp-8-13-0-release-notes)
identify AGP 8.13.2's Kotlin 2.3 support. Raw check outputs are retained in
`docs/validation/latest/`. Build-environment paths/proxy settings are excluded
from the owner source ZIP.

## Tests cover

Registration/domain logic; CSV/JSON/XLSX import, website aliases and lecture
hierarchy; duplicate content links; hidden ancestors; duplicate download saves,
delete/clear races, interruption and validation; Drive confirmation host/file-ID
checks and resource keys; durable account-isolated profile cache; university and
photo persistence; keyboard focus during typing/resize/scroll; Back navigation
and notice dismissal; professional filtering and changes; completed profile
without repeat prompts; finite remote image decode; dirty admin form retries;
student admin guard; every student tab/library route; information/shop routes;
all main admin screens; small phone with larger text; duplicate stock processing; product option structure and unlimited stock preservation.

## Acceptance still required

No physical Android device was available. Verify system Back and keyboard,
WebView, public/private file errors, cancel/export/offline PDF, photo picker,
real account login/profile sync and performance on a phone. No device FPS or
startup timing is claimed. No production admin writes or rule deployment were
performed. Student rules must be merged for cross-device profile sync;
closed-app push needs FCM setup. Development signing only.
