# Phase 04 — draft integrity groundwork, not camera acceptance

## Scope and ordering

The preceding native-preview test compile failure was caused by PdfDocument not implementing Closeable; explicit try/finally closing fixes the fixture. Phase 03 rerun 40083886627 at 41b69d583e5978f6f5d232d83fbb319562f9b365 has passing analyzer/widget/capture jobs; native job pending at this checkpoint. This Phase 04 subset is isolated review work under START_HERE's safe-independent-work allowance. It does not activate a new camera, waive a failing test, or pass the phase's physical-device gate.

## Actual changes

ScanDraftStore is extracted from HyzenCameraCapture into its own Kotlin file. Incoming bytes are copied unchanged into a private original file; the 1800px draft preview remains separately generated. Basic-camera captures and imported images are distinguished from ML Kit processed output and legacy processed drafts. Full-resolution refers only to the incoming file: no lost upstream pixels are invented.

Crop/rotate geometry, the selected filter and the last 20 state snapshots persist with page paths in one SharedPreferences commit. Each edit re-renders from the immutable input, avoiding cumulative JPEG/filter degradation. Original filter restores color while retaining geometry; Reset restores imported geometry and color. Undo survives recreation. Page-grid history menu exposes Undo and Reset. Editor preview uses an unfiltered geometric render and the actual selected filter, preventing a second stacked filter in preview.

Original copies use fsync before metadata publication. Failed imports/edits delete only newly staged files. Successful basic capture clears the pending-capture pointer with the appended page metadata, avoiding duplicate recovery across process death. A malformed capture is detached from automatic recovery without deleting earlier pages. Removing a page deletes its own original after metadata commit; explicit Clear removes files only inside the private draft directory. Source gallery files remain unchanged.

Existing external camera, ML Kit, gallery routes, PDF generation and saved-download keys remain. No CAMERA permission, dependency or direct camera preview added.

## Verification

New native cases cover exact original bytes and 2400x3200 dimensions, reversible crop/rotation/filter/reset after recreation, five-page capture preservation, legacy migration provenance, reversed-crop rejection and failed-import rollback. Existing native regressions remain. New widget test checks Undo/Reset channel calls use the latest returned page identity. CI results pending; synthetic emulator tests cannot establish camera quality/performance.

## Gates and limitations

G1 physical device and baseline benchmarks: BLOCKED (no device).
G2 camera permissions/torch/orientation: NOT IMPLEMENTED for custom camera.
G3 four-corner detection and perspective correction: NOT IMPLEMENTED.
G4 five-page lifecycle: automated coverage added, execution pending; physical capture pending.
G5 existing fallback remains available; no quality claims.

This is not a complete Phase 04 scanner. Durable originals currently belong to the draft lifecycle. Existing successful PDF save explicitly clears the draft; long-lived editable document originals and high-resolution export are Phase 05 work, not delivered here. Camera/process kill tests are simulated store recreation, not OS/device kills. SharedPreferences remains the inherited single-process store; multi-channel concurrency and fault-injected storage failures need further hardening before release.

## Rollback

Remove updates_phase_04.json from review assembly before any user-data rollout. On devices that have used this overlay, preview paths remain compatible with old code, but old code does not understand the original/transform metadata and can orphan originals. Do not downgrade a live in-progress draft; export/complete it first or retain the new store while rolling back UI. Production assembly does not consume any review overlays. No merge or deployment performed.
