# PDF Studio 1.4.1+9

Create PDF is available in PDF Studio. Scan with camera launches Google's native
document scanner, with gallery import, edge crop, rotate, cleanup and multi-page
review. Up to 50 pages may be saved as one PDF into the existing private workspace.
Cancellation saves nothing. Scanner availability depends on Google Play services
and at least 1.7 GB device RAM; first use may download the scanner. Gallery image
conversion remains available as a fallback. Scans stay on-device.

Page merge, split and organization now use Apache-licensed PdfBox Android page
imports, retaining text and vectors. Flattened export remains an explicit image
copy. Editable export adds standard PDF annotations separately from page content.
Native PDF readers vary in which annotations they allow users to modify.
This does not edit pre-existing PDF paragraph text or constitute a certificate
based digital signature. Typed signatures are visual annotations.

The new structured document writer creates PDF or DOCX with paragraph-level bold,
italic, underline, headings, lists, alignment, tables and images. It creates new
documents; arbitrary imported Word layouts are not round-trip edited. PDF-to-DOCX
remains text extraction rather than exact layout reconstruction.

OCR uses bundled on-device ML Kit Latin recognition (up to 50 pages). It can
export recognized text or create a searchable PDF with an invisible text layer.
Urdu/Arabic OCR is not included. Recognition quality depends on scan quality.

AES-128 password-protected copies require a 6–128 character password. Passwords
are never stored in history or configuration; originals remain unchanged.
Compression downsamples large embedded images with three quality presets and
retains text/vectors. A copy which would grow is discarded in favor of the original.
Images over 16 megapixels are skipped to bound memory use. Results depend on input.
JPEG-2000 images are preserved without recompression; the optional retired
PDFBox JP2Android codec is not bundled. Normal PDF viewing uses PDFium/Android.

Exports can go to Studio, Android Save As, or the native share sheet. Page-image
ZIP exports go to device/share rather than appearing as unreadable Studio files.

Drive setup remains blocked: existing Cloud project needs Drive API and an Android
OAuth client for com.hyzen.pharmd with the original signing certificate. See
DRIVE_PIPELINE_1_4.md. No source URLs, Drive permissions, accounts or cloud settings
were changed. No live Drive speed improvement has been established. As a working
fallback, absent/disabled API configuration restores the original online preview
and public download/export endpoints. Public download confirmation is parsed only
for Google's HTTPS hosts and the same file ID. Private access is not bypassed.

Validation: Flutter regression tests plus Android instrumentation verify page
order/rotation/text retention, separate PDF annotations, password enforcement,
compression, OCR and structured document exports. Camera hardware/UI acceptance
requires a physical Android device; a scanner bridge test is not a camera test.
