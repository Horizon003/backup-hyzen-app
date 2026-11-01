# Hyzen 1.3.1 working source (versionCode 5)

> Historical 1.3.0 notes below are superseded by the unbuilt 1.3.1+5 working
> revision. The current edits are source-only until Flutter/Android build tools
> are restored.

Continued from 1.2.0. A signed testing APK has now been built. It has not been
installed or acceptance-tested on a physical phone. See `VALIDATION_1_3.md`.
Keep the separate 1.2.0 private production signing backup safe. Build 1.3.0
with that same key so the APK can update 1.2.0 without wiping local data.

## Changes

- Corrected the preview action overlap. A global Material FilledButton minimum
  width was infinite inside Row, forcing the explanatory text into a single
  character column. Buttons now use zero minimum width and 54dp height; the
  preview has a compact Save action.
- Saved notes open from the local file by default. Saving an already loaded
  note copies its validated preview file into persistent offline storage,
  avoiding a second network transfer. Downloads still show status, date,
  search, category and delete controls.
- New signup success redirect and first-session "Welcome to Hyzen" greeting.
- Optional signup gallery photo and six generated student avatars, also
  selectable in Edit Profile. Avatar identifiers persist in the existing
  `photoUrl` field; no extra backend field. Gallery photo uses the existing
  Cloudinary preset.
- New welcome illustration/layout, original purple Hyzen book/pharmacy mark,
  brighter Home search border, richer dark palette.
- Android ACTION_VIEW / ACTION_SEND handlers for PDF, images, PPT/PPTX,
  DOCX and XLSX: import the content URI to app-private storage, show it in
  the native reader after sign-in, and record it in the Downloads reader
  history. Users can export or delete imported local copies. Imported
  Office formats use a text-reading fallback if exact PDF layout is absent.

## Checks performed

- Flutter 3.35.4/Dart 3.9.2 available locally; `dart format` parsed all 81
  source files successfully.
- AndroidManifest.xml and the launcher vector parsed as valid XML.
- Six avatar crops and the new illustration were created as local assets.
- The existing APK is 1.2.0 and was not changed or renamed as 1.3.0.

## Previous build blocker (resolved)

Online package resolution, Android SDK installation, full JDK 17 setup and
release compilation succeeded on 2026-10-15. Two missing `importPreview`
implementations and the navigation test's history-box initialization were
fixed. All 60 Flutter tests pass. Analyzer has no errors and retains eight
informational lint findings. APK signature and integrity checks pass.
Phone rendering, installation, actual public Drive files and WhatsApp chooser
behavior still need device acceptance checks.

## Next build in an authorized Android build environment

1. Extract this source and the existing **private** owner signing backup;
   restore `android/signing/hyzen-release.jks` and `android/key.properties`.
2. Install Flutter 3.35.4, Android SDK API 36/build tools, JDK 17 and locked
   packages with `flutter pub get`.
3. Run `flutter analyze`, `flutter test`, and `flutter build apk --release`.
4. On a phone, check narrow preview, public PDF and PPTX opening, Save,
   airplane-mode reopening, Downloads deletion, signup/photo/avatars, light
   and dark screens, and WhatsApp/Open-with intents for PDF and DOCX/PPTX.
5. Verify the resulting APK package `com.hyzen.pharmd`, versionCode 4,
   signing certificate SHA-256
   `3fd902d131ae56d8de4792c9f5953759e2b375e32bcad8f57f7ef5c0ab887f83`
   before distributing. Do not regenerate the key.

Android chooser presence depends on the sending app's MIME type and URI grant.
Legacy `.doc` files cannot be faithfully read by the current Office parser;
convert them to PDF or DOCX. Office fallback extracts text, not exact layout.

## Artwork provenance

The six avatar portraits and the student plus robot welcome illustration were
generated specifically for this project with the built-in image generator.
Avatar direction: three male and three female South Asian student portraits,
consistent warm 3D style, purple attire, individual circular crop. Welcome
direction: student pharmacist reading beside a small study robot, mint and blush
abstract backdrop, no embedded UI text. The launcher SVG mark was drawn in
source as an original book and medical cross combination after reviewing
education-app logo references. No third-party icon asset was copied.

## 1.3.1+5 changes in progress

- Drive's online preview is mounted immediately; the previous automatic
  full-file temporary download before rendering was removed. Offline transfer
  now starts only after the learner taps Save offline.
- Full-screen notices are suppressed while an in-app or externally imported
  document viewer is active.
- Home header no longer exposes a stale back arrow, and tapping its search
  field opens Search with keyboard focus.
- Search filter chips use compact density and narrower gaps.
- Phase 1 added a dedicated PDF Studio navigation branch/dashboard.
- Phase 2 added a private `pdf_studio_history_v1` Hive store, internal workspace
  and sidecar directories, guarded file copy/delete, and history CRUD (rename,
  star, recent-open page). External files can be copied from Downloads history
  into Studio and reopened there. Merge/split, annotations, text editing and
  universal exports remain later phases.
- Build status: no Flutter, Dart, Gradle, or Android SDK executable is
  available in this workspace; no 1.3.1+5 APK has been built or tested here.
