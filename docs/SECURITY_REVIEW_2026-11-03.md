# Security review — 2026-11-03

**Repository:** `Horizon003/pharm-d-with-hyzen`  
**Scope:** limited source/configuration review of the public `main` branch for open-source publishing.  
**Status:** **Partially reviewed, not certified secure.**

This review is a transparency record, **not** a penetration test, production security assessment, or guarantee against exposed secrets.

## Checks performed

- Reviewed the tracked file tree for conventional keystore, environment, service-account and signing files.
- Inspected **33 configuration, build, workflow, scripts and metadata files** against common high-confidence secret indicators.
- Inspected **15 selected Dart, Firebase, backend, authentication, admin and Android files** using the same high-confidence indicators.
- Performed targeted GitHub code-search checks for common token and credential strings. A zero-result search is not evidence of exhaustive indexing or history coverage.
- Confirmed GitHub's public-repository metadata and MIT code-license recognition.
- Inspected repository release workflow patterns for use of GitHub Actions secrets rather than committed production signing credentials.

## Findings within the checked scope

| Area | Observed result | Important limitation |
|:--|:--|:--|
| Production signing keys | No tracked `.jks` / `.keystore` file in the current recursive tree | Historical artifacts and prior commits are not cleared |
| Workflow secret handling | Inspected workflows reference protected GitHub Actions secret inputs | Actual configured secrets and workflows at runtime were not inspected |
| Firebase | Client application configuration and client API key exist in tracked code | Firebase client keys are typically public identifiers; restrictions and backend rules still need an authorized console review |
| High-confidence token signatures | None observed in the 48 inspected text files | Other sources, token formats, old commits and compressed artifacts were not fully scanned |
| Firestore access rules | A proposed rule file exists | The repository does not establish what is currently deployed |

**Do not treat this review as approval to publish private keys, student data, or internal service credentials.**

## Outstanding owner-verification steps

1. **Git history** — run an appropriate scanner against **all commits and branches**, not just the tip of `main`.
2. **Historical ZIP archives** — inspect tracked binary source archives, uploaded build artifacts, releases and backup files for secrets and personal data. Archive bytes were not inspected in this review.
3. **GitHub security alerts** — review any secret-scanning and dependency alerts available to the maintainer; their status was not accessible in this review.
4. **Firebase console** — verify authentication settings, key restrictions, deployed Firestore/Storage security rules, admin access, App Check strategy if applicable and audit logs.
5. **Android release** — verify manifest permissions, signing storage, network configuration and an installed release build on real devices.
6. **Asset rights and privacy** — confirm that published screenshots, learning resources, and branded visual assets may be shared; do not include real student records.
7. **Third-party dependencies** — inspect vulnerability advisories and package licenses before release.

If a credential is found, **revoke/rotate it before editing files or rewriting history**. A new `.gitignore` does not remove files already committed. Coordinate history cleanup and artifact removal to avoid accidental re-exposure.

Read [SECURITY.md](../SECURITY.md) for responsible reporting and [ASSET_POLICY.md](../ASSET_POLICY.md) for code-versus-artwork license boundaries.
