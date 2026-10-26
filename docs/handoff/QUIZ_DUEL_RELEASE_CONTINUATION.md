# Quiz/duel and canonical release continuation — 2026-10-26

Starting snapshot: `b84307e4`, PR1 / `work/hyzen-phase-01`. This continuation uses an independent branch to avoid overwriting another ongoing chat. It does not merge PR1 or deploy Firebase, billing, rules, Pages or customer data.

## Implemented in this continuation

- Private `QuizPlayService` and authenticated/App Check callable adapters: lobby, start/get/save/submit, create/join/status/cancel duel.
- Explicitly approved server policy required; no auto-enablement. Initial supported contract is **free practice only**, one point per correct answer, zero for wrong/unanswered, three combined solo/duel starts per Pakistan day, one-hour cooldown, shared-score draws. Started/abandoned attempts count. These are a concrete candidate contract, not an assertion of owner approval. Reward/event policies are not implemented.
- Membership/year is trusted server configuration, separate from the self-editable student profile. Immutable revision imports need separate publication approval and a configured pool before allocation. Per-user question IDs are reserved transactionally; revisions do not reset no-repeat history. Bounded pool size is 200 revisions / 20 questions per attempt. Exhaustion fails without charging an attempt.
- Server-generated 256-bit invitation codes, ten-minute invitations, explicit guest acceptance, same-year enforcement, one guest, shared assignment/deadline, three invitations/day and no automatic messages or user discovery. Pool changes invalidate outstanding invitations. No fee/wallet/prize functionality.
- Idempotent start/create/join, optimistic answer revisions, deadline enforcement, server-only scores, disconnected peer settlement on result/status reads. Answer keys/explanations and participant UIDs never appear in student DTOs. No scheduled gameplay settlement/history retention is implemented yet; read-time settlement is intentional in this candidate.
- Android client calls the actual callable APIs through Firebase Functions and Play Integrity App Check. Lobby shows only server-provided pools; errors, disabled state, quota/cooldown messages, copyable duel code, server-saved answers and last-attempt/invitation recovery are included. Request IDs persist before sending. It never runs a local fake quiz or calculates authoritative scores. Account changes recreate the screen and are checked before/after network calls.
- Canonical assembly now includes `updates_phase_08.json`. Current signed APK workflow uses the same complete assembly and inherited normalization as review CI. It verifies the original certificate, records actual normalized source/APK hashes and waits for backend tests + install smoke before optional release publication. Publishing requires a merged main commit. The old partial 1.4 workflow is retired and can no longer auto-deploy Pages.

## Validation

Final local validation: **78 backend/emulator tests passed, 0 failed**, including real Firestore transaction races and client rules denial across gameplay namespaces. **16 Python source/CSV/release-evidence tests passed**. Workflow YAML parses and `git diff --check` passes. Four Flutter widget tests are included in the overlay but have NOT been run; Flutter dependency resolution, analyzer, widget/native builds and signed release remain unverified.

**Remote persistence:** the first GitHub create-tree write did not execute because automatic approval review hit an account usage limit. After the user's continuation, retrying the same normal approval path succeeded. Source is being recorded on independent branch `work/hyzen-quiz-duel-release`; consult its PR and completed CI for actual remote validation. A recovery ZIP also preserves the earlier unpushed checkpoint. No merge, deployment, final release or Drive upload is implied.

## Still required before final release

1. Staging/backend hosting and billing access; deployed callable HTTP/Auth/App Check/IAM verification. No production upgrade or deployment is performed by this change.
2. Real approved taxonomy and MCQs, in-app admin Question Bank/revision/publication workflow, approved member enrollment/year management, pool setup and approval of the exact gameplay policy. The client and service intentionally fail closed without these.
3. Ranking/performance/history, Special/reward registration/attempt policies, moderation/block/report, gameplay data retention and broader abuse monitoring. These are not implemented by this candidate.
4. Real account/admin/Shop acceptance, legacy commerce privacy migration, physical camera/performance/accessibility and upgrade/rollback testing inherited from PR1.
5. Merge the reviewed continuation with the current branch, run the current signed workflow with the original owner key and a version code greater than every distributed APK, verify the artifact, then publish/upload the same checksum to GitHub and Drive. No final APK, release or Drive upload is claimed by source changes alone.

## Configuration contract (server-only; no fixture data in production)

`quiz_control/play`: `enabled:true`, `approved:true`, `version:'free-v1'`, `timezone:'Asia/Karachi'`, `correctPoints:1`, `wrongPoints:0`, `tie:'shared'`, `dailyCap:3`, `cooldownSeconds:3600`.

`quiz_members/{uid}`: `enabled:true`, verified `professionalYear:1..5`. Do not grant clients write access.

`quiz_publications/{revisionId}`: `enabled:true`, `revision` exactly matching the immutable revision document ID. Publication must follow an actual content review.

`quiz_pools/{poolId}`: `enabled:true`, bounded title, matching `professionalYear`, `questionCount:1..20`, `durationSeconds:30..1800`, numeric epoch-millisecond `opensAt/closesAt`, unique `revisions` array (up to 200). Pool IDs use letters/digits/underscore/hyphen. These paths and all gameplay records remain private under the existing catch-all denial rules; only Admin SDK callables access them.

Deploy only to an explicitly selected staging project using `firebase.quiz.json` after provisioning App Check and the administrator allowlist for import. No `.firebaserc` production default or credentials are included. Check the scheduled preview-retention index separately. Disabling `quiz_control/play.enabled` blocks new and existing gameplay APIs; rollback does not delete existing data.

