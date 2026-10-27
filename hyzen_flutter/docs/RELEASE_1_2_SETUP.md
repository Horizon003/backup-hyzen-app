# Hyzen 1.2.0 (3) — release and owner setup

## Preview and offline notes

The old file store rejected every non-PDF download and always used a `.pdf`
extension. The backend actually contains PDF, JPG/PNG, PPTX/PPT and Word notes.
The old viewer also depended on Drive's embedded page; unrelated HTTP resource
errors could replace that page with an error screen.

The native viewer now downloads and validates the document first. PDF notes
render with PDFium; images use a zoomable image view. Known Drive Office titles
try Google's PDF export first, then fall back to the original file. The tested
HLB system.pptx link exported to a 16-page PDF. For original Office files that
cannot export, a bounded offline text reading view supports PPTX/DOCX/XLSX and
legacy PPT. It does not reproduce Office charts, animations or exact layout.
Graphics-only Office pages need the original online preview or a PDF copy.
Legacy `.doc` and unsupported formats must be converted to PDF by the owner.

Saved copies are app-private in `offline_docs`, indexed in Hive. No broad Android
storage permission is needed. Save Offline is explicit; temporary preview files
are removed when the viewer closes. Partial files are never marked saved.
Normal documents are capped at 250 MB; raw Office reading is capped at 50 MB.
Device export uses Android's system save-location picker.

## Permanent signing — KEEP THE OWNER BACKUP

The private owner signing backup contains `android/signing/hyzen-release.jks`
and `android/key.properties`. It is deliberately separate from the normal
source ZIP. Restore those two paths into this project before a release build.
The key alias is `hyzen-release`; passwords are in the private properties file,
not in this document or public source control.

- Package ID stays `com.hyzen.pharmd`.
- This release is 1.2.0, versionCode 3.
- Use this same signing identity for ALL future production APK/AAB builds.
- Increase versionCode on every published update.
- Release builds fail rather than silently falling back to a debug key.
- Keep at least two encrypted offline backups. Losing the private key can
  prevent updating sideloaded installations.

The previous 1.1.0 testing APK used a DIFFERENT development signing identity.
Android will reject an in-place update from that APK to this production key.
Back up anything important first; the initial transition may require removing
the old test build. Uninstalling deletes its local notes/settings. Once this
permanent-signed base is installed, future same-key updates can retain app data.
Do not tell users to uninstall for ordinary future releases.

## Non-Play-Store in-app updater

Implemented in `lib/features/updates/` and Android `HyzenUpdater.kt`.
Update checks run on authenticated shell entry and manually from Settings.
The admin Settings form writes these fields into the existing `pw_settings`
value, under the existing server-enforced admin permissions:

```json
{
  "androidLatestVersionCode": 4,
  "androidVersionName": "1.2.1",
  "androidMinVersionCode": 3,
  "androidApkUrl": "https://YOUR-HTTPS-HOST/Hyzen-1.2.1.apk",
  "androidSha256": "REPLACE-WITH-64-CHARACTER-SHA256-OF-THE-EXACT-APK",
  "androidReleaseNotes": "Describe the changes here.",
  "androidForceUpdate": false
}
```

The placeholder is deliberately invalid: no update is advertised until the
owner supplies a real signed APK URL and checksum. No release has been published
and no production settings/rules were changed as part of this work.

For a future release:

1. Restore the owner key; increment versionCode; run analyze/tests; build APK.
2. Verify the APK signature and compute `sha256sum` for that exact APK.
3. Host the raw APK at a stable HTTPS download URL (not a Drive preview page).
4. Fill the admin fields only after the file is accessible. Test an optional
   update first; use minimum-version/forced updates carefully.
5. Test download/cancel, wrong checksum rejection, wrong signature rejection,
   permission return, installation and local-data retention on Android.

The native updater limits HTTPS redirects and package size, requires disk space,
validates SHA-256, checks package ID, expected/higher versionCode and matching
signing certificate, and hands the APK to Android's installer using FileProvider.
Android may ask to enable "Install unknown apps" for Hyzen and confirm Update.
Return to the dialog and tap Install update after granting permission.
Silent installation is not promised. Google Play integration can replace this
native channel later; review/remove sideload permissions for a Play variant.

## Build

Flutter 3.35.4 / Dart 3.9.2, JDK 17 with javac, Android SDK/NDK as pinned by
Flutter, Gradle 8.13 / AGP 8.13.2 / Kotlin 2.3.0. Run:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Configure local SDK locations in `android/local.properties` or let Flutter do it.
Do not commit local.properties, key.properties, signing files, generated caches,
proxy settings, or SDKs. Optional CI output isolation:
`./gradlew -PhyzenBuildDirectory=/absolute/temporary/build assembleRelease`.

## Remaining external setup

Existing proposed student-profile Firestore rules still need owner review and
deployment. Closed-app FCM push is not configured. Private/deleted/quota-blocked
Drive links cannot be repaired by a client app; fix file sharing at its source.
