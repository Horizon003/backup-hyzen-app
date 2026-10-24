# Phase 05 — scan editing, page review and configurable export

Review branch: work/hyzen-phase-01. Draft PR: https://github.com/Horizon003/pharm-d-with-hyzen/pull/1. Main and the production release workflow are unchanged.

## Implemented

- Four independent perspective corners, convexity/bounds checks and a 2.5x crop loupe opposite the active corner. Crop preview remains based on geometry before tonal filters.
- Original, Colour, Gray, B & W and Enhance presets; brightness and contrast sliders; before/after comparison and tone reset. Enhance is a deterministic contrast/brightness preset, not AI, OCR or automatic shadow removal.
- Native rendering, preview and high-quality export reconstruct the same reversible graph from immutable imported bytes. Tonal values persist through app restart and saved-scan archive/reopen. Earlier graph records default to neutral tone. Undo/Reset remain available.
- Multi-page selection, select-all and batch removal. Last removed batch and original insertion indices persist in the same preferences commit as the surviving page list. Restore works after recreation. Only one removed batch is retained; a later removal replaces it, and explicit discard clears it. Export archives only surviving pages.
- Explicit discard confirmation protects accidental clearing. Opening a saved archive requires no live pages, pending capture or removal history, preventing accidental mixing of different scans.
- Export sheet: editable filename, standard/high quality (1800/2600 px upper bound), A4/US Letter/US Legal, per-page automatic orientation or forced portrait/landscape, and optional margins. Whole image is fitted without cropping; zero margins does not stretch or guarantee full-bleed coverage of a different aspect ratio.
- PDFBox writes one page image at a time with temporary-file spill. Export validates page identities, conservative free space and final PDF page count. History import and editable archive finish before the active draft is cleared. Export-sheet cancellation starts no operation; failed export preserves the draft.
- Separate private saved archives preserve original image bytes and graph/history. Edit saved scan creates a new editable copy and subsequent save produces a new PDF. Older scans without archived originals report unavailability.

## Verification checkpoints

- Latest application code and screenshot-only follow-up080e60028f78a6dd3cb39767e5ac43ab0f2eebc2: run40136098876, clean analysis9.6s and all125 Dart tests PASS38s. Production-font/icon screenshots downloaded, SHA256 verified and visually checked at320px. Both document and controls are visible; crop loupe appears above the mask. These are synthetic-document captures, not camera/device acceptance or golden comparisons.
- Earlier source97cf63f8c3f009416af5d83642e8d3edd53fb445: run40135168896 built app/test APKs and passed28 Android35 instrumentation tests, including tonal pixel changes, original-byte equality and A4/Letter/Legal portrait/landscape PDF bounds.
- Batch-removal source5ca3491d163e4f88e12baea7595aa6efebb6db31: run40135369136 ran29 native tests; the new removal/restart test passed but two older tests still expected immediate permanent deletion. Those expectations conflict with the newly implemented removal Undo. This run is FAILED, not a complete native pass.
- Follow-upaf658df195f42cb4869a3e65e3b3340a432f3a4c updates those tests to verify retention, restart restoration, superseded-batch cleanup and explicit clear; application code is unchanged. Full native rerun is pending. Do not mark the final native gate green until that rerun completes.

## Remaining acceptance work

Direct custom camera preview, YUV live detection, confidence smoothing, auto/manual capture, torch/orientation and physical-device benchmark are still Phase04 work. Phase05 still needs automatic corner re-detection, processing cancellation, dedicated export receipt, reader floating editing controls and device accessibility/memory/low-storage acceptance. No physical camera, live backend or release acceptance is implied by synthetic emulator fixtures.

Retained risks: cross-channel draft operations use separate workers and still need a shared asynchronous ownership strategy; abrupt process death can leave unreferenced staging/preview files; archived originals use extra storage; failed archive cleanup can leave a private orphan. Do not delete arbitrary private files as cleanup. A saved archive does not include the removed-pages undo batch.

## Rollback

All changes are isolated in updates_phase_05.json consumed by the review workflow after earlier overlays. Removing the overlay is only a code rollback; it does not migrate back saved archives or new tonal state. Preserve user originals and archive manifests during any rollback. No merge, deployment or release signing was performed.
