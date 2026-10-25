# Phase 07 — Shop, journal, About and existing admin

Source 1e78c8659fd108aa28da1129ad40b362a2b56f01 on work/hyzen-phase-01. Draft PR https://github.com/Horizon003/pharm-d-with-hyzen/pull/1. Isolated updates_phase_07.json changes four files: shop/presentation/shop_screens.dart, content/presentation/info_screens.dart, admin/admin_screen.dart beneath lib/features, and test/navigation_test.dart.

## Delivered presentation

Shop shows an editorial Slate header and a catalog count only after real data loads, otherwise truthful loading/unavailable text. Search includes name/category/description; clear filters resets both visible text and category. Empty catalog and no matches differ. Narrow/large-text layouts use one column; prices wrap. Existing real stock, cart, checkout, COD/order and payment behavior is retained.

Blog leads with the actual first published article and its provided cover/author/excerpt, opening the existing reader; searching retains the normal filtered list. About uses a real credit's explicit owner/founder role rather than inferring ownership from a name. No hardcoded owner identity or invented portrait/bio remains. Other published contributors are retained, including a lone contributor.

Admin exposes Overview, Content and Commerce views with contextual existing actions. Overview retains the full inventory. Async order/message counts distinguish loading/unavailable from a real loaded zero. The unsupported 'Secure admin' claim becomes 'Admin workspace'; UI role guards are retained but are not evidence of server authorization.

## Validation and constraints

Run https://github.com/Horizon003/pharm-d-with-hyzen/actions/runs/40163839757 is the first check for this source. Three new widget tests exercise real fixture-catalog search/clear/out-of-stock, non-invented owner/contributor identity and opening the actual blog reader. That run failed analysis on a missing surfaces.dart import. Corrected source581c09eb passed analysis and136 tests, with one contributor test failing because its fixture used a list instead of the observed pw_credits.cards envelope. Sourcef2c98599 corrects that fixture and asserts provider decoding before checking the UI. No production behavior was weakened to pass the test. Final run https://github.com/Horizon003/pharm-d-with-hyzen/actions/runs/40164302166 atf2c98599 passed clean analysis11.2s, all137 Dart tests47s and screenshot capture. Artifact12587423901 SHA256 cb4c9c1d42a77835546de517258d60dab47221839f2869ab224ca8b033825318 was verified. Light Shop (empty catalog fixture), dark Blog, light About, light/dark Admin, dark Settings and corrected dark Profile screenshots were inspected. The two-product320px layout/out-of-stock case passed as a widget test; the catalog screenshot itself uses an empty fixture and is not live Shop evidence. Native source is unchanged from the7e18737236-test checkpoint; latest redundant native rerun remains in progress. Screenshot sweep adds Shop and Blog in light/dark. Fixtures are test-only; no mock catalog or owner is shipped.

Phase07 server-permission/staging gate is still blocked. No live order, payment or contact message was sent, backend rule changed or admin transaction exercised. Existing checkout has these observed risks requiring staging/provider review: verificationSnapshot contains customer names/full phone/city/province despite a masked-public comment; proposed public token-get rules could expose PII if that contract is deployed. Deployed rules were not accessible, so this is a conditional risk, not a proven live breach. Also, submit acknowledgment followed by a local-history failure can leave retry/idempotency uncertainty. Presentation changes do not resolve either backend issue.

## Rollback

Remove phase07 from both review workflow assembly loops to restore Phase06-era Shop/content/admin views and tests. No order schema, stored cart, payment service, route or backend migration changes. Preserve existing local data. Main and production remain unchanged; this is partial delivery, not a secure-commerce or release acceptance claim.
