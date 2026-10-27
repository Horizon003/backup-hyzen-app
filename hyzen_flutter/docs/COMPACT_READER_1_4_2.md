# PHARM D WITH HYZEN 1.4.2+10

Build destination Horizon003/pharm-d-with-hyzen was explicitly authorized by the
owner. The original private CI signing identity is unchanged. Check the release
workflow for Flutter and Android regression results; local structural checks
alone are not a compilation or a camera-hardware test.

This revision follows the owner's compact purple Home / PDF Workspace reference.
The opaque floating dock has Home, Study, a prominent PDF center, Shop, Settings.
Study opens a dismissible nested menu (Notes > Regular / Special, MCQs, PPS,
Downloads). Profile remains in the top-right header. PDF reader screens hide the
main dock and use a single compact page/search/create/zoom/tools dock.

Greeting artwork remains beside the text on narrow phones; very large accessible
text hides decorative artwork rather than stacking another large panel. Headers,
resource rows, recent study entries and subject tiles use compact typography and
spacing. Text scaling is not globally disabled. Sections and real data remain.

Android content intents are owned solely by HyzenExternalFiles. Flutter's default
deep-link handler is disabled to prevent content:// URIs becoming unknown app
routes. Read-only device previews do not require app sign-in. The history id is
retained in the reader URL so the route is not dependent solely on route extras.
Settings and Shop now belong to the authenticated shell and Android back returns
to Home instead of exiting a directly selected top-level destination.

## Lightweight multi-page camera and gallery flow

Create PDF asks Camera or Gallery. Camera delegates one full-size capture to the
installed Android camera application using a narrowly scoped FileProvider grant.
Each confirmed photo appends to a private on-device draft. Add more captures,
rotate, reorder or remove pages, name the PDF and save. Gallery photos join the
same flow. A pending camera path and page list are committed before handing off
to the camera. Process recreation recovers them without a live Dart callback.
Images are EXIF-corrected and bounded to control memory. Camera UI differs by
device; this flow does not provide automatic document-edge cropping.
Image-to-PDF saves use PDFBox with disk-backed compressed streams, avoiding
retaining many full-size camera bitmaps in a Canvas display list. Memory errors
return a retryable error rather than marking an incomplete PDF as saved.

The old heavy Google scanner bridge remains in the source but is not the default
camera flow. Its physical-device crash could not be proven from screenshots
alone; the replacement removes that dependency from normal capture. Real camera
device acceptance is still required; mocked capture tests are not hardware tests.

Save validates the produced page count, commits Studio history, then clears only
the app-owned draft. Failed saves retain pages for retry. Originals are untouched.
Existing source Drive links, public fallback and original signing identity remain.
Drive API/OAuth configuration is still not completed. No source migration or
Google Cloud permission changes are part of this release.
