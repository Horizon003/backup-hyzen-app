# Security policy

## Supported scope

The repository is actively developed; no formal long-term support schedule is promised. Security fixes should target the current `main` branch unless a maintainer specifies otherwise.

## Report vulnerabilities privately

Please **do not** disclose working exploits, credentials, private student information, or sensitive configuration in public GitHub issues or pull requests.

Use GitHub **Private Vulnerability Reporting** if it is enabled in the repository's Security tab. If it is unavailable, first reach the maintainer through an appropriate private channel; do not post confidential details publicly. General non-sensitive bugs can be filed as regular issues.

For a report, include affected version/commit, impact, reproduction steps with **redacted dummy data**, and any suggested mitigation. Do not send live tokens or private student documents.

## Local development and release hygiene

- Production keystores, signing passwords, service-account private keys, OAuth client secrets, deployment credentials and access tokens must **never** be committed.
- Local secret files are ignored by `.gitignore`, but **ignore rules do not remove already committed files or rewrite Git history**.
- Flutter/Firebase client configuration can contain public identifiers or client API keys. Public does **not** mean unrestricted: configure API-key restrictions, Firebase Security Rules, and least-privilege services independently.
- The repository contains **proposed** Firestore rules. They are **not** evidence of the deployed rules; review the deployed configuration before relying on them.
- The repository has historical source artifacts. Review archives and Git history before sharing credentials, and rotate/revoke any exposed sensitive values.
- Never upload real student records, private study documents, or personal data into public issues or screenshots.
- Evaluate third-party package advisories and keep dependencies updated.

## If a secret leaks

1. **Revoke or rotate the secret at its provider first.**
2. Audit access logs and affected systems.
3. Remove the value from current source and stop new exposure.
4. Decide whether Git history and published artifacts need a coordinated rewrite or withdrawal. Deleting a current file alone does not erase history.
5. Reverify deployed restrictions and notify impacted parties where appropriate.

A public source tree cannot by itself establish that the live backend, signed builds, old archives and commit history are fully secure.
