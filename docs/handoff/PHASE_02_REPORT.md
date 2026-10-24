# Phase 02 — Original assets and motion

State: IN PROGRESS. Owner approved the Gen Z concept ("Okay hain yaay", 2026-10-24). Earlier formal avatar direction is superseded by casual adult university-student styling.

Twelve individual original avatar assets generated with built-in image_gen using the approved concept as reference, visually reviewed and converted to 320x320 WebP. Total asset bytes: 114498 (~112 KiB). See AVATAR_ASSET_MANIFEST.json for descriptions, hashes and provenance. Generated output is not asserted to carry exclusive copyright; no external character/logo reference used.

Review-only integration: new genz_01 through genz_12 IDs prepended to ProfileAvatar choices, retaining all six legacy IDs and their files, existing HTTPS photos and initial fallback. Existing photoUrl='avatar:<id>' profile serialization and pending-write path reused. Picker has 52dp targets, semantic labels/selection and dirty state reset after choosing a new avatar. The change does not alter public profile visibility or Firestore authorization. Photo upload/crop/remove contract is not newly completed; existing upload remains as audited.

New tests decode every selectable avatar, check profile serialization, legacy IDs, HTTPS support and safe local-path fallback. First CI analyzed cleanly; 95 tests passed and one new test failed because it assumed legacy images were square. Restricting that dimension assertion to the 12 new assets; rerun pending. No live cloud-write, physical device, APK size or animation performance acceptance inferred from these tests.

G1 provenance: avatar manifest and existing seven-site design report present; full asset program pending. G2 assets: 12 new candidates prepared; CI/picker acceptance pending. G3 onboarding/state art/icons: in progress. G4 named welcome and reduced motion: pending additional implementation. G5 physical-device performance and release size: blocked by device access; static WebP bytes measured only.

Production assembly remains untouched. phase02_assets is copied only by the isolated review workflow and updates_phase_02.json is applied after phase 01. Rollback: remove the phase 02 overlay from review assembly; existing legacy IDs and files remain intact. Do not delete IDs after any future production persistence.

Five transparent 640px WebP illustrations added (254938 bytes): three adult Gen Z onboarding/study scenes, search and empty-folder art. HyzenArt maps Home to the new welcome scene, retains original static files as error fallback, and uses a 450ms nonblocking fade/14px entrance, disabled under reduced motion. PDF workspace empty state uses new folder art. Banner copy and artwork use separate columns to remove overlap. Added reduced-motion and mid-animation disposal/input tests; capture now includes Edit Profile. Total new optimized visual assets: 369436 bytes. APK/device benchmarks remain NOT RUN. Custom icon family, detailed upload crop/remove flow, complete error/download state animation and session-once welcome semantics remain unfinished; phase 02 is not accepted.

## Follow-up integration and observed QA

Four original vector dock symbols authored in Flutter CustomPainter, 24-unit grid / 1.8-unit stroke, inherit theme colors and existing destination semantics. Onboarding first page now uses new Gen Z art and theme surfaces; Next/indicator transitions respect reduced motion. Home greeting suppresses email-shaped display names and uses generic wording when no name is available. A session-once greeting policy is still unfinished.

CI run 40069770297 at d25e6fb07f4881bf3f239f08eb71cd4d06bf29cd: analyzer clean, 98 tests PASS, capture PASS. Artifact 12550693046 SHA256 0ce5aac0e9f746804228c133f20449358b05a465bb9d814a13acbd2744fbb828 verified after download. Light Edit Profile and light Study screenshots inspected: all 12 new avatars visible, Study banner copy no longer overlaps art. Fixture profiles are test data.

Subsequent changes add custom dock glyphs/safe welcome and restrict selectable choices to Gen Z IDs; all six legacy IDs still render and are covered by decode/serialization tests. Final validation at 32f7edfd490aa213c9dc3545065e37c8f395bccb: CI run 40070062288 PASS (analysis, 98 tests and screenshot capture). No physical device or live cloud validation. Phase remains IN PROGRESS: full original icon categories, crop/remove photo controls, full download/error motion, once-per-session welcome, package/frame-time and TalkBack checks remain open. Do not advance dependent phases under a false phase-02 completion claim.

Final CI: https://github.com/Horizon003/pharm-d-with-hyzen/actions/runs/40070062288 . Earlier formal concept and original legacy picker candidates are superseded by the approved Gen Z direction. Legacy images are rendering compatibility only, absent from selectable choices.

Final artifact 12550776815 SHA256 cd71a4a424b804c39d6db8cacee9de63133b25e54dd37edeb0f4a90e20153091 verified. Final light Edit Profile and dark Home captures reviewed: 12 Gen Z options only, new vector dock, new art and legible greeting.
