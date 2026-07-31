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
6. Install the generated bundle on a test device and confirm that the launcher
   shows the JS Truck Park icon, not the default Flutter icon.
7. Upload only the versioned AAB printed by the script.
8. Keep the adjacent `.build-info` file with the test record.

The script moves previous bundles out of Flutter's active output directory,
builds from `HEAD`, renames Flutter's generic `app-release.aab` output to the
versioned release filename, and verifies the internal version, Google Play
upload certificate, packaged launcher icon and release UI markers inside the
compiled `libapp.so`. The active output directory therefore contains only the
unambiguous versioned AAB. The script records the artifact SHA-256, certificate
SHA-256, launcher icon SHA-256, Git commit, branch, version and build time.
Previous bundles are preserved under `build/release-archive/`.

## Protected release markers

- `profile-invite-action`: the Invite friends action is present in the profile;
- `public-parking-details-photo-gallery`: the parking photo gesture surface is
  present;
- `public-parking-reviews-count` and `public-parking-photos-count`: the parking
  detail badges that refresh with newly submitted review content are present;
- `public-parking-details-scroll-view`: the explicit details scroll surface is
  present;
- `deep-link-cold-start-v1`: parking and shared-photo initial links are
  captured before asynchronous application startup;
- `referral-deferred-recovery-v3`: native SDK readiness, Android backup
  exclusions and the bounded deferred-attribution recovery are present in the
  release client;
- `referral-link-fallback-v1`: new referral links use the validated iOS browser
  fallback instead of relying on Chottu's blank embedded-browser response.
- `referral-link-capture-v2`: Chottu links observed by the independent platform
  channel are resolved through Chottu as a cold-start delivery fallback.
- `referral-device-identity-v1`: referral registration refreshes and validates
  a platform-specific app-scoped device identifier instead of using an Android
  firmware build label.

The marker check does not replace Flutter tests. It protects the final handoff
between tested source and uploaded binary.

The Android launcher mipmaps are generated from
`assets/images/app_launcher_icon.png`. The platform test validates every
required density and rejects the small default Flutter placeholder assets that
were found in the Android source tree while investigating production build 49.

## Production build 49 audit

The uploaded candidate was recovered from
`build/release-archive/20260731T035344Z-2e15fb8-42435/` and inspected without
modification. It contains `versionName=1.0.15`, `versionCode=49` and the expected
Google Play upload certificate, but packages the default Flutter launcher icon.
Its compiled application also lacks `deep-link-cold-start-v1`,
`referral-deferred-recovery-v3` and the current referral-link fallback marker.

No adjacent `.build-info` exists, and build 49 was produced before the later
branches were integrated into `main`. Treat it as an untraceable legacy
artifact and do not reuse it for any track.

The local build-52 verification from the main project folder contains version
`1.0.16 (52)`, the expected upload certificate, the JS Truck Park launcher icon
and all protected deep-link/referral markers. It remains a local verification
artifact until the source changes are committed and the provenance script is
run from a clean tree.

The local build-54 candidate contains the immediate review summary refresh:
the review badge, photo badge and parking gallery are reloaded after a review
with optional photos is submitted. The verified Android artifact is
`build/app/outputs/bundle/release/JS-Truck-Park-1.0.16-54.aab` with SHA-256
`2d46585ac7b31d06148b250f4c4d108a16a83ee9b346a708ccbce79e13eb1aa6`.
It was built from the current working tree and has not been uploaded; apply the
required clean-tree workflow before any Google Play upload.

Build `1.0.16 (55)` fixes the referral registration failure found during the
iPhone closed test. Read-only inspection showed that the newly created profile
had stored `TKQ1.221114.001`, which is an Android firmware build label and was
already present on another profile. The original FlutterFlow action used
`AndroidDeviceInfo.id` even though that field represents `Build.ID`, not a
device identifier.

Build 55 reads Android's app-scoped `ANDROID_ID`, validates iOS IDFV values,
refreshes the identifier immediately before registration, and waits for any
in-flight Chottu short-link resolution before deciding whether to call
`process_referral`. No Supabase schema, policy or production data is changed.

The local Android candidate is
`build/app/outputs/bundle/release/JS-Truck-Park-1.0.16-55.aab` with SHA-256
`73c99344ffa44c190eeee0297a45f16c5f5c7c9373b9be3c389a7791c36fa0a6`.
Its manifest reports version code 55, the upload certificate matches the
expected Google Play key, and the compiled application contains
`referral-device-identity-v1`.

The matching iOS candidate was uploaded to App Store Connect and passed the
physical-device referral and UI acceptance test. On 2026-08-01 the separate
Firebase Hosting relay was deployed and externally verified to use only the
published App Store and Google Play destinations.
