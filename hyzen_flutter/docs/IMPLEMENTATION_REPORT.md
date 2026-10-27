# Implementation report — PHARM D WITH HYZEN

14 October 2026 · Flutter app 1.1.0+2

## Source audit

The original Genspark ZIP had more screens than its active router exposed.
Placeholder tabs and missing nested routes made only a small portion usable.
The supplied `PharmD_with_Hyzen_updated(2).html` defines the existing Firebase
key/value backend, Cloudinary preset, admin inventory and founder photo field.
The screenshots supplied About and admin navigation references.

## Requested changes and resulting behavior

| Request | Implementation |
| --- | --- |
| Android Back closes app | Nested routes pop; other tab roots return Home; Home asks before exit; notices use a dismissible navigation route. |
| Drive preview missing | Drive/Docs/Slides/Sheets URLs, resource keys, embedded preview, loading bar, errors/watchdog, retry and browser fallback. Direct PDFs use native PDF viewing. |
| Missing download/save/progress | Save offline, progress/byte totals and ETA where known, cancel, validated PDF storage, offline reading and export through Android's system file picker. |
| Lag and glassmorphism | Removed live blur, translucent card rendering and moving background effects; retained tab state, isolated large tree parsing, finite image decoding and a release-mode build. No device FPS measurement is claimed. |
| Signup cities/keyboard | Expanded searchable list with manual entry; stable controllers and manual keyboard dismissal during form scrolling. |
| Completed profile asked again | Separate persistent profile cache and pending-sync draft, scoped to account. Successful sync clears only the draft. Student-facing technical sync banners removed. |
| Professional-specific data | Library, lectures and search follow the saved professional year. Edit Profile/Settings changes the year; admin retains all-year access. |
| Profile photo | Native bounded photo selection, resizing/rotation, Cloudinary unsigned upload and saved profile URL. |
| Welcome/engagement | Welcome by name, study CTA, resource shortcuts, daily prompt, recent study and brief reduced-motion-aware animation. |
| Founder photo | Reads `pw_credits.cards[].photo`, with fallback if the remote image is unavailable. |
| Light/dark redesign | Opaque Material navigation/cards, cream/emerald light and charcoal/green dark, readable adaptive accents and existing eight-palette compatibility. |
| Header notifications | Bell/unread badge, account-scoped read history, live announcements and full-screen notices, expiry/withdrawal and custom notice styling. Closed-app push is separate work. |
| Admin redesign/full controls | Grouped dashboard and drawer; inventory below; stable forms retain edits through listener refresh and retry. |
| App name | Android label, app brand and browser title/manifest use PHARM D WITH HYZEN. |

## Website admin inventory mapped into the app

| Group | Native controls |
| --- | --- |
| Overview | Dashboard, statistics |
| Content | Notes, Special Books & Notes, MCQs, Past Papers hierarchy CRUD/order/publish; Lectures professional/semester/subject/topic/link editing |
| Import/data | Multi-file CSV/JSON/XLSX validation, preview and duplicate skipping, import history; JSON backup/restore |
| Store | Products/media/variants/stock/feature/hide/duplicate; orders/inbox/status/tracking/delete; CSV and printable HTML invoice export; catalog categories/columns/spacing/radius/shadow; delivery rates |
| Inbox | Message inbox sync, read/unread/detail/delete; explicit email/WhatsApp reply links |
| Site | Eight palettes/per-palette logo/default palette, website presentation settings; announcement; full-screen notifications; About/team photos/social; blog CRUD/status/slug/HTML/media; section visibility; identity/contact/SEO settings |
| Backend/navigation | Connection read check, student view, logout |

Order inbox processing re-reads canonical values and inbox documents inside a
transaction. Duplicate processing does not reduce stock again. No automatic
outgoing communication was added. Admin routes use the existing configured UID;
server rules must independently authorize writes.

## Integration limits

- No production admin writes, real signup/login or rules deployment were done.
- The included student rules block must be merged before cross-device profile
  syncing is accepted. Local profile editing already works independently.
- Public Drive files can preview/download; private/deleted/quota-limited files
  need owner sharing/availability fixes. Loading time depends on connection.
- Notifications are live in-app; FCM/background push is not configured.
- Device-picker/WebView/PDF/photo and performance acceptance requires an Android
  phone. Automated rendering does not verify native plugins on a device.
- Website ring/glitter and marquee controls remain website-specific. Native
  surfaces remain opaque and announcements static for responsiveness.
- Legacy XLS is unsupported; convert it. Invoices export printable HTML.
- Development signing is retained privately for future test-build continuity.
  Older builds with a different signing key require the original key to update
  in place. Production signing and final owner policies remain release work.

Detailed check results and APK metadata are in `VALIDATION.md`.
