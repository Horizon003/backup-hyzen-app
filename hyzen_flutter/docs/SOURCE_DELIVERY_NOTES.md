# Source package notes

The source archive intentionally omits machine-generated build output, local SDK paths, and signing credentials.

To produce an update that installs over an existing production build, restore the owner's original release keystore at `android/signing/hyzen-release.jks` and restore `android/key.properties` with its existing alias and passwords. Keep both private and backed up. Never create a replacement keystore for an already distributed app.

The current source version is `1.3.3+7`. A testing APK must be built from this source with the Flutter and Android SDKs available; the older APK in prior release folders is not this build. See `PDF_STUDIO_IMPLEMENTATION_STATUS.md` for implemented tools and current limitations.
