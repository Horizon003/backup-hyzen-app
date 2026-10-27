# PHARM D WITH HYZEN 1.4.3+11

## Documents

The online, offline and imported readers now share a compact top header. A short
page tap hides/shows it; pan, long-press and two-finger gestures do not toggle it.
There is no permanent bottom toolbar. Share and grouped file actions live in the
header. PDFium explicitly enables pinch/pan, with bounded rendering memory.
The existing public Drive fallback explicitly enables WebView pinch zoom and a
zoomable viewport. Google-hosted preview features still depend on Google's UI;
native page thumbnails and text search are available for native/saved PDFs.
Drive API/OAuth configuration is unchanged; no new speed claim is made.

External imports use a streamed SHA-256 identity instead of a new identity for
each open. Saving a Studio copy records that identity. Reopening the same content
uses the saved copy and its tools. Earlier copies with matching names are checked
by content hash once for migration. Deleted copies can be imported again. Source
files, Drive URLs and other apps' files are never edited or deleted.

Announcement and automatic update prompts are suppressed during document launch
handoff, document viewing, PDF Studio and PDF creation. Read-only status is a menu
action, not an overlay. The in-app bell and announcements remain available.

Merge offers Recent files / From device. Merge/extract/organize have sticky Save
actions, a visible saved result and Save As/share destinations. Extract uses a
thumbnail selection grid with Select all and optional ranges; long-press drag
changes output order. Originals retain their text/vectors. In-reader tools
include bookmark, rename, text search, page overview, annotation/signature,
merge, extract, organize, rotate and export. No fake Upload to Cloud action is
shown: this app has no configured private document cloud-upload destination.
PDF-to-DOCX remains text extraction, not exact-layout reconstruction.
Offline-saved academic PDFs expose Edit a copy, Merge, Extract and Organize in
their own menu. The working copy uses the same content identity as device imports,
so repeated editing reuses it. The original academic download stays unchanged.

## Scanner

Scan Document uses Google's full native document-scanner UI (edge detection,
perspective crop, auto/manual capture, cleanup, filters and multi-page review).
Only JPEG output is requested; Hyzen generates the final PDF once after review.
Processed pages are copied into the existing durable private draft. Activity
results are processed even after the previous Flutter callback was lost.
The scanner requires compatible Google Play services and >=1.7 GB total device
RAM. First use may download its module. On unsupported devices the UI keeps
gallery and an explicit basic-camera fallback. Physical-device acceptance is
still required; emulator and mocked bridge tests are not camera hardware tests.

The Hyzen review grid supports long-press drag, rotate, delete, rectangular crop
and colour/grayscale/high-contrast B&W processing on individual/all pages.
Perspective correction is provided inside the native scanner. Post-scan crop is
rectangular. Draft edits process one bounded bitmap at a time and commit only
after success. Filters are committed edits; Original in the adjustment panel
means no additional filter. Failed saves preserve the draft. PDF generation
validates page count before committing history and clearing the draft.

Create PDF back returns inside the app; it does not call SystemNavigator.pop.
Only the Home close confirmation can close the app. Current scanning limits are
30 pages and 40 MB per imported image, with 1800-pixel normalization.

## Appearance

Workspace hero, Open File, Blank PDF, Template and workspace Tools menu removed.
About starts with the existing owner photo/intro and real configured social links.
Settings has immediate palette swatches, light/dark/system and an account card.
Admin has real order/message metrics, compact quick actions and grouped controls.
Palette colours now drive chips, banner surfaces, icon badges, dock and primary
accents. Fixed illustrations and semantic status/category colours retain their
asset/meaning. Transitions respect reduced motion; refresh rate/FPS depends on
the device and workload and is not guaranteed at 60–90 FPS.

Original package and private release signing identity are retained. Build through
the existing authorized GitHub workflow; signing credentials are never packaged
with source. See CI artifacts for actual analyze/test/install results.
