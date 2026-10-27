# Validation — PHARM D WITH HYZEN 1.3.3+7

Build date: 16 October 2026. Private repository: `Horizon003/pharm-d-with-hyzen`.
GitHub Actions run: `38841171153`, source/build commit `54b942423086b7e301baf1fa53bc96acebf3bb3b`.
Toolchain: Flutter 3.35.4, Dart 3.9.2, JDK 17, Gradle 8.13, NDK 27.0.12077973.

## Verified

- `flutter pub get`: success.
- `flutter analyze --no-pub`: no issues found.
- `flutter test --no-pub --reporter expanded`: 62 tests pass.
- `flutter build apk --release --no-pub`: success; signed APK is 83,589,939 bytes.
- Manifest: package `com.hyzen.pharmd`, version `1.3.3`, build number `7`, display label `PHARM D WITH HYZEN`.
- Native ABIs: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- APK SHA256: `813ab4af12eea5015f393cd82a1745316cbf4f4a7e5d67bf806e4807d71c9f2b`.
- Public signing certificate SHA256: `3fd902d131ae56d8de4792c9f5953759e2b375e32bcad8f57f7ef5c0ab887f83`; matches the original production keystore and older 1.3.0 APK.
- Downloaded artifact checksum and ZIP integrity match the GitHub artifact.
- Original signing key and passwords are configured as encrypted GitHub Actions secrets in the private repository and excluded from the source ZIP.

## Android installation

The Android API 35 x86_64 emulator install/launch smoke test passed. `adb install -r` returned `Success`, the launcher intent ran, and the app process remained alive after eight seconds. Captured logcat contained no `FATAL EXCEPTION` or unhandled Flutter errors. This is a fresh-install/startup check, not a full signed-in phone acceptance test or an upgrade test with existing user data.

## Fixes made while compiling

- Imported the router provider in the notification host.
- Removed invalid `mainAxisSize` arguments from `Wrap` in PDF tools.
- Replaced an unavailable transition class with the supported transition builder.
- Fixed Kotlin image export filename padding (`padStart`).
- Resolved all analyzer diagnostics, including the signup photo async context guard.

## Test scope and remaining acceptance

Automated tests cover navigation, registration, back handling, Drive URL/type resolution, offline download lifecycle and disk reopening, update-config validation, content refresh, bulk import, and PDF Studio workspace metadata. They do not establish a full real-phone UI or backend acceptance result.

Real documents on a physical device still need Drive streaming/preview, offline save/open, external Office/PDF intents, all native PDF Studio operations and both themes checked. Page composition and flattened annotations rasterize pages and lose selectable text/interactive fields. OCR, rich DOCX editing, layout-preserving conversion, vector-preserving manipulation and advanced encryption/compression remain incomplete; see the implementation status.
