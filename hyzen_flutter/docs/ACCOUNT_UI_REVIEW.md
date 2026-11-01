# Account UI review

The active Flutter project is `hyzen_flutter/`. Account, Settings, Account Info
(`/profile/info`) and the existing profile editor share the approved rounded Account layout. They follow the app’s existing
Light / Dark / Auto preference: white cards and dark text in Light, approved
black/charcoal surfaces with white text in Dark. Soft blue links and coral
destructive actions retain their purpose in both modes. The avatar menu uses the same Account
screen as `/profile`; existing routes, academic fields, promotions, local profile
sync, photo upload, downloads, orders, legal pages and logout remain connected.

Announcements use the existing persisted `pref_announcements` setting. The custom
toggle supports touch, keyboard, screen readers and reduced motion. Email remains
read-only. Username, balances, subscriptions and account deletion are not fabricated:
the current student schema/backend does not implement those account features.
Change Photo opens the existing editor, where gallery upload and built-in avatars
remain available; Save changes retains the existing pending/cloud sync behavior.

The original supplied panda is stored intact in `docs/reference/account/`.
`python tools/generate_panda_icons.py` (from the repository root, with Pillow)
regenerates all five Android density sets, conservative adaptive foregrounds,
in-app square branding and web icons. Android manifest now uses the launcher
resources; API 26+ adaptive backgrounds are white. No Gradle ABI configuration,
APK workflow, version number, signing or release settings are changed.

## Review without building an APK

Open the **Account UI validation and browser preview** workflow for
`fix/mascot-motion-apk`. Its artifact is named `account-ui-review-<full commit SHA>`.
The job runs Flutter analysis, the test suite, two Flutter web builds and browser
screenshots. It never invokes an Android build or publishes a release. Every
matching commit pushed to this branch builds and deploys the browser preview
after validation succeeds. Manual runs use the same validation and deployment.
The existing github-pages environment explicitly allows this review branch
following the approved branch-rule update. The workflow does not change
or bypass environment protection rules.

Download and unzip the artifact, then from its `build/serve` folder run:

```sh
python -m http.server 8080
```

Open:

- `http://localhost:8080/pharm-d-with-hyzen/` — actual app, normal authentication.
- `http://localhost:8080/pharm-d-with-hyzen/ui-review/#/profile` — real Account UI.
- `http://localhost:8080/pharm-d-with-hyzen/ui-review/#/profile/info` — Account Info.
- `http://localhost:8080/pharm-d-with-hyzen/ui-review/#/settings` — Settings.
- `http://localhost:8080/pharm-d-with-hyzen/commit.txt` — exact source revision.

The UI review entrypoint imports the production app, screens and routes. Its
sample profile is visibly labelled SAMPLE DATA; it uses local browser preferences
and local profile edits. Authentication operations require the normal app preview.
It is not used by `lib/main.dart`, APK builds or the ordinary Pages preview.
Browser previews display the version derived from pubspec; Android reads installed
package metadata. Gallery upload and device downloads still require Android.

Screenshots are in `qa/account-redesign/` inside the artifact. The existing Pages
workflow now builds checked-out Flutter source directly instead of an older ZIP.
Its own main/manual triggers remain unchanged; the account review workflow
updates the same preview from the requested review branch on pushes and manual
runs, subject to the repository’s Pages environment policy. The preview continues to use the existing protected github-pages environment;
no additional site or deployment workflow is introduced.

## Hosted browser preview

A hosted link is available only after a successful deployment. Check the
deploy job before using these URLs; the downloadable preview above works without
Pages deployment. For the default GitHub Pages domain:

- `https://horizon003.github.io/pharm-d-with-hyzen/ui-review/#/profile`
- `https://horizon003.github.io/pharm-d-with-hyzen/ui-review/#/profile/info`
- `https://horizon003.github.io/pharm-d-with-hyzen/ui-review/#/settings`

The root path is the normal authenticated app; `/ui-review/` uses the labelled
sample profile. Check `commit.txt` at the root to identify the deployed source.
After each requested UI change is committed to this branch, allow a few minutes
for the web build and deployment, then refresh the same preview link. An Android
APK is built only when separately requested.

## Local Flutter checks

```sh
cd hyzen_flutter
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter run -d chrome --target lib/main_account_review.dart --dart-define=HYZEN_APP_VERSION=1.5.3+12
```

Open `/profile`, `/profile/info` or `/settings` using the hash routes above.
Do not invoke an APK workflow until the UI is approved. The final Android package
remains one Universal APK for ARM32, ARM64 and x86_64.

## Five-tab navigation review

The existing MainDock now maps exactly five destinations to the original shell
branches, without reordering auxiliary branches:

| Visible destination | Existing route | Shell branch |
| --- | --- | --- |
| Home | /home | 0 |
| Study | /study | 1 |
| Office Workspace | /pdf-studio | 3 |
| Shop | /shop | 6 |
| Downloads | /downloads | 4 |

Study opens its hub on first entry. Switching tabs restores each branch’s nested
stack; tapping the selected destination returns to its root. Downloads has an
independent selected state and retains the existing controller, persisted records
and screen filters. Search, Account, Settings and Admin remain auxiliary routes.
Account and immersive workspace readers continue to hide the dock.

The dock is pure black in both app themes, with white labels/icons and neutral
selected surfaces. Office occupies the center with a restrained selected lift.
Motion uses HMotion and respects disableAnimations. Each destination keeps an
equal accessible hit area; compact Office text retains the full accessibility
label. TabPage reserves matching dock/system-gesture clearance once.

The review entrypoint also accepts /home, /study, /pdf-studio, /shop, /downloads
and /search, using the same real app screens with sample content/auth only.
Add ?theme=light or ?theme=dark **before** the hash, for example:

- https://horizon003.github.io/pharm-d-with-hyzen/ui-review/?theme=light#/profile
- https://horizon003.github.io/pharm-d-with-hyzen/ui-review/?theme=dark#/pdf-studio
- https://horizon003.github.io/pharm-d-with-hyzen/ui-review/?theme=dark#/downloads

Normal Settings → App theme remains functional and persisted. An explicit review
URL theme takes priority when that URL is loaded again.

The existing capture script saves light/dark Account, Account Info, Settings,
Office and Downloads screenshots plus 320px Office captures with reduced motion.
It validates five accessible destinations, their order, >=48px hit targets and
actual route changes in Chromium. browser-evidence.json records the source SHA
and capture matrix. Flutter navigation tests cover route selection, retained
Study stacks, retained download records/filters, auxiliary routes, safe areas,
large text, reduced motion and theme changes. The full existing regression suite
continues to run for downloads, scanner, reader, registration and account access.

No Home redesign, panda/mascot change, Android build, version/signing/ABI change,
release publication or main-branch merge is part of this task.
