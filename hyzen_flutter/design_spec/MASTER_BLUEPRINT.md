# PHARM D WITH HYZEN — COMPLETE IMPLEMENTATION BLUEPRINT

**Audience:** ChatGPT Work, an authorized Flutter/Kotlin engineering agent, design engineer and QA reviewer. **Input contract:** START_HERE + Q01–Q33 ledger + child specifications + repo read-only audit. This blueprint supersedes broad earlier suggestions where the user's later directions are more specific.

## 0. Product objective

Transform the existing **PHARM D WITH HYZEN** Android app into a **Premium Academic + Minimal Professional** experience that remains fast, offline-resilient and familiar to its actual users. Preserve the existing Flutter/Dart + native Kotlin foundation, feature contracts, backend workflows, identity and data, and all reachable screens. Address known PDF scanner slowness and imperfect page correction with a custom CamScanner/Adobe-inspired workflow validated on real devices. Add future Campus League academic competition modules: year-aware Standard/Special quizzes, master MCQ CSV import, fair user-specific question allocation, admin reviews, rankings and duels. Use original consistent AI-generated artwork + deliberate smooth animations rather than a generic Material-purple reskin.

## 1. Approved design language

- Palette light: primary `#087F76` Deep Teal; headline/slate `#1A3440`; page `#F3F8F7`; surface `#FFFFFF`; subtle tint `#DDEDEA`; muted copy `#507379`. Dark theme with readable counterpart values in DESIGN_SYSTEM/TOKENS_AND_COMPONENTS.md.
- Manrope font, verified licensed source; consistent text hierarchy, logical 8pt spacing grid supported by 4pt micro steps, usually 14–18 px main cards, comfortable 48dp or larger buttons, restrained outlines and shadows.
- A (academic typography) + B (soft premium components) globally. C dense compact list rows in Study folders, Settings, Admin. D slate editorial cards only Welcome, About founder intro, Campus League and occasional Home feature; no hero-card overload.
- Fully responsive light/dark/system; genuine screen readers, RTL when required, dynamic text, reduced-motion, empty/loading/offline/retry states and meaningful animated feedback.
- **Mandatory original branded visual asset initiative**: custom coherent icon family for prominent app destinations/actions, chip decorations, onboarding 3D-style characters, optional ready-made avatar sets, illustrative empty/error/download/success states, and personalized subtle welcome animation. Avoid heavy images for simple text-sized system actions. AI render outputs must be curated and converted to usable responsive assets (SVG/vector rebuilt where possible, optimized WebP/PNG/Rive/Lottie where appropriate); no distorted readable text embedded in raster images. Asset inventory and licensing must be recorded.

## 2. Navigation, identity and preservation

Exactly four compact bottom tabs: `Home`, `Study`, `PDF Studio`, `Shop`. Top-right profile opens identity/Settings. Secondary screens use preserved GoRouter navigation and existing deep-link structures. `/home` includes small premium hero, search, genuine quick access including **Campus League**, relevant Recent Activity, announcement and Shop/Blog/About/Contact entry; only show mini quiz event teaser when actual eligible scheduled event exists. User's **Professional Year selected at registration** is authoritative for Study and target-eligible quizzes; profile year update refilters appropriately rather than reasking on each screen. Keep auth and admin authorization working; do not invent unimplemented recovery/verification behavior.

## 3. Academic Study and content discovery

