# PHARM D WITH HYZEN — A-to-Z Traceability Report

**Release target:** 1.5.3+12  
**Branch:** `work/professional-redesign-1.5`  
**Package:** `com.hyzen.pharmd`  
**Framework:** Flutter 3.35.4 / Dart 3.9.2  
**Report date:** 2026-10-31

## Executive status

The requested professional redesign and feature expansion is implemented across the study home, profile/settings, scanner, Office Workspace, viewer, search, download, mascot, and admin-managed promotion flows. The final regression suite completed with **88 tests passing**. The owner-signed APK is produced through the repository GitHub Actions workflow because the private production keystore is intentionally not stored in the sandbox.

## A-to-Z feature traceability

| Area | Requirement / outcome | Main implementation | Status |
|---|---|---|---|
| A | App-wide graphite visual hierarchy | `lib/core/theme/tokens.dart`, shared UI kit, surfaces and compact spacing | Complete |
| B | Compact cards, typography and study density | Home/study widgets, resource tiles, typography and spacing tokens | Complete |
| C | CamScanner-style capture flow | `lib/features/pdf_studio/presentation/scan_pdf_screen.dart`, native CameraX bridge | Complete; physical camera acceptance remains device-specific |
| D | Durable scan draft and page review | scan draft persistence, `scan_page_editor.dart`, `ScanReviewPanel` | Complete |
| E | Eight-handle crop editor | four corners plus four midpoint handles with persistence | Complete |
| F | File/document visual identity | document icons, Office Workspace history and category labels | Complete |
| G | Graphite/grey palette with accent restraint | theme tokens and palette usage | Complete |
| H | Home quick actions and compact continuous study | compact home cards, one-line truncation and dense resource presentation | Complete |
| I | Interactive mascot system | `mascot_motion.dart`, `rive_mascot.dart`, semantic states and PNG fallback | Complete; final proprietary `.riv` art asset can be supplied later without changing screen APIs |
| J | Mascot states across app flow | welcome, onboarding, loading, downloading, studying, success and error states | Complete |
| K | Live Preview chrome | `reader_chrome.dart`: standalone close control and Share/Download/More pill | Complete |
| L | Local OCR persistence | `features/search/data/ocr_index.dart`, SharedPreferences-backed page index | Complete |
| M | Merge PDFs | `StudioToolsScreen`, `StudioPdfEngine.compose` | Complete |
| N | Native PDF viewer and offline reading | `features/viewer/offline_pdf.dart`, pdfrx | Complete |
| O | Office Workspace rename and history | `pdf_studio_repository.dart`, viewer route and recent file cards | Complete |
| P | Page-aware Super Search | OCR result snippets include page number and route query | Complete |
| Q | Query result exact-page navigation | `/pdf-studio/viewer/:fileId?page=N`, `OfflinePdf.initialPage` | Complete |
| R | Resumable downloads | `file_store_io.dart`: `.part` file, resume journal, HTTP Range and If-Range | Complete |
| S | Split PDF by range | page range parser and compose workflow | Complete |
| T | Extract selected pages | page selection grid and selected-page compose workflow | Complete |
| U | Unified action drawer over preview | rounded root modal sheet via `showReaderActions` | Complete |
| V | Viewer search, zoom and pages tools | `ReaderTools` callbacks and pdfrx controller | Complete |
| W | Web/device-safe fallbacks | platform file store stubs, online preview fallback and defensive parsing | Complete |
| X | Admin content and account controls | existing admin repository plus settings field integration | Complete |
| Y | Three admin-managed account ads | `SiteSettings.accountAds`, admin settings slots 1–3, 16:9 profile carousel | Complete |
| Z | Settings/Profile final hierarchy | tall slate account card, searchable settings, Personal/Academic/Security labels | Complete |

## Admin advertisement contract

The admin settings document `pw_settings.value` supports these fields for each slot `1`, `2`, and `3`:

- `accountAd{n}Enabled`
- `accountAd{n}Image`
- `accountAd{n}Title`
- `accountAd{n}Subtitle`
- `accountAd{n}Route`

Only enabled slots with an image URL and title are rendered. The student profile carousel enforces a 16:9 layout and keeps catalog/offline promotion fallback content when no admin ad is configured.

## Verification matrix

| Check | Result |
|---|---|
| `flutter analyze` with Flutter 3.35.4 | No new issues from this phase; one pre-existing `use_build_context_synchronously` info remains in `studio_export_sheet.dart:198` |
| Full `flutter test` suite | **88 passed** |
| OCR repository regression test | Passed after provider initialization hardening |
| Git diff whitespace check | Passed |
| Signed release configuration | CI workflow restores owner key from GitHub secrets; no replacement key generated |
| Install smoke | Executed by the release workflow on Android API 35 emulator after the build job succeeds |
| Physical scanner acceptance | Not executable in this sandbox; requires a representative Android device/camera |
| Existing-user upgrade test | Not executable without a device containing the previous installed release |

## Release procedure

The final release workflow is `.github/workflows/android-apk.yml`. It uses Flutter 3.35.4, restores the owner production keystore from GitHub secrets, runs analyzer and tests, builds `flutter build apk --release`, computes SHA-256, uploads `PharmD_With_Hyzen_1.5.3_signed`, and performs an Android API 35 install/launch smoke test.

## Known limitations and honest boundaries

The sandbox does not contain the private production keystore, so a locally generated APK must not be presented as an owner-signed update. Camera autofocus, physical lighting, crop quality, and upgrade installation must be checked on a real Android device. The Rive wrapper is production-ready and state-driven; the final art-specific `.riv` state-machine asset remains replaceable through the wrapper without changing screen integration.
