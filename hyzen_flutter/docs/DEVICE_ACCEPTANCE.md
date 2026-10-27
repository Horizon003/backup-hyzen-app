# Android device acceptance — 1.2.0

## Outcome: blocked by emulator infrastructure

The software Android 11/API 30 x86_64 emulator booted, without hardware
acceleration (`/dev/kvm` is unavailable). Repeated attempts hit Android system
service failures. The final attempt reached the real install command:

```text
Performing Streamed Install
adb: failed to install app-release.apk:
cmd: Failure calling service package: Broken pipe (32)
```

An earlier attempt also failed in the emulator's `window` service during
resolution setup. Retrying without treating that cosmetic command as a gate
still failed in the package service. No successful APK install, app start,
native preview/offline render, or future-version installer completion is claimed.
The build, signature, ZIP/CRC, automated Flutter checks and public file-byte
checks are independent and passed; see `VALIDATION_1_2.md`.

Affected module: emulator Android package/window services. No Dart/Kotlin
compile failure remains. This system-service error does not establish that the
APK itself was rejected as invalid.

## Best next check

Install the supplied testing APK on an actual Android phone (Android 7/API 24
or newer), or a working hardware-accelerated emulator. Keep the old app's local
data backed up before the one-time new-signing-key transition.

Acceptance checklist:

1. Open a public PDF, the HLB presentation and a JPEG note; verify page/image
   content and readable errors for a private/deleted resource.
2. Save offline; confirm progress, completion and Downloads entry. Force-stop
   and reopen the app, enable airplane mode, and open the saved note.
3. Cancel a download, retry it, export through the system picker and delete it.
4. Check Home/Study/Search/Downloads/Profile, small screen/large text, keyboard
   focus and Android Back. Verify login against the real Firebase project.
5. For a future higher-version, same-key APK, publish its HTTPS URL/checksum in
   admin Settings; test update checking, cancel/retry, wrong hash/signature
   rejection, unknown-source permission return and actual installation.
6. Confirm local notes/profile remain after that normal same-key update.

No backend release was published just to simulate a successful updater test.
