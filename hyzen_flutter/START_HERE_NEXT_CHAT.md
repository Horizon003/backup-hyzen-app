# Continue PHARM D WITH HYZEN 1.4.3+11

Read docs/READER_SCANNER_1_4_3.md first. It supersedes the permanent reader bottom
dock and default system-camera-only scanning described below. The compact reader
uses a tap-to-hide top header. Full Google document scanning returns JPEG pages
to the durable draft. Existing public Drive fallback and signing remain unchanged.

Read docs/COMPACT_READER_1_4_2.md first. This supersedes the old floating Sections
drawer with the owner's Home/Study/PDF/Shop/Settings dock. It also replaces the
default Google scanning Activity with a durable page-by-page system-camera flow,
fixes external content-intent routing and compact reader/home/workspace layout.

Read docs/PDF_STUDIO_1_4_1.md for the new scanner, OCR, structured document
writer, AES export, lossless page operations and layered annotation exports.

This is the existing Flutter app com.hyzen.pharmd, with the original signing
identity retained in private GitHub Actions secrets. Never generate a new key.

Read docs/DRIVE_PIPELINE_1_4.md first. Native Drive/PDFium delivery, secure Google
authorization, byte-range reading and resumable private downloads are implemented.
IMPORTANT: the current Google Cloud project still needs Drive API and Android
OAuth client configuration. Until configured, Drive files automatically use the
original online preview and public downloads. Disabled/blocked API errors also
fall back; permission errors still require access. Native saved-file reading
remains available. No owner Google Cloud settings have been changed.
Do not claim live Drive delivery or a successful speed improvement until the
configured API actually returns document bytes.

The updated UI uses a floating bottom dock with a nested Study popover.
Root Home never shows a dead back arrow. Reader
controls include zoom, page navigation and text search; Studio viewer actions
are consolidated under Edit, bookmark and a three-dot menu.
Profile promotions use real shop data, phone validation recovers after edits,
and profile save has a visible confirmation. Technical sign-in error codes and
the student/admin helper sentence have been removed.

Check the latest release workflow and test output for validation evidence.
qa/drive_benchmark_results.json records network measurements, not first rendered
page timing. The same-phone visual benchmark remains blocked by API setup.

Merge/split/page organization preserve original PDF page content. Only explicit
flattened export rasterizes. Scanning, on-device Latin OCR, AES-128 PDF protection
and standard editable annotations are implemented. Rich creation supports basic
formatted blocks; arbitrary Word layout editing and exact PDF-to-Word conversion
are not implemented. Camera scanning still needs physical-device acceptance.
