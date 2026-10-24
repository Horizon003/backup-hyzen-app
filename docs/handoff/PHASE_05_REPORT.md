# Phase 05 — export groundwork paired with Phase 04 review

User requested two phases in one go. This checkpoint advances Phase 04 manual perspective editing and Phase 05 export together. It does not mark either whole phase complete. Previous native checks remain unverified; independent reversible review/export work is explicitly isolated on the draft branch.

## Implemented candidate

Existing Save PDF opens a compact export sheet with filename, A4/workspace destination and optional higher-quality raster export (up to 2600px, standard up to 1800px). No unsupported cloud/OCR controls. Cancel does not start export or clear a draft.

Native scan export validates page identities against the current draft, checks a conservative temporary storage budget, reconstructs each page from the immutable imported image with its stored crop/rotate/quad/filter graph, and exports through the existing PDFBox A4 composer. It processes one bitmap at a time; temporary reconstructed JPEGs are removed on success or failure. The existing generic images-to-PDF API retains defaults. High quality increases the decoding bound and JPEG PDF compression quality; it cannot restore detail missing from a legacy or upstream processed image. Decode sampling may produce a raster smaller than the bound.

Existing page-count validation, private workspace atomic import and history commit occur before draft clear. Failed export leaves original files/metadata intact. Successful export still clears draft originals; long-lived editable originals/reopen are not implemented. Existing viewer retains Open/Share/Save to device behaviors; no new saved-success screen claimed.

## Tests and evidence

Adds export sheet cancel, quality argument and failed-export retention widget coverage. Native tests verify actual PDF embedded image resolution differs for a 2400px square original (standard1200/high2400), original bytes unchanged, reopen/page count and retained draft. Native tests require CI execution; not yet passed. Four-corner widget decode wait passed loading but route result assertion failed in run40125145884; route completion is now flushed in the real async zone used to launch it. Recheck pending. Analyzer previously clean; 121 preexisting tests passed alongside the failing added corner test. Do not describe latest suite as green until rerun passes.

## Still incomplete / release gates

Phase04 custom camera, YUV live detection, confidence smoothing, auto/manual capture UI, torch/orientation and physical-device benchmarks. Phase05 magnifier/auto-redetect, Magic/brightness controls, delete undo, durable editable scans after export, export cancellation during processing, detailed page-size controls, saved-success flow and reader floating editing controls. No physical camera quality, memory/performance, low-storage fault injection or full phase acceptance established.

## Rollback

Remove updates_phase_05.json from review assembly to restore prior export behavior. Keep the Phase04 graph-aware store for any already-created quad drafts. Production workflow/main remain unchanged; no release/signing/deployment operation performed.

## Passing combined Dart checkpoint

Source342f10b8d77b4720434006281384f51032cf6c39, run40125517511: analyzer clean (11.3s), all123 tests PASS (38s), screenshot capture PASS. This includes the real-async corner route-result correction, independent corner coordinates at320px and export cancellation/quality/failure retention. Native job120966616621 is queued at this checkpoint; no native export-resolution test pass or complete phase acceptance inferred.
