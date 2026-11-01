# Hyzen 1.3.0 testing release validation — 2026-10-15

- Release APK successfully built with Flutter 3.35.4 / Dart 3.9.2,
  full Temurin JDK 17, Gradle 8.13, AGP 8.13.2, Kotlin 2.3.0,
  Android SDK API 36 and NDK 27.0.12077973.
- All 60 automated Flutter tests passed, including narrow viewer action
  layout, offline lifecycle, signup focus, profile persistence and navigation.
- Analyzer: zero errors; eight informational lint findings remain.
- Package: `com.hyzen.pharmd`, versionName `1.3.0`, versionCode `4`.
- Minimum Android API: 24. Target API: 36.
- APK ZIP integrity passed; APK Signature Scheme v2 verified.
- Certificate SHA-256:
  `3fd902d131ae56d8de4792c9f5953759e2b375e32bcad8f57f7ef5c0ab887f83`
  (same permanent owner certificate as 1.2.0).
- APK SHA-256:
  `cd70197c893d503b65b3d1529819be0f152e8b2bdffe36faa2d8bb13529cc0b7`.

Device acceptance remains pending: install/update on a phone; preview a real
Drive PDF; Save, airplane-mode reopen and delete; signup avatar/photo; external
WhatsApp PDF/DOCX/PPTX intents; dark-mode rendering. Automated and signing
checks do not establish those device results.

Keep the separate private signing backup. It is intentionally excluded from
the shared source ZIP. Never replace the permanent key for future versions.
