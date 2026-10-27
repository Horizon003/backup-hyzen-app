# Campus League — Quiz Engine, CSV/Admin, Rankings and Duel Contract

## Non-negotiable current eligibility

- New academic learning feature; not proof of an existing backend.
- Home Quick Access, top Community CTA if verified legal destination, Standard/Special tabs, upcoming event card, registration, rankings and duels.
- Quiz event labels should say `Standard` / `Special`, **not** `Paid`, `Free`, `Reward`, `No reward`, prize money, deposit or bet. No wallet/payment buttons anywhere in this module.
- **App may not facilitate a fee-linked cash-prize contest even if organizer accepts payments outside app; such events cannot use in-app registration/CTA/participation until platform/regulatory clearance**. Compliant academic free/non-monetary events only by default.

## Enforced quiz types

| Contract | Standard | Special |
|---|---|---|
| Subject scope | **One** admin-selected subject for selected Professional Year | **Two or more** admin-selected subjects, question counts per subject configurable, one interleaved/shuffled test |
| Quiz scheduling | Weekly or fortnightly; admin sets real windows | Community-announced date/time, administered registration and eligibility |
| Attempts | 3 max/day, >=60 min between starts/eligible attempts; repeat questions for same user **forbidden within event** | exactly one per approved student/event; no reattempt |
| User registration | Show `Register`/Join action if genuinely required/available | prefill/request full name, email, phone/WhatsApp and roll no privately, admin approval |
| Ranking | Subject/event ranking can improve on later verified attempt; precise formula not yet locked | publish verified event standings only after review; exact formula not yet locked |
| Question delivery | Random unused IDs from selected subject/year topics | Random unique IDs by admin-selected subject distribution, then shuffle globally |
| Privacy | Public competition username and consented score | Public username and permitted score; sensitive registration never public |

## Proposed relational/data entities (abstract; map to actual backend)

`question_bank` (immutable stable question_id, year, subject, topic, stem, options, private correct_option, explanation, difficulty, status, version, import_batch, created_by).

`quiz_event` (id, type, title, eligible_years, selected_subjects, topic_filter, per_subject_counts, question_count, attempt_duration_s, local_timezone, registration_window, start/end, status, version, authz policy, created_by).

`quiz_registration` (event_id, user_id, profile snapshot + separately restricted PII references, status, consent timestamp, reviewed_by/date/reason, idempotency key).

`quiz_attempt` (attempt_id, event_id, user_id, attempt_index, status, server_started_at, deadline_at, question_set_version, assigned question IDs, sealed answers, submitted_at, score_version, final score, timeout reason).

`quiz_answer` (attempt_id, assigned question_id, selected choice, last_synced_at, server validation) and `quiz_score`/`ranking_snapshot` (scoring policy version, rank, tie logic, publication status), `duel_invite/duel_attempt` opt-in controls.

All timestamps stored in unambiguous UTC with server timezone conversion; daily cap clock rule needs explicit product approval. Data retention/privacy model required. Personal PII records separate from public response DTOs. Never expose correct answer or private scoring formula in student question fetch.

## Atomic question assignment: reference pseudocode

```text
BEGIN TRANSACTION with row lock/user-event uniqueness
  authenticate user server-side; verify academic year eligibility, active event, approved registration (special)
  reject if prohibited event or feature disabled
  inspect attempts for server-based daily cap and cooldown (Standard) or one-attempt flag (Special)
  calculate used_question_ids := ALL previously assigned/seen IDs for this user + event (Standard)
  query ACTIVE question pool in correct year(s), subjects, topics and valid event version
  exclude used IDs (Standard); exclude duplicates within this attempt (both)
  if pool can't provide required per-subject count -> reject safely with transparent exhausted-state
  choose CSPRNG/DB fair random set or audited deterministic server randomization; assign immutable IDs
  save attempt + deadline + question set securely and atomically before response
COMMIT
RETURN answer-key-free shuffled questions and server timing, stable attempt_id
```

At submission recompute eligibility, deadline, assigned question IDs, answers, attempt state, score from SERVER secrets, idempotency and concurrency; commit final once. If network drops, client stores tentative answers securely with expiry; server remains authority, honest outcome/pending state, no fake pause. For fairness, document how assigned-but-abandoned questions count toward non-repetition (recommend counted as seen) before activation.

## Question bank capacity and no repeat

Given Standard `questions_per_attempt` N and `max_attempts/day` 3, bank for a given event/year/subject must have at least enough eligible distinct questions for plausible repeated attempts; if event spans days, required capacity can become large. Preflight `eligible_pool >= N * expected attempts per participant` when strict no-repeat across entire event. Track per-user consumed IDs and preview remaining capacity without leaking exact quiz questions. If remaining unused count < N, block next attempt or use a separately approved refill policy (do not silently repeat). Admin importing new questions may safely expand pool if same subject/topic/version rules met; no changes to already assigned attempts.

## Rankings & fairness (PENDING formal product approval)

User wants ranking rise with correct+fast play. Recommended unapproved candidate: accuracy/number correct takes precedence, completion time breaks tie, best verified Standard attempt per user counts. Explicitly keep `SCORING_RULES_PENDING` while requirements unresolved. Decide wrong answer penalty, unfinished/timeout policy, adjusted speed weights, ties, overall scopes, relative year/university scores, attempt best/latest, global vs event rankings, anti-collusion, cheating penalties, contest closure and review. Do not display fabricated rankings. For Special events with any meaningful prizes, ensure independent compliance and fair-scoring approval before enablement.

## Anti-cheat and security constraints

- Secure Android exam window flag (`FLAG_SECURE`) when supported to discourage OS screenshots/recordings; disable copy/select context menu for question text where reasonable; exam focus/blur event logging according to privacy law. **Cannot prevent external camera photos or all rooting/screen capture.**
- Server controls timers, active session, question assignment, result formula, answer key, user/year, attempt caps, rate limits and concurrency.
- Avoid transmitting correct answers/explanations before allowed reveal policy. Randomize choice order and question order while mapping correct answer keys server-side; protect APIs against scraping/brute force; request audit logs.
- Student duels: opt-in visible usernames only, invite throttling, block/report, no unwanted direct messaging, controlled result history; publish scoring only after specific rules agreed.

## Tests (minimum)

T01 user with wrong Professional Year does not see/join event even by API; T02 Standard one subject only; T03 Special >=2 subjects selected and mixed; T04 3/day cap across parallel devices; T05 1h cooldown across timezone and clock changes; T06 no repeat after app reinstall; T07 aborted attempts policy explicit; T08 question exhaustion; T09 Special one attempt despite duplicate registration; T10 private registration no public PII; T11 client lacks answer key; T12 2 concurrent requests create at most one eligible attempt; T13 timer cannot be extended by client clock change; T14 idempotent submit and once-only results; T15 admin-only import and approval; T16 feature toggle enforced on endpoint; T17 offline pending state honest; T18 scoring publish not performed before policy decision; T19 fee-linked event cannot be exposed as harmless 'Special' and must remain blocked.
