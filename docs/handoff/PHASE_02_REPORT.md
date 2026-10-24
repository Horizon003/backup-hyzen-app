# Phase 02 — Original assets and motion

State: IN PROGRESS. Owner approved the Gen Z concept ("Okay hain yaay", 2026-10-24). Earlier formal avatar direction is superseded by casual adult university-student styling.

Twelve individual original avatar assets generated with built-in image_gen using the approved concept as reference, visually reviewed and converted to 320x320 WebP. Total asset bytes: 114498 (~112 KiB). See AVATAR_ASSET_MANIFEST.json for descriptions, hashes and provenance. Generated output is not asserted to carry exclusive copyright; no external character/logo reference used.

Review-only integration: new genz_01 through genz_12 IDs prepended to ProfileAvatar choices, retaining all six legacy IDs and their files, existing HTTPS photos and initial fallback. Existing photoUrl='avatar:<id>' profile serialization and pending-write path reused. Picker has 52dp targets, semantic labels/selection and dirty state reset after choosing a new avatar. The change does not alter public profile visibility or Firestore authorization. Photo upload/crop/remove contract is not newly completed; existing upload remains as audited.

New tests decode every selectable avatar, check profile serialization, legacy IDs, HTTPS support and safe local-path fallback. CI result pending. No live cloud-write, physical device, APK size or animation performance acceptance inferred from these tests.

G1 provenance: avatar manifest and existing seven-site design report present; full asset program pending. G2 assets: 12 new candidates prepared; CI/picker acceptance pending. G3 onboarding/state art/icons: in progress. G4 named welcome and reduced motion: pending additional implementation. G5 physical-device performance and release size: blocked by device access; static WebP bytes measured only.

Production assembly remains untouched. phase02_assets is copied only by the isolated review workflow and updates_phase_02.json is applied after phase 01. Rollback: remove the phase 02 overlay from review assembly; existing legacy IDs and files remain intact. Do not delete IDs after any future production persistence.
