# Compact Office and scanner review

Branch: `codex/scanner-compact-office` · PR #6

## Behavior

- Live CameraX preview/capture coordinates share a 4:3 viewport. Detection includes off-centre pages and a lower-contrast fallback. Captures accumulate until Next opens review.
- Four independent crop corners operate on the original image, with complete 44px touch targets at image edges. Auto detect proposes new corners on-device; Apply crop commits them.
- Scans start with the document-enhancement filter. Original images remain available for changing filters and crops. Review includes rotation, annotation, deletion, reordering and additional pages.
- Review has no persistent filename box. Save PDF opens a naming sheet, saves the document into Office history and clears the finished scan draft. Cancelling the naming sheet retains all pages.
- Office, Downloads and Notes share compact headers and cards. Account entry offers Log in or Create account before fields. Text size starts at 13 with numeric choices and respects system scaling. Relaunch returns Home and clears transient search input.

## Review evidence

These are actual Flutter widget renders with a sample page and mocked native channel, not camera photographs. Large-text toolbars scroll horizontally so labels remain readable.

| Screen | Light | Dark |
| --- | --- | --- |
| Review | [390px](../hyzen_flutter/qa/compact-office/light-review-390-1.0.png) | [390px](../hyzen_flutter/qa/compact-office/dark-review-390-1.0.png) |
| Free corners | [Crop](../hyzen_flutter/qa/compact-office/light-corners.png) | [Crop](../hyzen_flutter/qa/compact-office/dark-corners.png) |
| Narrow / 200% text | [320px](../hyzen_flutter/qa/compact-office/light-review-320-2.0.png) | [320px](../hyzen_flutter/qa/compact-office/dark-review-320-2.0.png) |
| Office | [Office](../hyzen_flutter/qa/compact-office/light-office.png) | [Office](../hyzen_flutter/qa/compact-office/dark-office.png) |
| Notes | [Notes](../hyzen_flutter/qa/compact-office/light-notes.png) | [Notes](../hyzen_flutter/qa/compact-office/dark-notes.png) |
| Downloads | [Downloads](../hyzen_flutter/qa/compact-office/light-downloads.png) | [Downloads](../hyzen_flutter/qa/compact-office/dark-downloads.png) |

Run `flutter analyze --no-pub` and `flutter test --no-pub -r expanded --timeout 90s` in `hyzen_flutter`. The scanner workflow also compiles Android Kotlin and builds the web review entrypoint. To regenerate scan renders, run `flutter test --no-pub test/scan_layout_test.dart --dart-define=HYZEN_CAPTURE_QA=true --update-goldens`.

See [detector regression results](../tools/scan_bench/README.md) for 28 synthetic images, blank-scene, rotation/stride, contrast and homography checks. Real-phone camera accuracy, lighting, latency and end-to-end file sharing still require device testing; passing widget/JVM/compile checks does not establish these.
