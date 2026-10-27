# Build signed APK (1.3.3+7)

Use the **original** production keystore from the owner's private backup. Creating a new key will prevent an update over an existing installation. Never commit or share the keystore or `android/key.properties`.

## Local build

Install Flutter stable, its Android toolchain, Android SDK licenses, and JDK 17. Restore `android/signing/hyzen-release.jks` and `android/key.properties` using `android/key.properties.example` as the field template. From the project root run:

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The output is `build/app/outputs/flutter-apk/app-release.apk`. Verify its version is **1.3.3+7** and its certificate fingerprint matches the owner's installed APK before distributing it. Test installation and the PDF Studio features on a device.

## GitHub Actions build

Push this source to a private repository. Configure repository Actions secrets `HYZEN_KEYSTORE_BASE64` (base64 of the original `.jks`, without line breaks), `HYZEN_STORE_PASSWORD`, `HYZEN_KEY_PASSWORD`, and `HYZEN_KEY_ALIAS`. Run **Signed Android APK** under Actions; download the resulting artifact. It runs analyze and tests before building. The keystore is restored only in the runner and is not included in the APK artifact. Keep the original signing backup outside the repository.

The remote workflow has successfully built 1.3.3+7 in the private repository `Horizon003/pharm-d-with-hyzen`. Its original signing secrets are already configured. The remote repository extracts the source ZIP and applies the checked-in source corrections before building; this source ZIP contains those corrections directly. The workflow included here builds an extracted checkout directly. Keep Flutter pinned to 3.35.4 for these builds.