- Study resource-first route: Regular Notes, Special Notes, MCQs, PPS → saved-year eligible Subjects → nested Folders → leaf PDF documents.
- Subject lists compact, professional, searchable where useful, no oversized useless cards.
- Recursive folder UI: breadcrumb from root, readable folder-icon grid, mixed folders containing files handled without hiding either files or subfolders. At leaf, **two-column real first-page PDF thumbnail gallery** with filenames. Generated preview must reflect actual accessible PDF, not a generic PDF icon represented as a thumbnail. Explicit loading/failure placeholders allowed while real render pending.
- PDF content under academic repository is read-only; user can download, annotate/create an editable copy, not silently mutate shared original.
- Search: context-aware global vs Study scopes, global category chips, admin-backed real filters in optional sheet, real counts, debounced search, recent searches with clear; no hypothetical PDF full-text indexing (reader's within-document search distinct).
- Downloads: Saved/In Progress/Failed tabs, compact file rows and Notes-style saved hierarchy (resource section → subject → subfolders → true PDF gallery); genuine local files only. Retry/cancel/remove actions safe. Storage and cleanup tools in Settings, not main downloads screen.

## 4. PDF experience

- Q8 immersive distraction-free full-screen reader with tap reveal controls, pinch zoom, pages/search/bookmarks.
- Q9 dock: floating bottom shortcuts Search, Pages, Bookmark, More; collapsed page-number pill on tap, expands on tap; More opens categorized bottom sheet.
- PDF Studio Q10 workspace: Scan and Create primary actions, search/manage PDFs and real recent file activity.
- Replace existing Google scanner handoff with an **own camera capture flow** where feasibility and performance can be validated in native Android pipeline: permission → preview → live quad overlay / on-device four-corner detection → Auto/Manual shutter + flash → capture → warp/crop → multi-page thumbnail strip → review. Native implementation architecture cannot be chosen until code/library/license/device audit. Benchmark vs baseline.
- Review Q12: page grid, reorder/remove/rotate; draggable precise corners with magnifier/redetection; Original/Magic/B&W/Grayscale filters + brightness/contrast, reversible previews, apply-to-all and crash-safe drafts.
- Q13 export: compact sheet with filename, quality/compression/resolution, optional page size, supported OCR (existing Latin capability only until verified), local destination; actual saving and Open/Share/Save to device success. No imaginary cloud/export services.
- Q14 PDF editing: read/edit separate modes, floating Adobe-style shortcuts, categorized More, contextual color/stroke/opacity. Do not promise true PDF source-text editing, certified signatures or professional PDF editor parity absent licensed backend and tests.

## 5. Profile, security and first-run

- Settings (Q15): categorized settings + search. Top **tall slate My Workspace** card, avatar above centered name; Edit Profile and My Year. Then **Your Preferences** cards, then **Security & Account** grouping with *future* App Lock, Change Password, Change Username; implement only after real auth logic approval. Other settings below.
- Profile Q16: clean academic card, dedicated Edit Profile screen; Personal / Academic / Security tabs. Photo selector, crop, preview/save, plus optional **original premade avatar gallery**; owner can avoid real photo. Security tab routes to available settings. Academic University/Professional Year real fields only.
- Welcome/auth Q17: premium academic welcome, editorial illustrated onboarding, minimal login/forgot password, guided Personal → Academic → Credentials → Success registration. Returning users skip onboarding. Personalized Welcome/Welcome Back with real first/display name, accessible skip/reduced motion.
- Preserve actual authentication, user IDs, password reset and real claims. Do not invent backend fields or expose private PII.

## 6. Shop, communications and content

- Shop Q18: subtle short editorial banner then true catalog/search/categories/products; product image/availability/quantity/cart; supported customer/delivery/payment checkout, order summary, confirmation and orders. Premium short image/cart/success animations, reduced motion. **Existing Shop payment is a separate, legitimate commerce flow; the prohibition on quiz money features does not delete Shop checkout.** Do not simulate unsupported courier/payment functionality.
- Notifications Q21: category tabs Academic / Announcements / Orders as data supports; chronological compact rows, clear read/unread, featured important announcement where real; overflow mark-read/archive/delete only if backend supports; admin announcements separate from personalized notifications.
- Blog Q22: tasteful featured editorial article card, distraction-free typographic reading and images. About: REAL owner's picture centered top, underneath **rectangular Slate → Deep Teal gradient introductory card** with actual biography text, never invented portrait/bio. Elegant Contact validation/loading and real success/failure.
- Admin Q23: task-first dashboard with quick actions / orders / incoming messages as supported, structured academic content explorer and optional import, separate Overview/Content/Commerce modules for actual analytics, products, orders, notices, resources. Server-side admin permissions, confirmation for destructive actions and no dummy metrics.

## 7. Campus League — academic engagement only in publishable configurations

- New module, **not existing app capability** unless fresh repo audit proves otherwise.
- Accessed from **Home quick access** with conditional mini teaser; **no fifth tab**. Campus League landing: top `Join Community` card linking to real user-provided destination and respecting eligibility; then `Standard` / `Special` tabs; scheduled academic quiz card/registration, rankings and duels. No paid/free/reward/no-reward badges on quiz cards. No monetary value display, wallet or payment support.
- Ranking view scopes: My Year, My University, Overall. Public profile = competition username, rank, score, academic performance/duel stats under opt-in conditions. Private roll number, legal name, email and phone/WhatsApp, and no public student directory unless later separately approved. Student discovery for challenges must be opt-in and privacy-controlled.
- **Standard:** free one-subject scheduled quiz (weekly and/or fortnightly), targeted Professional Year; user can register/join under actual eligibility. Up to **3 completed/initiated server-counted attempts per local policy day**, **at least one hour** between attempts; every attempt assigns randomly shuffled questions on selected subject/topics and excludes that user's already assigned/seen question IDs for that competition. Exhaustion outcome documented and safe; no silent repeat. Ranking improvement allowed but exact score aggregation and tie-break remain open; no implementation choice masquerading as finalized scoring.
- **Special:** academic community-announced event, selects **two or more** admin-configured subjects (or feasible selected number) from the same eligible Professional Year(s), question distribution by subject configured, selected questions interleaved/shuffled in a unified timer-based exam. **ONE attempt** per approved user, no re-entry. Registration private fields (saved full name, verified? if backend supports, email, phone/WhatsApp, roll number), reviewed and confirmed, not public. Admin approves/rejects eligibility; user sees accurate pending/approved/rejected state and schedule. Show subject list, exam topics, start/end time, rules, countdown and actual availability. Don't show paid/free/reward labels. **If a Special event is fee-linked to cash prizes externally, do not allow app-mediated registration/participation until cleared by applicable policy/law; treating fee collection as off-app is not an exemption**. Work on free/non-monetary Special flow with compliant wording only. Compliance holds apply to associated invitation CTAs and promotional community links.
- Duels: user opts in to discovery, selects consenting eligible student, invite → accept/decline → timed questions → server result and history; invitations rate-limited, block/report/moderation. Detailed duel scoring/eligibility later.
- Quiz exam Q27: A focused one question/four options + B prominent server timer and progress + C bottom sheet question navigator answered/unanswered/flagged + D Review → Confirm Submit → verified score/ranking. Smart error/resume semantics, but no false timer pause. No perfect screenshot prohibition claim; Android best-effort FLAG_SECURE + selection guards and item bank protection.
- Admin Q28: A operations dashboard, B CSV Studio downloadable blank/example templates and validations, C quiz scheduling wizard (year(s), Standard single subject or Special multiple, topic/question/time policies, start/end, registration deadlines, question distribution), D registration review + results scrutiny/publish + safe server-enforced feature flags. Admin can disable Standard, Special, Rankings, Duels independently; prohibited cash-prize functionality is hard unavailable, not just hidden behind toggle.

## 8. Quiz backend and data contracts

Server-authoritative authenticated user ID, Professional Year eligibility, admin roles, question imports with immutable IDs/version/audit, question secrecy, per-user `assigned_question_ids`, attempts with server start/end/deadline, deterministic correctness evaluation, cooldown and daily cap, idempotent registration/submission. `correct_option`/explanation never bundled into client question payload before permitted release. Store attempts and questions transactionally to prevent parallel device bypass. For Standard, random selection without repeats must be scoped explicitly to the user's competition; do not rely solely on client state. Cross-year subject question data must not leak. Enforce one-attempt Special at database/service layer.

The following are **not defined** and must be resolved before ranking publication/competition activation: scoring formula, percentage vs time weighting, best vs latest attempt ranking, tied ranks, skipped answers, daily reset timezone (Pakistan vs participant configured), timeouts/late submissions, resumption after network outage, distribution constraints when bank exhausts, dispute and moderation workflow. Document recommendation, ask user approval for sensitive changes; never silently choose a cash-prize winner formula.

## 9. Engineering plan

Actual observed repository is truth: previous discussions mentioned Flutter Material 3, Riverpod, GoRouter and native Kotlin channel with Google scanner, and original routes; **verify anew**. Do not replace full router, auth, DB or state management simply to fit a UI screenshot. Favor incremental shared tokens/components, feature modules and guarded route additions. Write migrations backwards compatible, use feature flags/config checks server-side and UI-side, test production data semantics and rollback.

Follow Q32 locked staged approach: B safe feature-by-feature with gates; C prioritize PDF scanner/offline after baseline; D quiz rollout modular behind genuine controlled flags; A final app-wide visual audit. See PHASES and architecture manifest.

## 10. Test and acceptance definition

User-facing app must preserve all currently working journeys. Verify on target Android hardware where native camera or performance matters. Design: compare screenshots at small/large fonts, both themes and reduced motion. Data: backed-up PDFs, drafts, downloads, subject hierarchy, account years, orders, notifications and auth retained. Scanner: quality, speed, perspective correction, multipage, accurate exports. Quizzes: subject/year isolation, Standard nonrepeat/cap/cooldown, Special single attempt/approvals, no answer leakage, anti-spam duels and result consistency. Admin permissions on backend, no unsafe anonymous uploads or leaderboards leaking PII. QA matrix is the release contract.

## 11. Non-goals / permanent exclusions in this package

- No wallet, top-up, withdrawal, contest money balance, screenshots as proof of quiz payment, JazzCash/Easypaisa funding workflow, or monetized Quiz UI.
- No app links, registration CTAs, quiz access gates, payments or prize marketing that facilitate an unapproved fee-linked cash-prize competition, even if organizers communicate separately.
- No fifth bottom tab; no mandatory actual profile photo; no public private student records.
- No guarantee against external-camera cheating; no unverified OCR languages, cloud storage, certified signatures or Adobe proprietary text editing.
- No direct React/CSS injection to Flutter; no unlicensed fonts/icons, fake precreated visuals or bloated infinite Lottie animations.

## 12. Reporting milestones

Read-only audit → design-component demonstrations → staged features with proof → Android device demonstration for scanner → backend authority test for quiz → e2e regression and rollout. For each phase report observed baseline, changes, tests, screenshots/evidence, risks, blockers, rollback. Source code changes not included inside handoff ZIP.
