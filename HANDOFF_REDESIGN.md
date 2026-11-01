# Redesign 1.5 – handoff (branch `redesign-1.5`)

This branch contains the **fully expanded Flutter project** in `hyzen_flutter/`
(= `PharmD_With_Hyzen_Source_1.3.3.zip` + root corrections + `updates_1_4_0..3.json`
already applied). Work directly in `hyzen_flutter/`; no unzip/patch step needed.

Design spec from the owner: `hyzen_flutter/design_spec/` (read `START_HERE_FOR_CLAUDE.md`,
`DECISION_LEDGER_Q01_Q33.md`, `HYZEN_CLAUDE_SCREEN_BY_SCREEN_DESIGN.md`).

## Goals
1. New design system: Deep Teal #087F76, Slate #1A3440, bg #F3F8F7, pale teal #DDEDEA,
   muted #507379, Manrope, 8pt, light/dark/system. Purple removed as brand.
2. Four bottom tabs only: Home / Study / PDF Studio / Shop. Profile+Settings via top-right avatar.
3. Scanner rebuilt: custom in-app camera (CameraX) with live document edge detection
   (pure-Kotlin `ScanVision.kt`), auto-capture when stable, perspective warp,
   4-corner crop editor with magnifier, filters Original/Magic/Gray/B&W + brightness/contrast.

## Progress log
See `REDESIGN_PROGRESS.md` (updated with every push).

## Build
`cd hyzen_flutter && flutter pub get && flutter analyze && flutter test`.
Signed release still uses the existing workflow on `main`; to release, either merge this
branch's `hyzen_flutter/` changes into a new `updates_1_5_0.json` or adapt the workflow.
