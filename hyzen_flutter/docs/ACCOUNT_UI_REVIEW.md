# Account UI review

The active Flutter project is `hyzen_flutter/`. Account, Settings, Account Info
(`/profile/info`) and the existing profile editor share the approved black,
charcoal, white, soft blue and coral design. The avatar menu uses the same Account
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
screenshots. It never invokes an Android build or publishes a release. Automatic branch pushes produce a downloadable browser preview. Manual runs
also attempt deployment to the existing GitHub Pages preview environment.

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
can update the same preview from the requested review branch on manual runs,
subject to the repository’s existing Pages environment policy. The first automatic
deployment attempt was rejected before a runner was allocated; validation and
all browser builds/screenshots succeeded. No environment/security policy was changed.

## Hosted browser preview

A hosted link is available only after a successful manual deployment. Check the
deploy job before using these URLs; the downloadable preview above works without
Pages deployment. For the default GitHub Pages domain:

- `https://horizon003.github.io/pharm-d-with-hyzen/ui-review/#/profile`
- `https://horizon003.github.io/pharm-d-with-hyzen/ui-review/#/profile/info`
- `https://horizon003.github.io/pharm-d-with-hyzen/ui-review/#/settings`

The root path is the normal authenticated app; `/ui-review/` uses the labelled
sample profile. Check `commit.txt` at the root to identify the deployed source.

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
