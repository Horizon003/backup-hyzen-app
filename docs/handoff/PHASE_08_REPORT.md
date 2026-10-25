# Phase08 — backend gate and preserved CSV contract

Status BLOCKED for application/backend implementation. Inspected real Firestore repositories, proposed rules, academic data model and package Phase08/CSV/schema/engine contract. There is no observed deployed quiz allocator, answer-secret backend, attempt API, migration pipeline or emulator/staging authorization environment. Only firestore.rules.proposed exists; deployed rules and admin enforcement remain unverified. No production question data was queried or written.

Safe independent output: preserved the handoff's blank CSV, explicitly demonstration-only sample CSV, schema and CSV guide under docs/handoff/quiz_contract. These are review resources, not an enabled in-app Question Bank. No sample question is inserted into application assets or published. No student payload contains these answer keys because no student question API/UI is enabled.

## Actual-stack implementation boundary

Existing Firebase Auth/Firestore can remain the identity/data foundation. A trusted server component is required for assignment, answer keys, attempt timing, rate limits, idempotency and scoring. A Flutter client writing Firestore directly cannot prove those guarantees. No provider/service has been selected or deployed on the owner's behalf.

Proposed additive namespaces, pending staging verification: quiz_question_revisions (private server/admin only, immutable questionId/version), quiz_import_batches (private actor/checksum/line errors/commit audit), quiz_events (sanitized published event descriptors), quiz_registrations (student-owner/admin private PII), quiz_attempts_private (server assignment/answer key/timestamps), quiz_attempt_views (owner-only answer-key-free view), quiz_ranking_public (opted-in username/permitted score only), quiz_duel_private (opt-in participants; unavailable until rules approved). Existing students/settings/orders/messages/verifications collections must remain untouched. Public/owner DTOs must use explicit field allowlists, never serialize private records wholesale.

All new namespaces should initially deny client writes; question revisions/import batches and private attempts should deny student reads. Trusted server admin SDK access bypasses Firestore rules, so endpoints must independently authenticate, authorize and enforce features. Proposed collection names are a design, not current repository endpoints or deployed permissions.

## Minimum staged transaction

1. Authenticate verified admin server-side; enforce byte/row/UTF8 limits; parse RFC CSV with line-aware errors; reject unknown/duplicate columns, duplicate IDs, invalid choices/options, unsafe markup/formulas and mismatched real year/subject/topic taxonomy. Sample status remains draft.
2. Stage preview with checksum, actor and expiring batch ID; no publication on upload. Import confirmation uses idempotency key and expected revision. Validate entire batch before committing, preserve immutable historical revisions and report inserted/skipped/conflicts without hidden partial success.
3. Preflight Standard one subject, Special at least two with exact per-subject counts. Derive question pool from approved real taxonomy. Do not guess school mappings or publish open-scoring events. No fee/payment/wallet schema or toggle.
4. Server allocates atomic unique attempt + deadline + unused revision IDs before returning allowlisted question text/options. Never return correct_option or private explanation during an exam. Starts/submits use server time and immutable versioned assignments; concurrent retry must not consume multiple attempts.
5. Stage negative tests: student/unauthenticated import denial; arbitrary claim escalation denial; direct answer-key query denial; PII query denial; field allowlist inspection; feature-off endpoint denial; duplicate start/submit; no-repeat after reinstall; expired deadline; rollback without modifying existing app collections.

## Decisions and acceptance

Still required: verified deployed rules and a dedicated staging project/provider, actual subject/year IDs, approved scoring/penalty/tie/best-vs-latest policy, daily timezone/aborted-attempt policy, Special publication/disputes, duel timing/ranking policy and private registration retention/consent. No monetary contest implementation is permitted by the handoff.

G1 downloadable handoff templates exist as repository review resources, but in-app staged import is NOT implemented. G2–G4 and G6 are BLOCKED, not passed. G5 no new monetized capability exposed remains a source-scope constraint, not legal certification. No migrations run; rollback consists only of removing these review documents. Phase09/10 server-dependent features remain disabled. Physical/live-service/complete release gates are also open.
