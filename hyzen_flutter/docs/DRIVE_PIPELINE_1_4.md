# Native Drive delivery — 1.4.0

## Implementation

The academic reader uses PDFium/pdfrx `PdfViewer.uri`,
`preferRangeAccess: true`, `useProgressiveLoading: true`. It never embeds the
Google Drive `/preview` UI for PDFs. The old URL helpers remain for compatibility
and historical benchmarks; production preview and save no longer call them.
Existing original URLs, file IDs and offline keys are retained. Google Workspace
Docs/Sheets/Slides use the official `files.export` API; binary PDFs use
`GET https://www.googleapis.com/drive/v3/files/{id}?alt=media`.

Metadata is cached for five minutes, separately for each Google account. OAuth
bearer tokens stay in memory and are refreshed before reuse. No client secret,
service-account JSON or refresh token is embedded in the app. The Google account
connection is separate from the app's email/password login. Logging out clears
the Drive authorization held by this app.

Downloads stream to private app storage. A `.part` file and resume journal retain
an interrupted transfer. Resume appends only after a matching source/version and
valid HTTP 206 Content-Range; If-Range protects ETag-based resumes. A server that
returns 200 restarts safely. Invalid responses discard partial data. A ready PDF
requires the PDF signature, an EOF marker and the expected full byte length,
plus a successful native Android PdfRenderer parse with at least one page.
Pause/retry preserve partial bytes. Local delete removes only the app copy and
its partial journal, never anything in Drive. The maximum is 250 MB per file.
pdfrx manages the reader's recent range cache; offline copies have explicit user
ownership and are separate. Google Docs export endpoints do not support Range.

## Owner configuration still required

The existing Android `google-services.json` has no OAuth clients. Testing its
current client API key against Drive returned HTTP 403:
`Requests to this API drive method google.apps.drive.v3.DriveFiles.Get are blocked.`
Do not repurpose this restricted Firebase key or make source files public.

1. In the existing Google Cloud project, enable Google Drive API.
2. Configure Google OAuth consent and a native Android OAuth client for
   `com.hyzen.pharmd` with the existing release signing SHA-1. Download the updated
   `google-services.json`. Do not rotate the release signing key.
3. For public academic files, optionally provide a properly restricted public
   Drive API key with `--dart-define=HYZEN_DRIVE_API_KEY=...`. A client API key is
   not a secret and cannot grant access to private files. Configure package and
   certificate restrictions appropriate for the deployed transport.
4. For private files, the learner uses Connect Google Drive and grants read-only
   access. Their Google account must already have access to the source document.
   Full Drive read-only scopes may require Google verification before public use.
5. Web account authorization needs the public web OAuth client ID via
   `HYZEN_GOOGLE_WEB_CLIENT_ID` and the preview domain as an authorized origin.

No accounts, source academic URLs, cloud permissions or API configuration were
changed automatically in this revision. Without the configuration above, Drive
will display a clear connection/setup error; an APK cannot bypass Google's API
authorization requirements.

## Honest performance acceptance

Run `python3 qa/drive_benchmark.py --output qa/drive_benchmark_results.json`.
It tests the SAME three existing academic IDs for old `/preview`, old download,
API head range and complete API transfer. Output records response code, TTFB,
elapsed time and received bytes. Errors are recorded as errors, not speed wins.
This network script does not measure a rendered first page. For that, measure
on the SAME phone/network in both builds, cold cache, three repetitions per PDF;
record median time to first painted page, transfer bytes before page one, and
full offline-save duration. Do not claim a successful before/after result while
the Drive API returns 403 or no authorized account is available.

## Optional mirror architecture (design only; no files migrated)

Keep Drive as source of truth. An owner-approved worker tracks Drive changes,
copies eligible PDFs to private object storage and records `fileId`, Drive
version, checksum, size and mirror object version in a delivery manifest.
An authenticated gateway verifies Firebase ID tokens and entitlement, looks up
the existing file ID, and returns a short-lived signed CDN URL. CDN must support
Range/206, ETag/If-Range, Content-Length and correct Content-Type; expose these
headers for browser CORS. Private documents must not become public cache objects.
Use workload identity/ADC on the server, never service-account keys in clients.
On a version mismatch, serve Drive or regenerate the mirror; never serve an
old student's private file to another account. Roll out behind a disabled
feature flag after owner approval, access audit, cost estimate and checksum
validation. Preserve current academic URLs; resolve fileId to delivery at runtime.

## PDF Studio boundary

The original 1.4.0 revision used rasterized page operations. Version 1.4.1
supersedes this boundary: see PDF_STUDIO_1_4_1.md for lossless page operations,
standard annotation exports, scanner, OCR, AES and structured document creation.
