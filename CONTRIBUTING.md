# Contributing to Pharm D with Hyzen

Thanks for helping make study and document tools better for students and everyday users.

## Ways to contribute

- Fix reproducible bugs in **Office Workspace** PDF operations or scanning.
- Improve Study browsing, local downloads, accessibility, performance and translations.
- Add focused tests, documentation, or issue reproduction steps.
- Improve Flutter/Android interoperability while keeping existing file formats and data safe.

## Before you start

1. Search [existing issues](https://github.com/Horizon003/pharm-d-with-hyzen/issues) and open a focused issue for larger changes.
2. Read the [README](README.md), [asset policy](ASSET_POLICY.md), and [security policy](SECURITY.md).
3. Avoid modifying production signing flows or backend access permissions without maintainer coordination.
4. Please do not attach real students' names, IDs, private files, account screenshots, or credentials to issues.

## Development setup

The primary Flutter project is in `hyzen_flutter/`.

```bash
git clone https://github.com/Horizon003/pharm-d-with-hyzen.git
cd pharm-d-with-hyzen/hyzen_flutter
flutter pub get
flutter analyze
flutter test
```

Use Flutter 3.35.4, Dart 3.9.x and JDK 17 for the project's currently documented baseline. Run `flutter run` with an appropriately configured test environment. Some authentication/cloud features may require maintainer-owned services and are not guaranteed to work without authorized setup.

## Pull requests

- Keep the diff small and the PR description clear.
- Say **what changed**, **why**, and **how it was verified**.
- Add or update relevant tests for behavior changes.
- For UI changes, include **sanitized** light/dark screenshots where helpful.
- For native scanner or PDF changes, explain which real-device checks remain pending.
- Never add keystores, tokens, `.env` files, production credentials, or real student records.
- New art or third-party assets require clear licensing and attribution.

## Scope and limitations

Original project code is licensed under MIT; branding and other assets have separate conditions. See [ASSET_POLICY.md](ASSET_POLICY.md). The project is evolving, and CI tests are not a substitute for real-device acceptance or deployed-backend verification.

## Responsible security reporting

Do not open public issues containing vulnerabilities, credentials, private endpoints or student data. Follow [SECURITY.md](SECURITY.md).
