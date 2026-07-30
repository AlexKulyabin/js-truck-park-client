# Release artifact provenance

## Purpose

Every uploaded Android App Bundle must be traceable to one committed source
revision. This prevents an older artifact or a bundle built from another
checkout from being uploaded under a new release description.

## Required workflow

1. Commit the feature changes.
2. Commit the `pubspec.yaml` version and build-number change.
3. Ensure the tracked working tree is clean.
4. If `android/key.properties` is absent, point `ANDROID_KEY_PROPERTIES` to the
   existing private signing-properties file.
5. Run `tool/build_release_aab.sh` from the repository root.
6. Upload only the versioned AAB printed by the script.
7. Keep the adjacent `.build-info` file with the test record.

The script moves previous bundles out of Flutter's active output directory,
builds from `HEAD`, and verifies the internal version, Google Play upload
certificate and release UI markers inside the compiled `libapp.so`. It records
the artifact SHA-256, certificate SHA-256, Git commit, branch, version and build
time. Previous bundles are preserved under `build/release-archive/`.

## Protected release markers

- `profile-invite-action`: the Invite friends action is present in the profile;
- `public-parking-details-photo-gallery`: the parking photo gesture surface is
  present;
- `public-parking-details-scroll-view`: the explicit details scroll surface is
  present;
- `referral-deferred-recovery-v3`: native SDK readiness, Android backup
  exclusions and the bounded deferred-attribution recovery are present in the
  release client.

The marker check does not replace Flutter tests. It protects the final handoff
between tested source and uploaded binary.
