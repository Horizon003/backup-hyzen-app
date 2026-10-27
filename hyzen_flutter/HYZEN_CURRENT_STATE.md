# Current state — PHARM D WITH HYZEN

Source version 1.4.2+10. Android package com.hyzen.pharmd is unchanged.
Read docs/COMPACT_READER_1_4_2.md for compact UI, content-intent routing,
back-navigation and the new durable multi-page camera/gallery flow.
Read START_HERE_NEXT_CHAT.md and docs/PDF_STUDIO_1_4_1.md for scope and limits.

Adds Create PDF with camera scanning or gallery photos, Latin OCR, lossless page
operations, layered annotations, AES protected copies, compression and structured
PDF/DOCX creation. The original owner signing identity remains in private CI secrets.

Drive API/OAuth setup is not complete. Missing/disabled configuration now restores
online Google preview and public-file offline downloads; file permissions remain
enforced. No Drive source URLs, account permissions or backend rules were changed.
Check the release workflow for actual build/test evidence; physical scanner camera
acceptance and the same-device first-page benchmark remain outstanding.
