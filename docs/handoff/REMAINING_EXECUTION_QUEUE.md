# Remaining execution queue

Draft PR1: https://github.com/Horizon003/pharm-d-with-hyzen/pull/1. Latest application source5322932e1a5ddb42597204f6d9747bd7832d01f1; test-only screenshot follow-up080e60028f78a6dd3cb39767e5ac43ab0f2eebc2. Main and production are unchanged.

1. Complete screenshot follow-up and native verification for the combined editing/export/page-management batch. The earlier52edfc98 checkpoint passed124 Dart and26 Android instrumentation tests; do not describe its native results as pending. New major batch has additional tests.
2. Phase04 direct custom camera preview, YUV detection, temporal confidence, auto/manual capture, torch/orientation and multi-page strip remain unimplemented. Existing MLKit and basic-camera fallbacks are retained. Real Android camera/performance acceptance is still required.
3. Phase05 delivered: immutable originals, perspective crop/loupe, tonal controls and comparison, persisted edit Undo, batch page selection/removal/restore, configurable paper/orientation/margins/quality, saved editable archives and reopen. Remaining: auto corner re-detection, processing cancellation, saved receipt and reader floating edit controls; shared asynchronous native draft ownership and orphan cleanup hardening; real-device memory/low-space/accessibility checks.
4. Phase06 Home/profile/settings/auth/notifications presentation remains beyond existing avatar/photo/welcome improvements. Use actual account/content services and locked screen specifications.
5. Phase07 Shop/content/admin presentation and staging regressions remain. Deployed Firebase rules/server-side admin enforcement are unverified; client UID checks do not establish backend authorization.
6. Phases08–10 quiz backend/CSV, Standard and non-monetary Special/duels remain disabled/unimplemented. Owner decisions are required for scoring, ties, timezone, abandonment and duels. No wallet, top-up, withdrawal or fee-linked cash prizes are in the authoritative scope.
7. Phase11 release requires complete traceability, physical-device and live-service evidence, rollback rehearsal and separate publish authorization. Production currently does not consume review overlays.

Continue authorized independent work in substantial batches without repeated next-step permission requests. This queue is neither a completion claim nor a promise of an unattended worker after the conversation stops.
