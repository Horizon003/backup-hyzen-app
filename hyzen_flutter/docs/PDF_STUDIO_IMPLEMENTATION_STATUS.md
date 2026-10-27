# PDF Studio implementation status — 1.3.3+7

## Available now

- PDF Studio has its own bottom-navigation destination and Hive-backed workspace history.
- Imported files are copied into private app storage with a sidecar JSON file for future, non-destructive edits.
- Android `VIEW` and `SEND` document intents open supported files in the app's read-only preview.
- External-file preview now includes a dismissible banner and a Save copy action. Saving creates a separate PDF Studio workspace record and opens that copy.
- PDF previews include in-document text search with highlighted results and previous/next navigation. The feature uses the existing `pdfrx` 1.x search API.
- PDF Studio files can be renamed, starred, removed from workspace history, saved to device storage, or sent through Android's native share sheet.
- The app display name and launcher icon use the PHARM D WITH HYZEN brand and purple HD capsule monogram.
- The new HD capsule monogram replaces the previous P icon across Android and web assets.
- The Studio dashboard offers device import, merge, split/extract by range or every N pages, page reordering/rotation/deletion/blank insertion, image-to-PDF, and simple text documents.
- These tools use Android `PdfRenderer` and `PdfDocument` on a worker thread, with bounded page and image sizes. Outputs are separate private workspace copies.
- PDF exports offer original PDF, extracted selectable text as TXT or plain DOCX, and all pages as PNG or JPG in ZIP via Android Save As or native share.
- A saved TXT can be reopened and edited into a new TXT, DOCX or PDF copy. New DOCX files contain plain paragraphs.
- The page annotation editor stores ink, highlight strokes, underline/strike lines, rectangles, circles, text labels and typed signatures in the workspace sidecar JSON. Marks can be undone and exported as a separate flattened visual PDF.

## Still required for a full editor

The Android PDF engine **rasterizes** input pages when merging, splitting, rotating or reordering. Output looks like the original but loses selectable text, links and interactive fields. The original PDF remains untouched. This is a practical first pass and must be tested with actual files on Android before release.

Text-anchored highlighting/underline/strikethrough, draggable edit handles, sticky comments, image stamps, page thumbnails, OCR, layout-preserving PDF/DOCX conversion, rich document editing, searchable/vector-preserving merge, compression presets, AES password protection, and interactive/editable PDF annotation exports remain unimplemented. PDF-to-DOCX only extracts selectable text as plain paragraphs. The page annotations above are drawn by gesture and stored non-destructively in the app; the flattened PDF export is rasterized. The existing Office preview extracts readable text but does not preserve the original page layout or edit DOCX/PPTX. Do not label these advanced features as complete in the app.

The simple document writer creates TXT, DOCX and PDF from plain text; rich Word formatting is not available.

## Build and verification

Source version: `1.3.3+7`.

The 1.3.3+7 signed release was built in the owner's private GitHub Actions repository on 16 October 2026 using Flutter 3.35.4 and JDK 17. `flutter analyze --no-pub` reports no issues, all 62 tests pass, and `flutter build apk --release --no-pub` succeeds. The APK certificate matches the original keystore and the older 1.3.0 APK. See `docs/VALIDATION_1_3_3.md` for the exact evidence and remaining physical-device acceptance scope. Never replace the owner-controlled production keystore.
