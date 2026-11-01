# Hyzen 1.2.0 (3) — validation

15 October 2026. Existing project continued; package ID remains `com.hyzen.pharmd`.

## Verified

- Flutter analyzer: no issues found.
- Normal suite: **59 tests passed** (52 existing + 7 added).
- Both-theme navigation/visual capture run: **10 tests passed**, with 14 fixture
  screenshots in `qa/`. Home, Study and Downloads were inspected. Screenshots
  are Flutter test renders with fictional fixture accounts, not phone proof.
- Web release compilation and Wasm dry-run passed during implementation.
- Read-only live backend inspection found the original PDF-only assumption was
  wrong: notes include PDF, JPEG, PPTX/PPT, Word and other file types.
- Real public Drive PDF downloaded and inspected; real JPEG downloaded and
  identified as a valid 1500x1500 image.
- Actual backend `HLB system.pptx` URL exported to a valid **16-page PDF**.
- Release Android build succeeded: Gradle **BUILD SUCCESSFUL in 4m 37s**.
- Native updater and file bridge compiled. Android release lint completed.
- APK ZIP/CRC and Android signature verification passed.
- Version 1.2.0, versionCode 3, minSdk 24, target/compile SDK 36, label Hyzen.
- ARM64, ARMv7 and x86_64 each contain AOT `libapp.so` and Flutter engine.
- Package is not debuggable. Signed with the new permanent owner production key.
- APK SHA-256: `c6b490a3329c9fd856a493c412809e19ab3612c74c0b2ff2c7ebd5e88c0c7c86`.
- Signing certificate SHA-256:
  `3fd902d131ae56d8de4792c9f5953759e2b375e32bcad8f57f7ef5c0ab887f83`.
- Signing certificate SHA-1:
  `a08e2cbe5321b439cc74e40914cc570b8b9986b6`.

## Regression coverage added

Byte-based PDF/Office/image recognition; Office slide order and Word text;
Drive Office-to-PDF URL and resource-key retention; invalid/insecure update
manifests and integer-valued Firestore numeric fields; local file finalization,
offline byte reopening, deletion, HTML/unsupported-file rejection and cancel
cleanup. Existing tests cover navigation, keyboard focus, admin guards,
professional filtering, profile persistence and download lifecycle races.

## Acceptance boundaries

No production login/signup, admin settings writes, profile-rules deployment or
update publication was performed. Real Drive reads above verify public bytes
and exports; they do not prove all 2330 notes or private/quota-limited files.

Physical Android phone testing and a hosted future-version update remain owner
acceptance tasks. Raw Office fallback is a text reading view, not original
slide/chart rendering; prefer the PDF export for exact layout. FCM push and
student-profile Firestore rules still require owner backend setup.

Read `DEVICE_ACCEPTANCE.md` for the final emulator install/start outcome and
its limits. Do not treat a release build/signature check as an install test.
Raw evidence is in `docs/validation/1.2.0/`.

## Signing / Firebase setup

The current 1.1.0 development key differs from the new production key. Back up
important local data before the first production-base installation; uninstall
may be required for that one-time transition. All subsequent releases must use
the same owner key. For Firebase Android app registration, add the production
certificate fingerprints above where SHA restrictions, Google sign-in or App
Check require them. No Firebase console configuration was changed here.
