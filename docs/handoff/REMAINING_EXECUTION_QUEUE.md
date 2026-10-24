# Remaining execution queue — honest status

Review branch work/hyzen-phase-01, draft PR 1. Latest code checkpoint cdccdff1a95aee7dc2c58110aaa7e2ecbd64e7ba. No merge or deployment.

1. Finish native instrumentation verification. Build succeeds; earlier emulator runs failed for disk/image/userdata space before app tests ran. A 2 GiB userdata bound is now under verification. Native results must not be inferred from Dart tests.
2. Manual perspective crop implementation is now under CI: independent four corners, convexity/area/bounds checks, reversible warp graph, restart/Undo tests, 320px widget coverage. It is not live auto-detection, a magnifier, or a complete scanner.
3. Implement direct native camera preview and efficient YUV detection prototype, permissions, torch/orientation, stable auto/manual capture and multi-page strip. Existing ML Kit/basic-camera fallbacks remain until quality is measured. Physical acceptance requires an actual Android phone; no model/performance result exists here.
4. Finish editable document persistence after export, full-resolution transform/export, precise crop magnifier, enhancement controls, export sheet/receipt/cancellation/low-space handling and reader floating controls. Current originals belong to drafts and are cleared after successful existing export.
5. Finish Home/profile/settings/auth/notifications presentation against locked screen specs using actual existing account/content services. Existing avatar/photo/welcome improvements are only a subset.
6. Finish Shop/content/admin presentation and staging regressions. Live deployed Firebase rules and server-side admin enforcement remain unverified; client UID checks are not evidence of backend security.
7. Quiz backend/CSV, Standard and non-monetary Special/duels remain unimplemented and disabled. Scoring, ties, timezone, abandonment and duel rules require owner decisions before behavioral implementation. Private MCQ bank and atomic attempt/nonrepeat controls require actual server implementation and staging validation. No wallet, top-up, withdrawal or fee-linked cash-prize flows are authorized by the authoritative handoff.
8. Final release requires physical-device/accessibility/performance and live-service evidence, complete traceability, rollback rehearsal and separate publish authorization. The production workflow currently does not consume review overlays.

User authorized continuing all remaining safe work without repeatedly requesting a next-step confirmation. This file is not a claim that those tasks are completed or that an unattended worker will continue after the conversation stops.
